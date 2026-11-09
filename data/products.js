/*
 * HM Store — Catálogo de Productos (Provisional)
 *
 * ESTADO: CONTENIDO PROVISIONAL. HM aún no ha entregado datos reales.
 * Todo lo marcado con `provisional: true` se muestra con una etiqueta visible.
 *
 * Estructura:
 *   id              -> identificador único del producto
 *   sku             -> código comercial (SKU)
 *   name            -> nombre de la prenda
 *   collection      -> colección a la que pertenece
 *   brand           -> marca (cuando aplique)
 *   description     -> descripción editorial
 *   price           -> precio base (sin descuentos)
 *   provisional     -> indica contenido provisional
 *   images          -> array de imágenes [{ src, alt }]
 *   sizes           -> array de tallas disponibles
 *   colors          -> array de colores [{ name, hex, available }]
 *   stock           -> cantidad disponible (null = no confirmada)
 *   featured        -> destacado en galería (true/false)
 */

window.HM_PRODUCTS = {
  // Colección: Animal Print
  // 12 productos reales fotografiados

  "ap-001": {
    id: "ap-001",
    sku: "ANIM-001-BLK",
    provisional: true,
    name: "Camiseta Animal Print — Brooklyn",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con la palabra BROOKLYN en letras con distintos patrones animal print. Confección básica, algodón 100%, corte relajado. Perfecta para crear looks casuales con presencia.",
    price: null, // Pendiente de HM
    images: [
      { src: "assets/campaigns/animal-print/01-800.jpg", alt: "Camiseta blanca con BROOKLYN animal print — vista frontal" },
      { src: "assets/campaigns/animal-print/01-480.jpg", alt: "Camiseta blanca con BROOKLYN animal print — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: true,
  },

  "ap-002": {
    id: "ap-002",
    sku: "ANIM-002-PNK",
    provisional: true,
    name: "Camiseta Animal Print — Corazones Love",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta rosa con corazones de leopardo y la palabra love. Diseño romántico con estampado animal print. Algodón orgánico, confección sostenible.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/02-800.jpg", alt: "Camiseta rosa con corazones leopardo — vista frontal" },
      { src: "assets/campaigns/animal-print/02-480.jpg", alt: "Camiseta rosa con corazones leopardo — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Rosa", hex: "#F653BD", available: true },
    ],
    stock: null,
    featured: true,
  },

  "ap-003": {
    id: "ap-003",
    sku: "ANIM-003-WHT",
    provisional: true,
    name: "Camiseta Animal Print — Lazo Leopardo",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con un lazo de leopardo y dos cerezas. Estampado delicado, detalles en color. Ideal para looks femeninos y casuales.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/03-800.jpg", alt: "Camiseta blanca con lazo leopardo — vista frontal" },
      { src: "assets/campaigns/animal-print/03-480.jpg", alt: "Camiseta blanca con lazo leopardo — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: true,
  },

  "ap-004": {
    id: "ap-004",
    sku: "ANIM-004-CRM",
    provisional: true,
    name: "Camiseta Animal Print — Love Always",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta crema con corazones de leopardo, rojo y estampado de corazones, y el texto Love Always. Mezcla de patrones que transmite movimiento y energía.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/04-800.jpg", alt: "Camiseta crema Love Always — vista frontal" },
      { src: "assets/campaigns/animal-print/04-480.jpg", alt: "Camiseta crema Love Always — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Crema", hex: "#F5F3F4", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-005": {
    id: "ap-005",
    sku: "ANIM-005-WHT",
    provisional: true,
    name: "Camiseta Animal Print — Triple Corazón",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con tres corazones: rojo con brillo, de rayas y de leopardo. Composición asimétrica que juega con texturas y estilos.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/05-800.jpg", alt: "Camiseta blanca triple corazón — vista frontal" },
      { src: "assets/campaigns/animal-print/05-480.jpg", alt: "Camiseta blanca triple corazón — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-006": {
    id: "ap-006",
    sku: "ANIM-006-WHT",
    provisional: true,
    name: "Camiseta Animal Print — Corazones Superpuestos",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con corazones superpuestos en leopardo y rayas en tonos marrón. Composición sobrepuesta que crea profundidad visual.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/06-800.jpg", alt: "Camiseta blanca corazones superpuestos — vista frontal" },
      { src: "assets/campaigns/animal-print/06-480.jpg", alt: "Camiseta blanca corazones superpuestos — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-007": {
    id: "ap-007",
    sku: "ANIM-007-PNK",
    provisional: true,
    name: "Camiseta Animal Print — Corazones Entrelazados",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta rosa con corazones entrelazados de leopardo y brillo dorado. Toque elegante y sofisticado para looks nocturnos o especiales.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/07-800.jpg", alt: "Camiseta rosa corazones entrelazados — vista frontal" },
      { src: "assets/campaigns/animal-print/07-480.jpg", alt: "Camiseta rosa corazones entrelazados — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Rosa", hex: "#F653BD", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-008": {
    id: "ap-008",
    sku: "ANIM-008-WHT",
    provisional: true,
    name: "Camiseta Animal Print — Country Heart",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con un corazón de estampado de vaca y el texto Country Heart. Mezcla urbana-rural que juega con el contraste de estilos.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/08-800.jpg", alt: "Camiseta blanca Country Heart — vista frontal" },
      { src: "assets/campaigns/animal-print/08-480.jpg", alt: "Camiseta blanca Country Heart — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-009": {
    id: "ap-009",
    sku: "ANIM-009-CRM",
    provisional: true,
    name: "Camiseta Animal Print — Live a Good Life",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta crema con tres corazones de leopardo y la frase Live a good life meet slowly. Mensaje inspiracional con estampado editorial.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/09-800.jpg", alt: "Camiseta crema Live a Good Life — vista frontal" },
      { src: "assets/campaigns/animal-print/09-480.jpg", alt: "Camiseta crema Live a Good Life — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Crema", hex: "#F5F3F4", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-010": {
    id: "ap-010",
    sku: "ANIM-010-PNK",
    provisional: true,
    name: "Camiseta Animal Print — Mama's Girl",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta rosa con el texto mama's GIRL en letras de leopardo. Diseño cariñoso, perfecto para looks familiares o regalos especiales.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/10-800.jpg", alt: "Camiseta rosa Mama's Girl — vista frontal" },
      { src: "assets/campaigns/animal-print/10-480.jpg", alt: "Camiseta rosa Mama's Girl — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Rosa", hex: "#F653BD", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-011": {
    id: "ap-011",
    sku: "ANIM-011-WHT",
    provisional: true,
    name: "Camiseta Animal Print — Attitude",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta blanca con un corazón de cebra, brillo y leopardo, y la palabra Attitude. Actitud desafiante, perfecta para looks con presencia.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/11-800.jpg", alt: "Camiseta blanca Attitude — vista frontal" },
      { src: "assets/campaigns/animal-print/11-480.jpg", alt: "Camiseta blanca Attitude — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Blanco", hex: "#FFFFFF", available: true },
    ],
    stock: null,
    featured: false,
  },

  "ap-012": {
    id: "ap-012",
    sku: "ANIM-012-CRM",
    provisional: true,
    name: "Camiseta Animal Print — Love Vertical",
    collection: { name: "Animal Print", slug: "animal-print" },
    brand: null,
    description:
      "Camiseta crema con un corazón de leopardo y la palabra love en vertical. Composición minimalista, perfecto para looks simples pero impactantes.",
    price: null,
    images: [
      { src: "assets/campaigns/animal-print/12-800.jpg", alt: "Camiseta crema Love Vertical — vista frontal" },
      { src: "assets/campaigns/animal-print/12-480.jpg", alt: "Camiseta crema Love Vertical — detalle" },
    ],
    sizes: ["XS", "S", "M", "L", "XL"],
    colors: [
      { name: "Crema", hex: "#F5F3F4", available: true },
    ],
    stock: null,
    featured: false,
  },
};

// Helper: obtener producto por ID
window.HM_getProduct = function (productId) {
  return window.HM_PRODUCTS[productId] || null;
};

// Helper: obtener todos los productos de una colección
window.HM_getProductsByCollection = function (collectionSlug) {
  return Object.values(window.HM_PRODUCTS).filter(
    (p) => p.collection && p.collection.slug === collectionSlug
  );
};

// Helper: obtener productos destacados
window.HM_getFeaturedProducts = function () {
  return Object.values(window.HM_PRODUCTS).filter((p) => p.featured);
};
