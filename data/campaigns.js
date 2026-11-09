/*
 * HM Store — fuente única de datos del Hero y de la cinta de anuncio.
 *
 * ESTADO: CONTENIDO PROVISIONAL. HM aún no ha entregado fotografías de
 * campaña, nombre de colección ni textos definitivos. Todo lo marcado con
 * `provisional: true` se muestra con una etiqueta visible y NO debe
 * publicarse como información real.
 *
 * Esta estructura es la que más adelante alimentará el panel administrativo
 * (fase posterior). Hoy se edita a mano; no existe panel todavía.
 *
 * Campos de `featured` (una sola colección protagonista):
 *   collection.name / slug  -> colección asociada (pendiente de HM)
 *   title, description      -> textos de campaña
 *   cta.label / cta.href    -> botón principal y destino (href null o inexistente => botón deshabilitado)
 *   image.src               -> ruta de la fotografía real (null = marcador)
 *   image.alt               -> descripción accesible de la fotografía
 *   image.focal             -> punto focal por tamaño para el recorte
 *   theme                   -> fondo, tinta y acento propios de la campaña
 */
window.HM_DATA = {
  featured: {
    id: "provisional-001",
    provisional: true,
    collection: { name: "Animal Print", slug: null }, // nombre confirmado; prendas y fotos pendientes
    title: "Animal Print",
    description:
      "Estampados que hablan por ti. La primera colección de HM con la actitud del animal print.",
    cta: { label: "Descubrir Colección", href: "#coleccion" },
    // Imagen de fondo: foto completa de modelos
    backgroundImage: {
      src: "assets/campaigns/animal-print/hero-background.jpg",
      alt: "Modelos de la colección Animal Print",
    },
    theme: {
      bg: "#F5F3F4", // fondo gris suave para overlay/contenido
      ink: "#000000",
      accent: "#F653BD", // rosa HM para acentos
    },
  },

  // Cinta de anuncio. Desactivada hasta que HM confirme una novedad real.
  announcement: {
    enabled: true,
    message: "Nueva colección · Animal Print",
    href: "#coleccion",
  },

  // Fotografías reales de la colección Animal Print (entregadas por HM).
  // PENDIENTE de HM: nombres de producto, precios, tallas, colores, stock y orden definitivo.
  // `n` es solo un número de trabajo, no un nombre comercial.
  collectionPreview: [
    { n: "01", alt: "Camiseta blanca con la palabra BROOKLYN en letras con distintos patrones animal print" },
    { n: "02", alt: "Camiseta rosa con corazones de leopardo y la palabra love" },
    { n: "03", alt: "Camiseta blanca con un lazo de leopardo y dos cerezas" },
    { n: "04", alt: "Camiseta crema con corazones de leopardo, rojo y estampado de corazones, y el texto Love Always" },
    { n: "05", alt: "Camiseta blanca con tres corazones: rojo con brillo, de rayas y de leopardo" },
    { n: "06", alt: "Camiseta blanca con corazones superpuestos en leopardo y rayas en tonos marrón" },
    { n: "07", alt: "Camiseta rosa con corazones entrelazados de leopardo y brillo dorado" },
    { n: "08", alt: "Camiseta blanca con un corazón de estampado de vaca y el texto Country Heart" },
    { n: "09", alt: "Camiseta crema con tres corazones de leopardo y la frase Live a good life meet slowly" },
    { n: "10", alt: "Camiseta rosa con el texto mama's GIRL en letras de leopardo" },
    { n: "11", alt: "Camiseta blanca con un corazón de cebra, brillo y leopardo, y la palabra Attitude" },
    { n: "12", alt: "Camiseta crema con un corazón de leopardo y la palabra love en vertical" },
  ],
};
