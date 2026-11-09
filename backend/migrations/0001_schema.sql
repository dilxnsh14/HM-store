-- HM Store — Migración 0001: schema base
-- Reglas de negocio reflejadas aquí:
--  * Precios en COP enteros. price_cop NULL = pendiente de HM (no se puede publicar).
--  * Estado del producto separado: draft | published | sold_out | hidden | archived.
--  * Stock por variante (talla + color). stock_qty NULL = no confirmado (no se vende).
--  * Pedido y pago son estados independientes.
--  * Pedidos guardan snapshot de nombre, SKU, talla, color y precio.
--  * Pedidos solo se crean mediante la función public.create_order (valida precio y stock en servidor).
--  * RLS: lectura pública solo de contenido publicado; escritura y datos personales solo para admins.

create extension if not exists pgcrypto;

-- ============================================================
-- TIPOS
-- ============================================================
create type product_status    as enum ('draft', 'published', 'sold_out', 'hidden', 'archived');
create type collection_status as enum ('draft', 'published', 'hidden', 'archived');
create type order_status      as enum ('pending', 'confirmed', 'preparing', 'shipped', 'delivered', 'cancelled');
create type payment_status    as enum ('unpaid', 'pending', 'paid', 'refunded', 'failed');
create type admin_role        as enum ('owner', 'editor', 'operator');
create type fulfillment_mode  as enum ('print_on_demand', 'stock');

-- ============================================================
-- FUNCIONES GENERALES
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ============================================================
-- 1. MARCAS Y CATEGORÍAS
-- ============================================================
create table public.brands (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,
  created_at  timestamptz not null default now()
);

create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  slug        text not null unique,
  name        text not null,
  sort_order  integer not null default 0
);

-- ============================================================
-- 2. COLECCIONES (incluye configuración del hero y de la cinta)
-- ============================================================
create table public.collections (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique,
  name            text not null,
  description     text,
  status          collection_status not null default 'draft',
  sort_order      integer not null default 0,
  -- Hero: solo una colección puede ser protagonista (índice parcial abajo)
  is_hero         boolean not null default false,
  hero_title      text,
  hero_text       text,
  hero_cta_label  text,
  hero_image_path text,
  hero_theme      jsonb not null default '{}'::jsonb,
  published_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  constraint collections_hero_requires_published
    check (not is_hero or status = 'published')
);

create unique index collections_single_hero on public.collections (is_hero) where is_hero;

create trigger collections_updated_at before update on public.collections
  for each row execute function public.set_updated_at();

-- ============================================================
-- 3. PRODUCTOS
-- ============================================================
create table public.products (
  id              uuid primary key default gen_random_uuid(),
  sku             text not null unique,
  name            text not null,
  description     text,
  brand_id        uuid references public.brands(id) on delete set null,
  category_id     uuid references public.categories(id) on delete set null,
  collection_id   uuid references public.collections(id) on delete set null,
  price_cop       integer check (price_cop is null or price_cop >= 0),
  is_provisional  boolean not null default true,
  status          product_status not null default 'draft',
  -- print_on_demand: se fabrica al pedir, no requiere existencias.
  -- stock: se vende desde inventario físico (product_variants.stock_qty).
  fulfillment     fulfillment_mode not null default 'print_on_demand',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  -- No se puede publicar ni vender un producto sin precio real
  constraint products_published_needs_price
    check (status not in ('published', 'sold_out') or price_cop is not null)
);

create index products_collection_idx on public.products (collection_id);
create index products_status_idx     on public.products (status);

create trigger products_updated_at before update on public.products
  for each row execute function public.set_updated_at();

-- ============================================================
-- 4. IMÁGENES DE PRODUCTO (rutas en Supabase Storage)
-- ============================================================
create table public.product_images (
  id            uuid primary key default gen_random_uuid(),
  product_id    uuid not null references public.products(id) on delete cascade,
  storage_path  text not null,
  alt           text not null default '',
  sort_order    integer not null default 0,
  is_primary    boolean not null default false
);

create index product_images_product_idx on public.product_images (product_id, sort_order);
create unique index product_images_single_primary
  on public.product_images (product_id) where is_primary;

-- ============================================================
-- 5. VARIANTES (talla + color) con inventario
-- ============================================================
create table public.product_variants (
  id           uuid primary key default gen_random_uuid(),
  product_id   uuid not null references public.products(id) on delete cascade,
  size         text not null default '',
  color_name   text not null default '',
  color_hex    text check (color_hex is null or color_hex ~ '^#[0-9A-Fa-f]{6}$'),
  -- Solo aplica a productos con fulfillment = 'stock'. Ignorado en print_on_demand.
  stock_qty    integer check (stock_qty is null or stock_qty >= 0),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  unique (product_id, size, color_name)
);

create index product_variants_product_idx on public.product_variants (product_id);

-- ============================================================
-- 6. MOVIMIENTOS DE INVENTARIO (trazabilidad de existencias)
-- ============================================================
create table public.inventory_movements (
  id          bigserial primary key,
  variant_id  uuid references public.product_variants(id) on delete set null,
  delta       integer not null check (delta <> 0),
  reason      text not null check (reason in ('order', 'order_cancelled', 'manual_adjustment', 'restock')),
  order_id    uuid,
  actor_id    uuid,
  note        text,
  created_at  timestamptz not null default now()
);

create index inventory_movements_variant_idx on public.inventory_movements (variant_id, created_at);

-- ============================================================
-- 7. CLIENTES (datos personales: solo admin)
-- ============================================================
create table public.customers (
  id          uuid primary key default gen_random_uuid(),
  full_name   text not null,
  phone       text not null,
  email       text,
  address     text,
  city        text,
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create trigger customers_updated_at before update on public.customers
  for each row execute function public.set_updated_at();

-- ============================================================
-- 8. PEDIDOS (estado de pedido separado del estado de pago)
-- ============================================================
create table public.orders (
  id                 uuid primary key default gen_random_uuid(),
  order_code         text not null unique,
  idempotency_key    text not null unique,
  customer_id        uuid references public.customers(id) on delete set null,
  customer_name      text not null,
  customer_phone     text not null,
  customer_email     text,
  shipping_address   text,
  city               text,
  notes              text,
  subtotal_cop       integer not null default 0 check (subtotal_cop >= 0),
  shipping_cop       integer not null default 0 check (shipping_cop >= 0),
  total_cop          integer not null default 0 check (total_cop >= 0),
  status             order_status not null default 'pending',
  payment_status     payment_status not null default 'unpaid',
  whatsapp_opened_at timestamptz,  -- abrir WhatsApp NO significa que el mensaje se envió
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint orders_total_consistent check (total_cop = subtotal_cop + shipping_cop)
);

create index orders_status_idx on public.orders (status, created_at desc);

create trigger orders_updated_at before update on public.orders
  for each row execute function public.set_updated_at();

-- Relación diferida: movimientos de inventario -> pedidos
alter table public.inventory_movements
  add constraint inventory_movements_order_fk
  foreign key (order_id) references public.orders(id) on delete set null;

-- ============================================================
-- 9. LÍNEAS DE PEDIDO (snapshot del producto al momento de compra)
-- ============================================================
create table public.order_items (
  id                    uuid primary key default gen_random_uuid(),
  order_id              uuid not null references public.orders(id) on delete cascade,
  variant_id            uuid references public.product_variants(id) on delete set null,
  product_id            uuid references public.products(id) on delete set null,
  product_name_snapshot text not null,
  sku_snapshot          text not null,
  size_snapshot         text not null default '',
  color_snapshot        text not null default '',
  unit_price_cop        integer not null check (unit_price_cop >= 0),
  quantity              integer not null check (quantity > 0),
  line_total_cop        integer not null check (line_total_cop >= 0),
  constraint order_items_line_total check (line_total_cop = unit_price_cop * quantity)
);

create index order_items_order_idx on public.order_items (order_id);

-- ============================================================
-- 10. PAGOS (vacía hasta integrar Wompi; no guarda secretos)
-- ============================================================
create table public.payments (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references public.orders(id) on delete cascade,
  provider      text not null check (provider in ('manual', 'wompi')),
  provider_ref  text,
  amount_cop    integer not null check (amount_cop >= 0),
  status        payment_status not null default 'pending',
  raw_payload   jsonb,
  created_at    timestamptz not null default now()
);

create index payments_order_idx on public.payments (order_id);

-- ============================================================
-- 11. ANUNCIOS (cinta superior)
-- ============================================================
create table public.announcements (
  id             uuid primary key default gen_random_uuid(),
  text           text not null,
  collection_id  uuid references public.collections(id) on delete set null,
  is_active      boolean not null default false,
  sort_order     integer not null default 0,
  starts_at      timestamptz,
  ends_at        timestamptz,
  created_at     timestamptz not null default now(),
  constraint announcements_dates check (ends_at is null or starts_at is null or ends_at > starts_at)
);

-- ============================================================
-- 12. ADMINISTRADORES
-- ============================================================
create table public.admin_users (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  role        admin_role not null default 'operator',
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 13. AUDITORÍA
-- ============================================================
create table public.audit_logs (
  id           bigserial primary key,
  actor_id     uuid,
  action       text not null,
  entity       text not null,
  entity_id    text,
  diff         jsonb,
  created_at   timestamptz not null default now()
);

create index audit_logs_entity_idx on public.audit_logs (entity, entity_id);

-- ============================================================
-- SEGURIDAD: helpers
-- ============================================================
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$$;

-- ============================================================
-- FUNCIÓN: crear pedido (valida precios y stock en servidor)
-- ============================================================
-- p_items: [{ "variant_id": "uuid", "quantity": 1 }, ...]
-- p_customer: { "name": "...", "phone": "...", "email": "...", "address": "...", "city": "...", "notes": "..." }
-- Idempotente por p_idempotency_key: reenvíos devuelven el mismo pedido.
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
  v_existing_id uuid;
  v_order_id    uuid := gen_random_uuid();
  v_code        text;
  v_item        jsonb;
  v_variant     public.product_variants%rowtype;
  v_product     public.products%rowtype;
  v_qty         integer;
  v_line        integer;
  v_subtotal    integer := 0;
begin
  if p_idempotency_key is null or length(p_idempotency_key) < 8 then
    raise exception 'Clave de idempotencia inválida';
  end if;

  select o.id into v_existing_id from public.orders o where o.idempotency_key = p_idempotency_key;
  if v_existing_id is not null then
    return query
      select o.id, o.order_code, o.total_cop from public.orders o where o.id = v_existing_id;
    return;
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'El pedido no tiene artículos';
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

    -- Bloquea la variante durante la transacción para evitar sobreventa
    select * into v_variant
      from public.product_variants
      where id = (v_item->>'variant_id')::uuid
      for update;

    if not found or not v_variant.is_active then
      raise exception 'Una variante seleccionada ya no está disponible';
    end if;

    select * into v_product from public.products where id = v_variant.product_id;

    if v_product.status <> 'published' then
      raise exception 'El producto "%" no está disponible', v_product.name;
    end if;
    if v_product.price_cop is null then
      raise exception 'El producto "%" no tiene precio confirmado', v_product.name;
    end if;
    -- Solo productos con inventario físico validan y descuentan existencias
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

  -- Envío: pendiente de política de HM (0 hasta definir)
  update public.orders
    set subtotal_cop = v_subtotal,
        shipping_cop = 0,
        total_cop    = v_subtotal
    where id = v_order_id;

  return query select v_order_id, v_code, v_subtotal;
end $$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
alter table public.brands              enable row level security;
alter table public.categories          enable row level security;
alter table public.collections         enable row level security;
alter table public.products            enable row level security;
alter table public.product_images      enable row level security;
alter table public.product_variants    enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.customers           enable row level security;
alter table public.orders              enable row level security;
alter table public.order_items         enable row level security;
alter table public.payments            enable row level security;
alter table public.announcements       enable row level security;
alter table public.admin_users         enable row level security;
alter table public.audit_logs          enable row level security;

-- Lectura pública de catálogo
create policy brands_public_read     on public.brands     for select using (true);
create policy categories_public_read on public.categories for select using (true);

create policy collections_public_read on public.collections for select
  using (status = 'published');

create policy products_public_read on public.products for select
  using (status in ('published', 'sold_out'));

create policy product_images_public_read on public.product_images for select
  using (exists (select 1 from public.products p
                 where p.id = product_id and p.status in ('published', 'sold_out')));

create policy product_variants_public_read on public.product_variants for select
  using (is_active and exists (select 1 from public.products p
                               where p.id = product_id and p.status in ('published', 'sold_out')));

create policy announcements_public_read on public.announcements for select
  using (is_active and (starts_at is null or starts_at <= now())
                   and (ends_at is null or ends_at > now()));

-- Administradores: control total del contenido
create policy brands_admin     on public.brands     for all using (public.is_admin()) with check (public.is_admin());
create policy categories_admin on public.categories for all using (public.is_admin()) with check (public.is_admin());
create policy collections_admin on public.collections for all using (public.is_admin()) with check (public.is_admin());
create policy products_admin   on public.products   for all using (public.is_admin()) with check (public.is_admin());
create policy product_images_admin on public.product_images for all using (public.is_admin()) with check (public.is_admin());
create policy product_variants_admin on public.product_variants for all using (public.is_admin()) with check (public.is_admin());
create policy announcements_admin on public.announcements for all using (public.is_admin()) with check (public.is_admin());

-- Datos sensibles y operativos: solo administradores (lectura y escritura)
create policy inventory_movements_admin on public.inventory_movements for all using (public.is_admin()) with check (public.is_admin());
create policy customers_admin   on public.customers   for all using (public.is_admin()) with check (public.is_admin());
create policy orders_admin      on public.orders      for all using (public.is_admin()) with check (public.is_admin());
create policy order_items_admin on public.order_items for all using (public.is_admin()) with check (public.is_admin());
create policy payments_admin    on public.payments    for all using (public.is_admin()) with check (public.is_admin());
create policy audit_logs_admin  on public.audit_logs  for all using (public.is_admin()) with check (public.is_admin());

-- Administradores: solo lectura de la lista; gestión de roles vía service role (no expuesta)
create policy admin_users_read on public.admin_users for select using (public.is_admin());

-- Pedidos: ningún cliente anónimo puede insertar directamente; solo vía create_order().
-- Permisos de ejecución de la función:
revoke execute on function public.create_order(text, jsonb, jsonb) from public;
grant  execute on function public.create_order(text, jsonb, jsonb) to anon, authenticated;
revoke execute on function public.is_admin() from public;
grant  execute on function public.is_admin() to anon, authenticated;
