insert into auth.users (id) values ('aaaaaaaa-0000-0000-0000-000000000009') on conflict do nothing;
insert into public.admin_users (user_id, email, role) values ('aaaaaaaa-0000-0000-0000-000000000009','admin2@test.local','owner') on conflict do nothing;
insert into public.products (id, sku, name, price_cop, status, fulfillment) values ('44444444-0000-0000-0000-000000000001','C-STK','Concurrencia',1000,'published','stock') on conflict do nothing;
insert into public.product_variants (id, product_id, size, color_name, stock_qty) values ('55555555-0000-0000-0000-000000000001','44444444-0000-0000-0000-000000000001','M','Negro',5) on conflict (id) do update set stock_qty = 5;
delete from public.inventory_movements where variant_id = '55555555-0000-0000-0000-000000000001';
