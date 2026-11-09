/* HM Store — Página de Detalle del Producto
 * Lee window.HM_PRODUCTS (data/products.js) y window.HM_DATA (data/campaigns.js).
 * Renderiza el detalle del producto basado en el parámetro URL.
 */
(function () {
  "use strict";

  // Obtener ID del producto desde URL
  var urlParams = new URLSearchParams(window.location.search);
  var productId = urlParams.get("id");

  var product = productId ? window.HM_getProduct(productId) : null;
  var data = window.HM_DATA;

  // Elementos del DOM
  var el = {
    productError: document.getElementById("product-error"),
    productContent: document.getElementById("product-content"),
    galleryMainImage: document.getElementById("gallery-main-image"),
    galleryThumbsContainer: document.getElementById("gallery-thumbs-container"),
    galleryProvisionalBadge: document.getElementById("gallery-provisional-badge"),
    productTitle: document.getElementById("product-title"),
    productSku: document.getElementById("product-sku"),
    productPrice: document.getElementById("product-price"),
    productDescription: document.getElementById("product-description"),
    productCollection: document.getElementById("product-collection"),
    colorSelectorContainer: document.getElementById("color-selector-container"),
    colorSelector: document.getElementById("color-selector"),
    sizeSelector: document.getElementById("size-selector"),
    quantityInput: document.getElementById("quantity-input"),
    addToCartBtn: document.getElementById("add-to-cart-btn"),
    addToCartFeedback: document.getElementById("add-to-cart-feedback"),
    addToCartMessage: document.getElementById("add-to-cart-message"),
    addToCartText: document.getElementById("add-to-cart-text"),
    stockStatus: document.getElementById("stock-status"),
    productProvisionalNotice: document.getElementById("product-provisional-notice"),
    relatedProductsSection: document.getElementById("related-products-section"),
    breadcrumbProduct: document.getElementById("breadcrumb-product"),
    breadcrumbCollection: document.getElementById("breadcrumb-collection"),
  };

  // Estado
  var state = {
    selectedColor: null,
    selectedSize: null,
    isAdding: false,
  };

  // Validar que el producto existe
  if (!product) {
    el.productError.hidden = false;
    el.productContent.hidden = true;
    return;
  }

  // ---------- RENDERIZAR GALERÍA ----------
  function renderGallery() {
    if (!product.images || product.images.length === 0) return;

    // Imagen principal
    el.galleryMainImage.src = product.images[0].src;
    el.galleryMainImage.alt = product.images[0].alt;

    // Thumbnails
    el.galleryThumbsContainer.innerHTML = "";
    product.images.forEach(function (image, index) {
      var thumbButton = document.createElement("button");
      thumbButton.className = "gallery-thumb";
      thumbButton.type = "button";
      thumbButton.setAttribute("role", "tab");
      thumbButton.setAttribute("aria-selected", index === 0 ? "true" : "false");
      thumbButton.setAttribute("aria-label", "Ver imagen " + (index + 1));

      var thumbImg = document.createElement("img");
      thumbImg.src = image.src;
      thumbImg.alt = image.alt;

      thumbButton.appendChild(thumbImg);
      el.galleryThumbsContainer.appendChild(thumbButton);

      // Click handler
      thumbButton.addEventListener("click", function () {
        selectImage(index, thumbButton);
      });
    });

    // Badge provisional
    el.galleryProvisionalBadge.hidden = !product.provisional;
  }

  function selectImage(index, thumbButton) {
    if (!product.images || !product.images[index]) return;

    // Actualizar imagen principal
    el.galleryMainImage.src = product.images[index].src;
    el.galleryMainImage.alt = product.images[index].alt;

    // Actualizar ARIA
    var allThumbs = el.galleryThumbsContainer.querySelectorAll(".gallery-thumb");
    allThumbs.forEach(function (thumb) {
      thumb.setAttribute("aria-selected", "false");
    });
    thumbButton.setAttribute("aria-selected", "true");
  }

  // ---------- RENDERIZAR INFORMACIÓN ----------
  function renderInfo() {
    el.productTitle.textContent = product.name || "";
    el.productSku.textContent = (product.sku || "").toUpperCase();

    // Precio
    if (product.price) {
      el.productPrice.textContent = "$" + product.price.toLocaleString();
      el.productPrice.setAttribute("data-price", product.price);
    } else {
      el.productPrice.textContent = "Precio no disponible";
      el.productPrice.setAttribute("data-price", "null");
    }

    // Descripción
    el.productDescription.textContent = product.description || "";

    // Colección
    if (product.collection && product.collection.name) {
      el.productCollection.textContent = product.collection.name;
      el.breadcrumbCollection.textContent = product.collection.name;
      el.breadcrumbCollection.href = "index.html#coleccion";
    }

    // Migas de pan
    el.breadcrumbProduct.textContent = product.name || "Producto";

    // Aviso provisional
    el.productProvisionalNotice.hidden = !product.provisional;
  }

  // ---------- RENDERIZAR SELECTORES ----------
  function renderSelectors() {
    // Colores
    if (product.colors && product.colors.length > 1) {
      el.colorSelectorContainer.hidden = false;
      el.colorSelector.innerHTML = "";

      product.colors.forEach(function (color, index) {
        var label = document.createElement("label");
        label.className = "product-selector__option";

        var radio = document.createElement("input");
        radio.type = "radio";
        radio.name = "color";
        radio.value = color.name;
        radio.classList.add("product-selector__color");
        radio.style.backgroundColor = color.hex;
        radio.disabled = !color.available;
        radio.setAttribute("aria-label", color.name);

        if (index === 0) {
          radio.checked = true;
          state.selectedColor = color.name;
        }

        radio.addEventListener("change", function () {
          state.selectedColor = color.name;
        });

        label.appendChild(radio);
        el.colorSelector.appendChild(label);
      });
    } else {
      el.colorSelectorContainer.hidden = true;
    }

    // Tallas
    if (product.sizes && product.sizes.length > 0) {
      el.sizeSelector.innerHTML = "";

      product.sizes.forEach(function (size, index) {
        var label = document.createElement("label");
        label.className = "product-selector__option";

        var radio = document.createElement("input");
        radio.type = "radio";
        radio.name = "size";
        radio.value = size;
        radio.disabled = false; // Por ahora, todas disponibles
        radio.setAttribute("aria-label", "Talla " + size);

        if (index === 0) {
          radio.checked = true;
          state.selectedSize = size;
        }

        radio.addEventListener("change", function () {
          state.selectedSize = size;
        });

        var span = document.createElement("span");
        span.textContent = size;

        label.appendChild(radio);
        label.appendChild(span);
        el.sizeSelector.appendChild(label);
      });
    }
  }

  // ---------- ACTUALIZAR STOCK ----------
  function updateStockStatus() {
    if (product.stock === null) {
      el.stockStatus.textContent = "Stock no confirmado";
      el.stockStatus.className = "product-info__stock";
    } else if (product.stock > 0) {
      el.stockStatus.textContent = product.stock + " unidades disponibles";
      el.stockStatus.className = "product-info__stock in-stock";
    } else {
      el.stockStatus.textContent = "Producto agotado";
      el.stockStatus.className = "product-info__stock out-of-stock";
      el.addToCartBtn.disabled = true;
    }
  }

  // ---------- AGREGAR AL CARRITO ----------
  function addToCart() {
    if (state.isAdding || !state.selectedSize) return;

    state.isAdding = true;
    el.addToCartBtn.disabled = true;
    el.addToCartText.textContent = "Agregando...";

    // Simulación de proceso (en fase real se guardaría en BD/carrito)
    setTimeout(function () {
      var quantity = parseInt(el.quantityInput.value, 10) || 1;
      var cartItem = {
        productId: product.id,
        name: product.name,
        size: state.selectedSize,
        color: state.selectedColor,
        quantity: quantity,
        price: product.price,
        image: product.images[0].src,
      };

      // Guardar en localStorage (fase 1: sin servidor)
      var cart = JSON.parse(localStorage.getItem("hm-cart") || "[]");
      cart.push(cartItem);
      localStorage.setItem("hm-cart", JSON.stringify(cart));

      // Feedback
      el.addToCartMessage.textContent = quantity + " × " + product.name + " agregado al carrito.";
      el.addToCartFeedback.hidden = false;

      // Limpiar estado
      setTimeout(function () {
        state.isAdding = false;
        el.addToCartBtn.disabled = false;
        el.addToCartText.textContent = "Agregar al carrito";
        el.addToCartFeedback.hidden = true;
      }, 2000);
    }, 600);
  }

  // ---------- PRODUCTOS RELACIONADOS ----------
  function renderRelatedProducts() {
    if (!product.collection || !product.collection.slug) return;

    var related = window.HM_getProductsByCollection(product.collection.slug).filter(
      function (p) {
        return p.id !== product.id;
      }
    );

    if (related.length === 0) return;

    el.relatedProductsSection.hidden = false;
    var grid = document.getElementById("related-products-grid");
    grid.innerHTML = "";

    related.forEach(function (relatedProduct) {
      var card = document.createElement("div");
      card.className = "product-card";

      var link = document.createElement("a");
      link.href = "producto.html?id=" + relatedProduct.id;
      link.className = "product-card__link";

      var img = document.createElement("img");
      img.src = relatedProduct.images && relatedProduct.images[0] ? relatedProduct.images[0].src : "";
      img.alt = relatedProduct.name;
      img.className = "product-card__image";

      var name = document.createElement("h3");
      name.className = "product-card__name";
      name.textContent = relatedProduct.name;

      var price = document.createElement("span");
      price.className = "product-card__price";
      price.textContent = relatedProduct.price
        ? "$" + relatedProduct.price.toLocaleString()
        : "Precio por confirmar";

      link.appendChild(img);
      link.appendChild(name);
      link.appendChild(price);
      card.appendChild(link);
      grid.appendChild(card);
    });
  }

  // ---------- EVENT LISTENERS ----------
  el.addToCartBtn.addEventListener("click", addToCart);

  // Validar cantidad
  el.quantityInput.addEventListener("input", function () {
    var value = parseInt(this.value, 10);
    if (value < 1) this.value = 1;
    if (value > 10) this.value = 10;
  });

  // ---------- INICIALIZAR ----------
  renderGallery();
  renderInfo();
  renderSelectors();
  updateStockStatus();
  renderRelatedProducts();
})();
