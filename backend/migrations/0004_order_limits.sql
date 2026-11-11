-- HM Store — Migración 0004: límites configurables para create_order
-- Principios:
--  * Los límites viven en la base de datos (tabla store_settings), no en el frontend.
--  * Si un límite no está configurado, create_order RECHAZA el pedido (fail closed).
--    No se fijan valores comerciales en esta migración: los define HM y se aprueban antes.
--  * Solo se pueden leer por anon/authenticated las claves públicas 'checkout.*'
--    (el frontend las necesita para mostrar cantidades máximas). Escritura solo admins.
--  * Esta migración es aditiva; no altera pedidos ni datos existentes.

-- ============================================================
-- 1. Tabla de configuración
-- ============================================================
create table public.store_settings (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid
);

alter table public.store_settings enable row level security;

create policy store_settings_public_read on public.store_settings for select
  using (key like 'checkout.%');

create policy store_settings_admin on public.store_settings for all
  using (public.is_admin()) with check (public.is_admin());

create trigger store_settings_updated_at before update on public.store_settings
  for each row execute function public.set_updated_at();

-- Claves reconocidas (documentadas; sin valores por defecto):
--   checkout.max_units_per_item   -> entero >= 1
--   checkout.max_lines_per_order  -> entero >= 1

-- ============================================================
-- 2. create_order con límites
-- ============================================================
create or replace function public.create_order(
  p_idempotency_key text,
  p_customer        jsonb,
  p_items           jsonb
)
returns table (out_order_id uuid, out_order_code text, out_total_cop integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing_id   uuid;
  v_order_id      uuid := gen_random_uuid();
  v_code          text;
  v_item          jsonb;
  v_variant       public.product_variants%rowtype;
  v_product       public.products%rowtype;
  v_qty           integer;
  v_line          integer;
  v_subtotal      integer := 0;
  v_max_units     integer;
  v_max_lines     integer;
begin
  if p_idempotency_key is null or length(p_idempotency_key) < 8 or length(p_idempotency_key) > 100 then
    raise exception 'Clave de idempotencia inválida';
  end if;

  -- Idempotencia: un reenvío devuelve el mismo pedido sin volver a descontar stock
  select o.id into v_existing_id from public.orders o where o.idempotency_key = p_idempotency_key;
  if v_existing_id is not null then
    return query
      select o.id, o.order_code, o.total_cop from public.orders o where o.id = v_existing_id;
    return;
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'El pedido no tiene artículos';
  end if;

  -- Límites configurados (fail closed si faltan)
  select (value #>> '{}')::integer into v_max_units
    from public.store_settings where key = 'checkout.max_units_per_item';
  select (value #>> '{}')::integer into v_max_lines
    from public.store_settings where key = 'checkout.max_lines_per_order';

  if v_max_units is null or v_max_lines is null or v_max_units < 1 or v_max_lines < 1 then
    raise exception 'Los límites de compra no están configurados. Contacta a la tienda.';
  end if;

  if jsonb_array_length(p_items) > v_max_lines then
    raise exception 'El pedido supera el máximo de % líneas', v_max_lines;
  end if;

  if coalesce(trim(p_customer->>'name'), '') = '' or coalesce(trim(p_customer->>'phone'), '') = '' then
    raise exception 'Nombre y teléfono son obligatorios';
  end if;

  v_code := 'HM-' || to_char(now() at time zone 'America/Bogota', 'YYMMDD')
            || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 5));

  insert into public.orders (
    id, order_code, idempotency_key, customer_name, customer_phone, customer_email,
    shipping_address, city, notes
  ) values (
    v_order_id, v_code, p_idempotency_key,
    trim(p_customer->>'name'), trim(p_customer->>'phone'), nullif(trim(p_customer->>'email'), ''),
    nullif(trim(p_customer->>'address'), ''), nullif(trim(p_customer->>'city'), ''),
    nullif(trim(p_customer->>'notes'), '')
  );

  for v_item in select * from jsonb_array_elements(p_items) loop
    begin
      v_qty := (v_item->>'quantity')::integer;
    exception when others then
      raise exception 'Cantidad inválida';
    end;
    if v_qty is null or v_qty < 1 then
      raise exception 'Cantidad inválida';
    end if;
    if v_qty > v_max_units then
      raise exception 'La cantidad máxima por artículo es %', v_max_units;
    end if;

    select * into v_variant
      from public.product_variants
      where id = (v_item->>'variant_id')::uuid
      for update;

    if not found or not v_variant.is_active then
      raise exception 'Una variante seleccionada ya no está disponible';
    end if;

    -- Una variante por línea: evita eludir el límite repitiendo la misma variante
    if exists (select 1 from public.order_items
               where order_id = v_order_id and variant_id = v_variant.id) then
      raise exception 'Una variante aparece más de una vez; combina las cantidades en una sola línea';
    end if;

    select * into v_product from public.products where id = v_variant.product_id;

    if v_product.status <> 'published' then
      raise exception 'El producto "%" no está disponible', v_product.name;
    end if;
    if v_product.price_cop is null then
      raise exception 'El producto "%" no tiene precio confirmado', v_product.name;
    end if;

    if v_product.fulfillment = 'stock' then
      if v_variant.stock_qty is null or v_variant.stock_qty < v_qty then
        raise exception 'Existencias insuficientes para "%"', v_product.name;
      end if;

      update public.product_variants
        set stock_qty = stock_qty - v_qty
        where id = v_variant.id;

      insert into public.inventory_movements (variant_id, delta, reason, order_id)
        values (v_variant.id, -v_qty, 'order', v_order_id);
    end if;

    v_line := v_product.price_cop * v_qty;
    v_subtotal := v_subtotal + v_line;

    insert into public.order_items (
      order_id, variant_id, product_id, product_name_snapshot, sku_snapshot,
      size_snapshot, color_snapshot, unit_price_cop, quantity, line_total_cop
    ) values (
      v_order_id, v_variant.id, v_product.id, v_product.name, v_product.sku,
      v_variant.size, v_variant.color_name, v_product.price_cop, v_qty, v_line
    );
  end loop;

  update public.orders
    set subtotal_cop = v_subtotal,
        shipping_cop = 0,
        total_cop    = v_subtotal
    where id = v_order_id;

  return query select v_order_id, v_code, v_subtotal;
end $$;

revoke execute on function public.create_order(text, jsonb, jsonb) from public;
grant  execute on function public.create_order(text, jsonb, jsonb) to anon, authenticated;

-- Permisos de lectura de configuración para anon/authenticated (RLS limita a checkout.*)
grant select on public.store_settings to anon, authenticated;
grant insert, update, delete on public.store_settings to authenticated;
