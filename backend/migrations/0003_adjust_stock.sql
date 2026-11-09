-- HM Store — Migración 0003: ajustes de inventario transaccionales
-- Objetivo: impedir cambios directos de stock_qty sin movimiento ni auditoría.
--  * Los administradores ya no pueden escribir stock_qty con UPDATE/INSERT directo.
--  * Todo ajuste pasa por public.adjust_stock(), que en una sola transacción:
--      valida permisos, motivo, delta y existencias; actualiza el stock;
--      registra inventory_movements y audit_logs.
--  * Solo aplica a productos con fulfillment = 'stock'.
-- Esta migración es aditiva: no altera datos existentes ni políticas RLS.

-- ============================================================
-- 1. Quitar escritura directa de stock_qty a authenticated
-- ============================================================
-- Supabase concede UPDATE/INSERT de tabla a authenticated. Se revoca la tabla
-- completa y se vuelve a conceder solo sobre columnas que no son stock.
revoke insert, update on public.product_variants from authenticated;
grant  insert (product_id, size, color_name, color_hex, is_active)
  on public.product_variants to authenticated;
grant  update (product_id, size, color_name, color_hex, is_active)
  on public.product_variants to authenticated;

-- ============================================================
-- 2. Función de ajuste transaccional
-- ============================================================
create or replace function public.adjust_stock(
  p_variant_id uuid,
  p_delta      integer,
  p_reason     text,
  p_note       text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor    uuid := auth.uid();
  v_variant  public.product_variants%rowtype;
  v_product  public.products%rowtype;
  v_before   integer;
  v_after    integer;
begin
  -- Permisos: solo administradores
  if not public.is_admin() then
    raise exception 'No autorizado para ajustar inventario' using errcode = '42501';
  end if;

  -- Motivo permitido
  if p_reason is null or p_reason not in ('manual_adjustment', 'restock') then
    raise exception 'Motivo de ajuste inválido: %', coalesce(p_reason, 'nulo');
  end if;

  -- Delta válido
  if p_delta is null or p_delta = 0 then
    raise exception 'El ajuste debe ser distinto de cero';
  end if;

  -- Bloqueo de la variante durante la transacción (evita carreras entre ajustes y pedidos)
  select * into v_variant
    from public.product_variants
    where id = p_variant_id
    for update;

  if not found then
    raise exception 'Variante no encontrada';
  end if;

  select * into v_product from public.products where id = v_variant.product_id;

  if v_product.fulfillment <> 'stock' then
    raise exception 'El producto no maneja inventario físico (print_on_demand)';
  end if;

  v_before := coalesce(v_variant.stock_qty, 0);
  v_after  := v_before + p_delta;

  if v_after < 0 then
    raise exception 'El ajuste dejaría el stock en negativo (actual: %, ajuste: %)', v_before, p_delta;
  end if;

  update public.product_variants
    set stock_qty = v_after
    where id = v_variant.id;

  insert into public.inventory_movements (variant_id, delta, reason, actor_id, note)
    values (v_variant.id, p_delta, p_reason, v_actor, p_note);

  insert into public.audit_logs (actor_id, action, entity, entity_id, diff)
    values (
      v_actor,
      'adjust_stock',
      'product_variants',
      v_variant.id::text,
      jsonb_build_object(
        'before', v_before,
        'after', v_after,
        'delta', p_delta,
        'reason', p_reason,
        'note', p_note
      )
    );

  return v_after;
end $$;

-- ============================================================
-- 3. Permisos de ejecución
-- ============================================================
revoke execute on function public.adjust_stock(uuid, integer, text, text) from public, anon;
grant  execute on function public.adjust_stock(uuid, integer, text, text) to authenticated;
