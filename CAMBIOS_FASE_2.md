# HM Store — Cambios Fase 2: Hero con Galería

## Resumen
Se rediseñó el Hero para presentar la colección Animal Print mediante una galería de 3 modelos en layout horizontal. El fondo cambió a blanco, permitiendo que las fotos de moda sean protagonistas. El contenido se mantuvo a la izquierda, creando composición editorial balanceada.

## Cambios de Estructura

### HTML (index.html)
- `.hero__media` ahora contiene `.hero__gallery` (no `.hero__frame`)
- Galería se renderiza dinámicamente con `window.HM_DATA.featured.gallery`
- Badge movido dentro de `.hero__media`

### Datos (data/campaigns.js)
```javascript
gallery: [
  { src: "assets/campaigns/animal-print/hero-01.jpg", alt: "..." },
  { src: "assets/campaigns/animal-print/hero-02.jpg", alt: "..." },
  { src: "assets/campaigns/animal-print/hero-03.jpg", alt: "..." },
]
```
- Nuevo campo `gallery` con array de objetos imagen
- `theme.bg` = `#FFFFFF` (blanco)
- `theme.accent` = `#F653BD` (rosa HM)

### CSS (css/hero.css)
```css
.hero {
  grid-template-columns: 1fr 1.5fr;
}
.hero__gallery {
  display: flex;
  gap: clamp(0.75rem, 2vw, 1.5rem);
  height: 100%;
}
.hero__img-item {
  flex: 1;
  height: 100%;
  border-radius: 8px;
}
```

### JavaScript (js/hero.js)
- Nueva función `renderGallery(gallery, provisional)` renderiza elementos dinámicamente
- Carga asincrónica de imágenes
- Espera máximo 1,5s antes de mostrar animaciones

## Comportamiento Responsivo

### Desktop (> 900px)
- Galería: flex vertical, 3 imágenes lado a lado en columna
- Aspect ratio: 400×800 (tall format)
- Content: 40% ancho izquierda, Media: 60% derecha

### Tablet (900px–1024px)
- Similar a desktop, galería más comprimida

### Mobile (< 900px)
- Grid 2×1: 2 imágenes arriba (50% cada), 1 abajo (100%, más grande)
- Content aparece debajo en stack vertical

### Mobile pequeño (< 480px)
- Stack vertical: 1 imagen por línea
- Content debajo

## Imágenes Nuevas

| Archivo | Tamaño | Descripción |
|---------|--------|-------------|
| `hero-01.jpg` | 46 KB | Modelo izquierda (camiseta rosa) |
| `hero-02.jpg` | 76 KB | Modelo centro (camiseta crema) |
| `hero-03.jpg` | 59 KB | Modelo derecha (camiseta blanca) |

Procesadas desde la foto completa (1536×1024) mediante crop + resize a 400×800, JPEG quality 85.

## Animaciones

Las 3 imágenes entran juntas con:
- **slide-in**: traslación desde derecha (800ms, ease-out, delay 120ms)
- **zoom-settle**: escala desde 105% a 100% (1600ms, ease-out, delay 120ms)

Todas respetan `prefers-reduced-motion`.

## Verificación

✓ Probado en chrome dev tools:
- 1440px desktop: 3 imágenes lado a lado ✓
- 768px tablet: 3 imágenes lado a lado ✓  
- 390px mobile: grid 2+1 ✓
- Sin errores en consola ✓

## Próximas Fases

1. **Página de detalle del producto** (SKU, tallas, colores, precio, stock)
2. **Carrito de compra** (agregar/eliminar, cantidad)
3. **Checkout** (datos cliente, resumen, WhatsApp)
4. **Panel administrativo** (CRUD de productos, inventario, pedidos)

---

**Estado**: COMPLETADO Y VERIFICADO ✓  
**Fecha**: 14 oct 2026
