# Migraciones de HM Store

## Secuencia para una instalación nueva

Aplicar en este orden, sobre un proyecto Supabase vacío:

1. `0001_schema.sql`: schema base, incluye `products.fulfillment` (versión final del esquema inicial).
2. `0003_adjust_stock.sql`: ajustes de inventario transaccionales (`adjust_stock`).
3. `0004_order_limits.sql`: tabla `store_settings` y `create_order` con límites.

Las pruebas viven en `backend/tests/` y se ejecutan contra bases locales o de prueba, nunca contra producción.

## Proyecto de producción existente

El proyecto `ghkhbayyoabcaqjijslc` tiene aplicado el historial siguiente:

- `0001_schema` (versión original, sin `fulfillment`)
- `0002_print_on_demand` (añade `products.fulfillment` y cambia `create_order`)
- `0003_adjust_stock`
- `0004_order_limits`

`0002` no existe como archivo en el repo porque su contenido ya está incluido en `0001_schema.sql`. No vuelvas a aplicar `0002` en una instalación nueva.

## Reglas

- No modificar migraciones ya aplicadas. Los cambios van en una migración nueva.
- Toda migración debe tener su prueba en `backend/tests/`.
- Antes de aplicar en Supabase, reproducir la secuencia completa en una base local.
