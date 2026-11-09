/* HM Store — aparición suave al entrar en pantalla. Sin dependencias; sin JS o sin IntersectionObserver todo queda visible. */
(function () {
  "use strict";
  var nodes = document.querySelectorAll(".section-head, .notice, .reveal");
  nodes.forEach(function (n) { n.classList.add("reveal"); });
  if (!("IntersectionObserver" in window)) { nodes.forEach(function (n) { n.classList.add("in"); }); return; }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add("in"); io.unobserve(e.target); } });
  }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
  nodes.forEach(function (n) { io.observe(n); });
})();
