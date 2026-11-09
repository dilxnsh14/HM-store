-- Sesión de ajuste: argumentos por variable psql -v delta=... -v hold=...
set role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000009', false);
begin;
select public.adjust_stock('55555555-0000-0000-0000-000000000001', :delta, 'manual_adjustment', 'concurrencia');
select pg_sleep(:hold);
commit;
