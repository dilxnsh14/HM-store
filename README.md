# HM Store — Hero Experience (Fase 2)

Base mínima sin dependencias (HTML + CSS + JS).

## Cómo verlo en tu computador
1. Descomprime el zip.
2. Opción simple: doble clic en `index.html` (funciona sin servidor).
3. Opción recomendada (se comporta como un sitio real): en la carpeta `hm-store` ejecuta
   `python3 -m http.server 8000` y abre http://localhost:8000
   (o `npx serve` si usas Node). Requiere conexión a internet para cargar las tipografías de Google Fonts;
   sin ella se ve con tipografías de reserva.

## Estructura
- `index.html` — cinta de anuncio, cabecera mínima provisional y Hero.
- `css/hero.css` — estilos, secuencia de entrada, responsive y `prefers-reduced-motion`.
- `js/hero.js` — lee `window.HM_DATA`, pinta el Hero, cambio de campaña (`HMHero.setCampaign`), cinta y parallax discreto.
- `data/campaigns.js` — **única fuente** de la colección destacada y la cinta. Hoy se edita a mano; el panel admin es una fase posterior.
- `assets/brand/` — logotipo oficial entregado por HM (`logo-hm-boutique.png`, intacto) y una copia con márgenes blancos recortados (`-recortado.png`) usada en la cabecera.

## Cómo poner la campaña real
1. Copiar la fotografía a `assets/campaigns/<slug>/` (recomendado: JPG/WebP ~1600 px de alto, y variantes con `srcset`).
2. En `data/campaigns.js`: rellenar `collection`, `title`, `description`, `cta`, `image.src`, `image.alt`, `image.focal` y `theme`; poner `provisional: false`.
3. Para activar la cinta: `announcement.enabled = true` con mensaje y enlace de una novedad real.

## Movimiento (ya implementado)
- Titular por líneas: cada palabra tiene su máscara y cada línea entra con 110 ms de retardo respecto a la anterior (`--line`).
- Parallax de la imagen con el scroll: solo escritorio (>900 px) y sin movimiento reducido; la imagen es un 12 % más alta que el marco para no dejar huecos.
- Parallax del fondo con el puntero: solo escritorio con ratón.
- Movimiento reducido: todo pasa a un fundido de 0,2 s, sin desplazamientos, y la cinta queda estática.

## Estados del Hero (comportamiento ya implementado)
- `image.src: null` o imagen que no carga -> marcador rosa + etiqueta "Contenido provisional".
- `cta.href: null` o ancla inexistente -> el botón queda deshabilitado (borde punteado, sin enlace, no enfocable). Nunca apunta a una colección inexistente.
- `cta.href` solo acepta rutas relativas, anclas existentes o http(s); cualquier otro esquema (p. ej. `javascript:`) se rechaza.
- `announcement.enabled: false` -> la cinta no ocupa espacio.

## Pendiente de HM
Fotografía de campaña real (y `image.alt` que la describa), nombre de la colección, textos definitivos, destino del CTA, novedad real para la cinta, y si el Hero debe usar el rosa del logotipo en todas las campañas.
