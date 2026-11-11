-- Pruebas de límites de create_order y store_settings (migración 0004)
-- SOLO base local/de prueba. Todo queda revertido al final (rollback).
-- Uso: psql -d hm_test -v ON_ERROR_STOP=1 -f backend/tests/0004_order_limits.test.sql

\set ON_ERROR_STOP on
begin;

-- ---------- Fixture (superusuario) ----------
insert into public.products (id, sku, name, price_cop, status, fulfillment) values
  ('66666666-0000-0000-0000-000000000001', 'L-POD', 'Límites POD',  1000, 'published', 'print_on_demand'),
  ('66666666-0000-0000-0000-000000000002', 'L-STK', 'Límites stock', 500, 'published', 'stock'),
  ('66666666-0000-0000-0000-000000000003', 'L-DRF', 'Límites draft', 700, 'draft',     'print_on_demand');
insert into public.product_variants (id, product_id, size, color_name, stock_qty) values
  ('77777777-0000-0000-0000-000000000001', '66666666-0000-0000-0000-000000000001', 'M', 'Negro', null),
  ('77777777-0000-0000-0000-000000000002', '66666666-0000-0000-0000-000000000002', 'M', 'Negro', 10),
  ('77777777-0000-0000-0000-000000000003', '66666666-0000-0000-0000-000000000002', 'L', 'Negro', 10),
  ('77777777-0000-0000-0000-000000000004', '66666666-0000-0000-0000-000000000003', 'M', 'Negro', null);

create or replace function pg_temp.try_as(p_role text, p_uid text, p_sql text)
returns text language plpgsql as $$
declare v_err text;
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_uid, ''), true);
  execute format('set local role %I', p_role);
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

-- Payload base
-- p_items usa variantes del fixture

-- ---------- 1. Sin límites configurados: rechazo (fail closed) ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-sin-limites-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":1}]')$q$);
  perform pg_temp.check('sin límites configurados: pedido rechazado', v_err like '%no están configurados%');
end $$;

-- ---------- 2. Configuración de límites (superusuario) ----------
insert into public.store_settings (key, value) values
  ('checkout.max_units_per_item',  '3'),
  ('checkout.max_lines_per_order', '2'),
  ('internal.secreto', '"no debe verse"');

-- ---------- 3. Lectura de configuración por anon ----------
do $$
declare v_count integer; v_err text; v_val jsonb;
begin
  execute 'set local role anon';
  select count(*) into v_count from public.store_settings;
  execute 'reset role';
  perform pg_temp.check('anon solo ve claves checkout.* (2 de 3)', v_count = 2);
end $$;

do $$
declare v_err text; v_val jsonb;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$update public.store_settings set value = '99' where key = 'checkout.max_units_per_item'$q$);
  select value into v_val from public.store_settings where key = 'checkout.max_units_per_item';
  perform pg_temp.check('anon no puede modificar límites (valor intacto = 3)', v_val = '3'::jsonb);
end $$;

-- ---------- 4. Cantidad mayor al máximo ----------
do $$
declare v_err text; v_stock integer;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-cantidad-alta-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000002","quantity":4}]')$q$);
  select stock_qty into v_stock from public.product_variants where id = '77777777-0000-0000-0000-000000000002';
  perform pg_temp.check('cantidad 4 > máximo 3 rechazada', v_err like '%máxima por artículo es 3%');
  perform pg_temp.check('stock intacto tras rechazo por cantidad (10)', v_stock = 10);
end $$;

-- ---------- 5. Más líneas que el máximo ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-lineas-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":1},{"variant_id":"77777777-0000-0000-0000-000000000002","quantity":1},{"variant_id":"77777777-0000-0000-0000-000000000003","quantity":1}]')$q$);
  perform pg_temp.check('3 líneas > máximo 2 rechazado', v_err like '%máximo de 2 líneas%');
end $$;

-- ---------- 6. Misma variante repetida en dos líneas ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-repetida-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":2},{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":2}]')$q$);
  perform pg_temp.check('variante repetida rechazada (no se puede eludir el máximo)', v_err like '%más de una vez%');
end $$;

-- ---------- 7. Producto en borrador ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-borrador-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000004","quantity":1}]')$q$);
  perform pg_temp.check('producto en borrador no vendible', v_err like '%no está disponible%');
end $$;

-- ---------- 8. Clave de idempotencia y cantidades inválidas ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('corta', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":1}]')$q$);
  perform pg_temp.check('clave de idempotencia corta rechazada', v_err like '%idempotencia inválida%');

  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-cantidad-cero-1', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":0}]')$q$);
  perform pg_temp.check('cantidad 0 rechazada', v_err like '%Cantidad inválida%');
end $$;

-- ---------- 9. Pedido válido dentro de límites ----------
do $$
declare v_err text; v_stock integer; v_total integer; v_items integer; v_mov integer;
begin
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-valido-0001', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000002","quantity":2},{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":3}]')$q$);
  perform pg_temp.check('pedido válido aceptado (anon)', v_err is null);

  select total_cop into v_total from public.orders where idempotency_key = 'key-valido-0001';
  select count(*) into v_items from public.order_items o join public.orders p on p.id = o.order_id where p.idempotency_key = 'key-valido-0001';
  select stock_qty into v_stock from public.product_variants where id = '77777777-0000-0000-0000-000000000002';
  select count(*) into v_mov from public.inventory_movements where variant_id = '77777777-0000-0000-0000-000000000002' and delta = -2;
  perform pg_temp.check('total = 2*500 + 3*1000 = 4000', v_total = 4000);
  perform pg_temp.check('dos líneas guardadas', v_items = 2);
  perform pg_temp.check('stock 10 -> 8 (solo producto stock)', v_stock = 8);
  perform pg_temp.check('movimiento de inventario -2 registrado', v_mov = 1);
end $$;

-- ---------- 10. Reenvío idempotente ----------
do $$
declare v_err text; v_orders integer; v_stock integer; v_before uuid; v_after uuid;
begin
  select id into v_before from public.orders where idempotency_key = 'key-valido-0001';
  v_err := pg_temp.try_as('anon', null,
    $q$select * from public.create_order('key-valido-0001', '{"name":"Ana","phone":"300"}', '[{"variant_id":"77777777-0000-0000-0000-000000000002","quantity":2},{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":3}]')$q$);
  select id into v_after from public.orders where idempotency_key = 'key-valido-0001';
  select count(*) into v_orders from public.orders where idempotency_key = 'key-valido-0001';
  select stock_qty into v_stock from public.product_variants where id = '77777777-0000-0000-0000-000000000002';
  perform pg_temp.check('reenvío idempotente sin error', v_err is null);
  perform pg_temp.check('reenvío devuelve el mismo pedido', v_before = v_after and v_orders = 1);
  perform pg_temp.check('reenvío no vuelve a descontar stock (8)', v_stock = 8);
end $$;

-- ---------- 11. Usuario autenticado también puede comprar dentro de límites ----------
do $$
declare v_err text;
begin
  v_err := pg_temp.try_as('authenticated', 'bbbbbbbb-0000-0000-0000-000000000002',
    $q$select * from public.create_order('key-auth-0001', '{"name":"Luis","phone":"301"}', '[{"variant_id":"77777777-0000-0000-0000-000000000001","quantity":1}]')$q$);
  perform pg_temp.check('pedido válido por usuario autenticado', v_err is null);
end $$;

-- ---------- 12. Verificación global ----------
do $$
begin
  perform pg_temp.check('ningún pedido de prueba excede 3 unidades por línea',
    not exists (select 1 from public.order_items where quantity > 3));
  perform pg_temp.check('ningún pedido de prueba excede 2 líneas',
    not exists (select 1 from (select order_id from public.order_items group by order_id having count(*) > 2) x));
end $$;

rollback;
\echo 'PRUEBAS 0004: TODAS LAS VERIFICACIONES PASARON (transacción revertida)'
