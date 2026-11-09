-- Pruebas de public.adjust_stock (migración 0003)
-- Ejecutar SOLO contra base local/de prueba (nunca contra Supabase de producción).
-- Uso: psql -d hm_test -v ON_ERROR_STOP=1 -f backend/tests/0003_adjust_stock.test.sql
-- Cada prueba imprime PASS o lanza error.

\set ON_ERROR_STOP on
begin;

-- ---------- Datos de prueba (como superusuario) ----------
insert into auth.users (id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'),  -- admin
  ('bbbbbbbb-0000-0000-0000-000000000002');  -- no admin
insert into public.admin_users (user_id, email, role) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@test.local', 'owner');

insert into public.products (id, sku, name, price_cop, status, fulfillment) values
  ('11111111-0000-0000-0000-000000000001', 'T-STK', 'Producto stock', 1000, 'published', 'stock'),
  ('11111111-0000-0000-0000-000000000002', 'T-POD', 'Producto POD',   1000, 'published', 'print_on_demand');

insert into public.product_variants (id, product_id, size, color_name, stock_qty) values
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'M', 'Negro', 5),
  ('22222222-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002', 'M', 'Negro', null),
  ('22222222-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000001', 'L', 'Negro', null);

-- Función auxiliar: ejecuta una consulta como usuario dado y devuelve el error (o NULL)
create or replace function pg_temp.try_as(p_uid uuid, p_sql text)
returns text language plpgsql as $$
declare v_err text;
begin
  perform set_config('request.jwt.claim.sub', p_uid::text, true);
  execute 'set local role authenticated';
  begin
    execute p_sql;
    v_err := null;
  exception when others then
    v_err := SQLERRM;
  end;
  execute 'reset role';
  return v_err;
end $$;

create or replace function pg_temp.check(p_name text, p_cond boolean)
returns void language plpgsql as $$
begin
  if p_cond then raise notice 'PASS: %', p_name;
  else raise exception 'FAIL: %', p_name; end if;
end $$;

-- ---------- 1. Ajuste positivo válido ----------
do $$
declare v_err text; v_stock integer;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', 10, 'restock', 'Compra proveedor')$q$);
  select stock_qty into v_stock from public.product_variants where id = '22222222-0000-0000-0000-000000000001';
  perform pg_temp.check('ajuste positivo admin: sin error', v_err is null);
  perform pg_temp.check('ajuste positivo admin: stock 5+10=15', v_stock = 15);
end $$;

-- ---------- 2. Ajuste negativo válido ----------
do $$
declare v_err text; v_stock integer;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', -3, 'manual_adjustment', 'Conteo físico')$q$);
  select stock_qty into v_stock from public.product_variants where id = '22222222-0000-0000-0000-000000000001';
  perform pg_temp.check('ajuste negativo admin: sin error', v_err is null);
  perform pg_temp.check('ajuste negativo admin: stock 15-3=12', v_stock = 12);
end $$;

-- ---------- 3. Movimiento y auditoría registrados ----------
do $$
begin
  perform pg_temp.check('movimiento registrado (2 filas para la variante)',
    (select count(*) from public.inventory_movements where variant_id = '22222222-0000-0000-0000-000000000001') = 2);
  perform pg_temp.check('movimiento con actor y delta correctos',
    exists (select 1 from public.inventory_movements
            where variant_id = '22222222-0000-0000-0000-000000000001'
              and delta = -3 and reason = 'manual_adjustment'
              and actor_id = 'aaaaaaaa-0000-0000-0000-000000000001'));
  perform pg_temp.check('auditoría registrada con before/after',
    exists (select 1 from public.audit_logs
            where action = 'adjust_stock' and entity_id = '22222222-0000-0000-0000-000000000001'
              and (diff->>'before')::int = 15 and (diff->>'after')::int = 12));
end $$;

-- ---------- 4. Negativo que dejaría stock < 0 ----------
do $$
declare v_err text; v_stock integer;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', -100, 'manual_adjustment')$q$);
  select stock_qty into v_stock from public.product_variants where id = '22222222-0000-0000-0000-000000000001';
  perform pg_temp.check('stock negativo rechazado', v_err like '%negativo%');
  perform pg_temp.check('stock intacto tras rechazo (12)', v_stock = 12);
end $$;

-- ---------- 5. Delta cero ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', 0, 'restock')$q$);
  perform pg_temp.check('delta 0 rechazado', v_err like '%distinto de cero%');
end $$;

-- ---------- 6. Motivo inválido ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', 1, 'order')$q$);
  perform pg_temp.check('motivo "order" rechazado en ajuste manual', v_err like '%Motivo de ajuste inválido%');

  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', 1, null)$q$);
  perform pg_temp.check('motivo nulo rechazado', v_err like '%Motivo de ajuste inválido%');
end $$;

-- ---------- 7. Usuario no administrador ----------
do $$
declare v_err text; v_stock integer;
begin
  v_err := pg_temp.try_as('bbbbbbbb-0000-0000-0000-000000000002',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000001', 5, 'restock')$q$);
  select stock_qty into v_stock from public.product_variants where id = '22222222-0000-0000-0000-000000000001';
  perform pg_temp.check('no admin bloqueado por adjust_stock', v_err like '%No autorizado%');
  perform pg_temp.check('stock intacto tras intento no admin (12)', v_stock = 12);
end $$;

-- ---------- 8. Usuario anónimo ----------
do $$
declare v_err text;
begin
  perform set_config('request.jwt.claim.sub', '', true);
  execute 'set local role anon';
  begin
    perform public.adjust_stock('22222222-0000-0000-0000-000000000001', 1, 'restock');
    v_err := null;
  exception when others then v_err := SQLERRM;
  end;
  execute 'reset role';
  perform pg_temp.check('anon sin permiso de ejecución', v_err like '%permission denied%');
end $$;

-- ---------- 9. Producto print_on_demand ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('22222222-0000-0000-0000-000000000002', 5, 'restock')$q$);
  perform pg_temp.check('ajuste en POD rechazado', v_err like '%print_on_demand%');
end $$;

-- ---------- 10. Variante inexistente ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$select public.adjust_stock('99999999-0000-0000-0000-000000000000', 1, 'restock')$q$);
  perform pg_temp.check('variante inexistente rechazada', v_err like '%no encontrada%');
end $$;

-- ---------- 11. Escritura directa de stock_qty bloqueada ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$update public.product_variants set stock_qty = 999 where id = '22222222-0000-0000-0000-000000000001'$q$);
  perform pg_temp.check('UPDATE directo de stock_qty bloqueado para admin', v_err like '%permission denied%');

  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$insert into public.product_variants (product_id, size, color_name, stock_qty) values ('11111111-0000-0000-0000-000000000001', 'XL', 'Negro', 50)$q$);
  perform pg_temp.check('INSERT con stock_qty bloqueado para admin', v_err like '%permission denied%');
end $$;

-- ---------- 12. Admin sí puede editar columnas que no son stock ----------
do $$
declare v_err text; v_size text;
begin
  v_err := pg_temp.try_as('aaaaaaaa-0000-0000-0000-000000000001',
    $q$update public.product_variants set size = 'S' where id = '22222222-0000-0000-0000-000000000003'$q$);
  select size into v_size from public.product_variants where id = '22222222-0000-0000-0000-000000000003';
  perform pg_temp.check('admin puede editar talla (no stock)', v_err is null and v_size = 'S');
end $$;

-- ---------- 13. Verificación de consistencia final ----------
do $$
begin
  perform pg_temp.check('stock actual = suma de movimientos (variante 1)',
    (select stock_qty from public.product_variants where id = '22222222-0000-0000-0000-000000000001')
    = (select 5 + coalesce(sum(delta), 0) from public.inventory_movements
       where variant_id = '22222222-0000-0000-0000-000000000001'));
end $$;

rollback;
\echo 'PRUEBAS 0003: TODAS LAS VERIFICACIONES PASARON (transacción revertida)'
