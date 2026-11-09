/* HM Store — Hero Experience (Fase 3: Full Background). Sin dependencias.
 * Lee window.HM_DATA (data/campaigns.js). Todo el texto se inserta con
 * textContent; nunca se inyecta HTML desde los datos. */
(function () {
  "use strict";

  var data = window.HM_DATA;
  var root = document.documentElement;
  var hero = document.getElementById("hero");
  if (!data || !data.featured || !hero) {
    console.error("[HM Hero] Falta window.HM_DATA.featured o el contenedor #hero.");
    return;
  }

  var el = {
    title: document.getElementById("hero-title-text"),
    desc: document.getElementById("hero-desc"),
    cta: document.getElementById("hero-cta"),
    ctaText: document.getElementById("hero-cta-text"),
    bgImg: document.getElementById("hero-bg-img"),
    badge: document.getElementById("hero-badge"),
    announce: document.getElementById("announce"),
    announceLink: document.getElementById("announce-link"),
    announceTrack: document.getElementById("announce-track"),
    announceText: document.getElementById("announce-text"),
  };

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  var current = null;
  var busy = false;

  /* Devuelve un destino seguro o null. Solo rutas relativas, anclas o http(s);
   * evita esquemas como javascript:. Un ancla (#x) solo es válida si existe en la página. */
  function safeHref(href) {
    if (typeof href !== "string" || !href) return null;
    if (href.charAt(0) === "#") {
      return href.length > 1 && document.getElementById(href.slice(1)) ? href : null;
    }
    if (/^(\/|\.\/|\.\.\/)/.test(href) || /^https?:\/\//i.test(href)) return href;
    return /^[\w\-./]+$/.test(href) ? href : null;
  }

  /* Un enlace sin destino válido NO se enlaza a ningún sitio: queda como botón
   * deshabilitado (aria-disabled) hasta que HM defina el destino real. */
  function setLink(a, href) {
    var ok = safeHref(href);
    if (ok) {
      a.setAttribute("href", ok);
      a.removeAttribute("aria-disabled");
    } else {
      a.removeAttribute("href");
      a.setAttribute("aria-disabled", "true");
    }
  }

  function applyTheme(theme) {
    var s = root.style;
    if (!theme) return;
    if (theme.bg) s.setProperty("--bg", theme.bg);
    if (theme.ink) s.setProperty("--ink", theme.ink);
    if (theme.accent) s.setProperty("--accent", theme.accent);
  }

  /* Renderiza la imagen de fondo de campaña */
  function applyBackgroundImage(image, provisional) {
    var hasImage = image && image.src;

    el.bgImg.onerror = function () {
      // Si la foto no carga, mostrar badge
      el.bgImg.hidden = true;
      el.badge.hidden = false;
    };

    if (hasImage) {
      el.bgImg.alt = image.alt || "";
      el.bgImg.src = image.src;
      el.bgImg.hidden = false;
    } else {
      el.bgImg.removeAttribute("src");
      el.bgImg.hidden = true;
    }

    // Mostrar badge mientras sea provisional o falte la imagen
    el.badge.hidden = !(provisional || !hasImage);
  }

  /* Titular por líneas: cada palabra va en su máscara (sin innerHTML). Tras el layout se
   * agrupan por línea (offsetTop) y cada línea recibe su retardo --line. */
  function setTitle(text) {
    el.title.textContent = "";
    text.split(/\s+/).filter(Boolean).forEach(function (word, i, all) {
      var w = document.createElement("span");
      w.className = "w";
      var inner = document.createElement("i");
      inner.textContent = word;
      w.appendChild(inner);
      el.title.appendChild(w);
      if (i < all.length - 1) el.title.appendChild(document.createTextNode(" "));
    });
    var words = el.title.querySelectorAll(".w");
    var line = -1, lastTop = null;
    for (var k = 0; k < words.length; k++) {
      var top = words[k].offsetTop;
      if (lastTop === null || Math.abs(top - lastTop) > 4) { line++; lastTop = top; }
      words[k].style.setProperty("--line", line);
    }
  }

  function fill(c) {
    setTitle(c.title || "");
    el.desc.textContent = c.description || "";
    el.desc.hidden = !c.description;
    el.ctaText.textContent = (c.cta && c.cta.label) || "";
    setLink(el.cta, c.cta && c.cta.href);
    el.cta.hidden = !(c.cta && c.cta.label);
    applyTheme(c.theme);
    applyBackgroundImage(c.backgroundImage, c.provisional);
    current = c;
  }

  function afterAnimation(node, done, fallbackMs) {
    var finished = false;
    function end() { if (finished) return; finished = true; done(); }
    node.addEventListener("transitionend", end, { once: true });
    setTimeout(end, fallbackMs);
  }

  /* Cambio de colección: salida breve del contenido anterior y entrada del nuevo. */
  function setCampaign(next) {
    if (!next || busy) return;
    if (!current || reduceMotion.matches && !hero.classList.contains("is-ready")) {
      fill(next);
      return;
    }
    busy = true;
    hero.classList.add("is-leaving");
    afterAnimation(hero.querySelector(".hero__content"), function () {
      fill(next);
      hero.classList.remove("is-leaving");
      hero.classList.add("is-entering");
      setTimeout(function () {
        hero.classList.remove("is-entering");
        busy = false;
      }, 600);
    }, reduceMotion.matches ? 180 : 260);
  }

  /* ---------- Cinta de anuncio ---------- */
  function setAnnouncement(a) {
    var on = a && a.enabled && a.message;
    el.announce.hidden = !on;
    root.style.setProperty("--announce-h", on ? el.announce.offsetHeight + "px" : "0px");
    if (!on) { el.announceTrack.textContent = ""; return; }

    setLink(el.announceLink, a.href);
    el.announceText.textContent = a.message;

    // Dos grupos idénticos para un bucle continuo; cada grupo se repite hasta cubrir el ancho.
    el.announceTrack.textContent = "";
    function group() {
      var g = document.createElement("span");
      g.className = "announce__group";
      g.style.display = "inline-flex";
      for (var i = 0; i < 4; i++) {
        var it = document.createElement("span");
        it.className = "announce__item";
        it.textContent = a.message;
        g.appendChild(it);
      }
      return g;
    }
    el.announceTrack.appendChild(group());
    el.announceTrack.appendChild(group());

    var half = el.announceTrack.scrollWidth / 2;
    var pxPerSecond = 45; // velocidad moderada y legible
    el.announceTrack.style.setProperty("--marquee-duration", Math.max(15, half / pxPerSecond) + "s");
    root.style.setProperty("--announce-h", el.announce.offsetHeight + "px");
  }

  /* ---------- Parallax discreto del fondo (solo puntero fino, escritorio) ---------- */
  function initParallax() {
    var fine = window.matchMedia("(pointer: fine) and (min-width: 1025px)");
    var shapes = hero.querySelectorAll(".hero__shape");
    var raf = 0, tx = 0, ty = 0;
    function frame() {
      raf = 0;
      shapes[0].style.transform = "translate3d(" + tx * -10 + "px," + ty * -8 + "px,0)";
      if (shapes[1]) shapes[1].style.transform = "translate3d(" + tx * 14 + "px," + ty * 10 + "px,0)";
    }
    hero.addEventListener("pointermove", function (e) {
      if (!fine.matches || reduceMotion.matches) return;
      var r = hero.getBoundingClientRect();
      tx = (e.clientX - r.left) / r.width - 0.5;
      ty = (e.clientY - r.top) / r.height - 0.5;
      if (!raf) raf = requestAnimationFrame(frame);
    }, { passive: true });
  }

  /* ---------- Arranque ---------- */
  fill(data.featured);
  setAnnouncement(data.announcement);
  initParallax();

  function start() {
    // Se espera a la imagen (máx. 1,5s) para que la entrada sea fluida.
    requestAnimationFrame(function () { hero.classList.add("is-ready"); });
  }

  // Esperar a que la imagen de fondo cargue
  if (!el.bgImg.hidden && !el.bgImg.complete) {
    var started = false;
    var go = function () { if (!started) { started = true; start(); } };
    el.bgImg.addEventListener("load", go, { once: true });
    el.bgImg.addEventListener("error", go, { once: true });
    setTimeout(go, 1500);
  } else {
    start();
  }

  window.HMHero = { setCampaign: setCampaign, setAnnouncement: setAnnouncement };
})();
