/* HM Store — comportamiento de componentes (Fase 2). Sin dependencias. */
(function () {
  "use strict";

  /* Control de cantidad: mínimo 1, máximo data-max (límite de stock real cuando exista). */
  document.querySelectorAll("[data-qty]").forEach(function (box) {
    var val = box.querySelector(".qty__val");
    var dec = box.querySelector("[data-dec]");
    var inc = box.querySelector("[data-inc]");
    var max = parseInt(box.getAttribute("data-max") || "99", 10);
    var n = Math.min(Math.max(parseInt(val.textContent, 10) || 1, 1), max);
    function render() {
      val.textContent = n;
      dec.disabled = n <= 1;
      inc.disabled = n >= max;
    }
    dec.addEventListener("click", function () { if (n > 1) { n--; render(); } });
    inc.addEventListener("click", function () { if (n < max) { n++; render(); } });
    render();
  });

  /* Selectores: pintan el color de data-color y muestran la opción elegida en la leyenda. */
  document.querySelectorAll("[data-color]").forEach(function (n) { n.style.setProperty("--c", n.getAttribute("data-color")); });
  document.querySelectorAll("[data-field]").forEach(function (f) {
    var out = f.querySelector("output");
    if (!out) return;
    function sync() {
      var c = f.querySelector("input:checked");
      out.textContent = c ? c.getAttribute("data-label") || c.value : "";
    }
    f.addEventListener("change", sync);
    sync();
  });
})();
