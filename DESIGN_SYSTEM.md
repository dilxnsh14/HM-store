# HM Store — Sistema de diseño

Fuente de negocio: `Contexto_Real_HM_Store_para_Claude.md` y `Paleta_de_Colores_HM_Store.md`.
Guía visual interna: `sistema.html` (noindex; contenido de ejemplo).

## Archivos
`css/tokens.css` (variables) · `css/base.css` · `css/components.css` · `css/hero.css` · `js/ui.js` · `js/hero.js` · `data/campaigns.js`.

## Estado de la información
| Elemento | Estado |
|---|---|
| Nombre HM Boutique / HM Store, ropa y calzado | Confirmado |
| Colección "Animal Print" (nombre) | Confirmado; prendas, fotos y textos pendientes |
| Paleta: rosa `#F653BD`, negro, blanco, gris suave `#F5F3F4`, gris medio `#777777`, gris claro `#E8E5E7` | Selección de trabajo. El rosa es aproximación, no oficial |
| `#666666` (gris de texto pequeño) y rojo de error `#b3261e` | **Propuesta** mía: `#777777` da 4.48:1 sobre blanco y 4.05:1 sobre gris suave (<4.5). Requiere aprobación |
| Tipografía (hoy Bodoni Moda + Hanken Grotesk, Google Fonts, licencia OFL) | **Provisional**: recomendación pendiente de aprobación; alojar localmente al aprobar |
| Menú | Solo "Colección" (existe). Ropa/calzado no se enlazan hasta que existan sus páginas |
| Marcas, contacto, WhatsApp, pagos, envíos, políticas | Pendientes: no se muestran |

## Reglas de color
Blanco predominante; negro para titulares, navegación y CTA; rosa solo en acentos (hover del botón, punto de la cinta, detalles); grises para jerarquía. Sin colores de marca nuevos. Blanco sobre rosa da 3.05:1: no usar texto pequeño blanco sobre rosa (se usa negro, 6.89:1).

## Otras reglas
- Enlace sin destino real = botón deshabilitado (`aria-disabled`, sin `href`).
- Disponibilidad con punto + texto, nunca solo color.
- Objetivos táctiles ≥44px, foco visible, `prefers-reduced-motion` respetado.
- Datos de ejemplo siempre rotulados ("Ejemplo", `$00.000`).

## Integración futura
Menú desde categorías/marcas reales; tarjetas desde el catálogo; `data-max` de cantidad = stock validado en servidor.
