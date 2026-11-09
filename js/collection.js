/* HM Store — Galería de Colección. Lee window.HM_PRODUCTS (data/products.js).
 * Renderiza productos de la colección Animal Print con enlace a detalle.
 */
(function () {
  "use strict";
  var list = document.getElementById("product-grid");
  if (!list || !window.HM_PRODUCTS) return;

  // Obtener productos de Animal Print
  var products = window.HM_getProductsByCollection("animal-print");

  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text) n.textContent = text;
    return n;
  }

  products.forEach(function (product, idx) {
    // Card container
    var li = el("li", "card reveal");
    li.style.setProperty("--d", (idx % 4) * 80 + "ms");

    // Link a detalle del producto
    var link = document.createElement("a");
    link.href = "producto.html?id=" + product.id;
    link.className = "card__link";

    // Media
    var media = el("div", "card__media");
    if (product.images && product.images[0]) {
      var img = document.createElement("img");
      img.src = product.images[0].src;
      img.alt = product.name;
      img.loading = "lazy";
      img.decoding = "async";
      media.appendChild(img);
    }

    // Badge de provisional
    if (product.provisional) {
      media.appendChild(el("span", "card__tag tag", "Información provisional"));
    }

    // Body
    var body = el("div", "card__body");
    body.appendChild(el("p", "card__brand", product.collection ? product.collection.name : ""));
    body.appendChild(el("h3", "card__title", product.name));
    var priceText = product.price ? "$" + product.price.toLocaleString() : "Precio por confirmar";
    body.appendChild(el("p", "card__price", priceText));

    // Armar el card
    link.appendChild(media);
    link.appendChild(body);
    li.appendChild(link);
    list.appendChild(li);
  });
})();
