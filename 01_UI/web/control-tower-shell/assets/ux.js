(function () {
  "use strict";

  const UX = {
    routes: [
      ["control-tower", "Torre de Control HIA", "Vista global de HIA"],
      ["portfolio", "Portafolio", "Proyectos, IA y costos"],
      ["ai-control", "Control de IA", "IAs disponibles y costos"],
      ["cost-center", "Centro de Costos", "Costos globales/proyecto/IA"],
      ["project-overview", "Workspace", "Proyecto seleccionado"],
      ["project-ai-chat", "IA / Chat", "Chat IA por proyecto"],
      ["project-costs", "Costos del Proyecto", "Costos demo por proyecto"],
      ["project-evidence", "Evidencia", "BATON/RADAR/BACKLOG"],
      ["reports", "Informes", "Future feature"],
      ["collaboration", "Colaboración", "Future feature"],
      ["integrations", "Integraciones", "Future feature"],
      ["knowledge-vault", "Bóveda / Conocimiento", "Future feature"],
      ["settings", "Configuración Global", "Governance"]
    ],
    projectId: "PRJ_0001_HIA.PRODUCT",
    rootWsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    rootWin: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA"
  };

  function qs(selector) {
    return document.querySelector(selector);
  }

  function qsa(selector) {
    return Array.from(document.querySelectorAll(selector));
  }

  function currentRoute() {
    return window.location.hash.replace("#", "") || "control-tower";
  }

  function routeLabel(route) {
    const found = UX.routes.find((item) => item[0] === route);
    return found ? found[1] : route;
  }

  function toast(message, type) {
    let host = qs("#ux-toast-host");
    if (!host) {
      host = document.createElement("div");
      host.id = "ux-toast-host";
      host.className = "ux-toast-host";
      document.body.appendChild(host);
    }

    const item = document.createElement("div");
    item.className = "ux-toast " + (type || "info");
    item.textContent = message;
    host.appendChild(item);

    window.setTimeout(() => item.classList.add("is-visible"), 20);
    window.setTimeout(() => {
      item.classList.remove("is-visible");
      window.setTimeout(() => item.remove(), 260);
    }, 2800);
  }

  function copyText(text, label) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text)
        .then(() => toast((label || "Texto") + " copiado", "ok"))
        .catch(() => fallbackCopy(text, label));
      return;
    }

    fallbackCopy(text, label);
  }

  function fallbackCopy(text, label) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand("copy");
      toast((label || "Texto") + " copiado", "ok");
    } catch (error) {
      toast("No se pudo copiar", "bad");
    }
    textarea.remove();
  }

  function updateRouteIndicator() {
    const badge = qs("#ux-route-indicator");
    if (!badge) return;
    const route = currentRoute();
    badge.textContent = "Ruta activa · " + routeLabel(route);
  }

  function go(route) {
    window.location.hash = route;
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    toast("Vista: " + routeLabel(route), "info");
    closePalette();
    updateRouteIndicator();
  }

  function buildFloatingActions() {
    if (qs("#ux-floating-actions")) return;

    const root = document.createElement("div");
    root.id = "ux-floating-actions";
    root.className = "ux-floating-actions";
    root.innerHTML = `
      <button class="ux-fab main" id="ux-open-palette" title="Command Palette · Ctrl+K">⌘K</button>
      <button class="ux-fab" id="ux-copy-context" title="Copiar contexto">CTX</button>
      <button class="ux-fab" id="ux-copy-wsl" title="Copiar comando WSL">WSL</button>
    `;
    document.body.appendChild(root);

    qs("#ux-open-palette").addEventListener("click", openPalette);
    qs("#ux-copy-context").addEventListener("click", copyContext);
    qs("#ux-copy-wsl").addEventListener("click", copyWslCommand);
  }

  function buildRouteIndicator() {
    const topbar = qs(".topbar");
    if (!topbar || qs("#ux-route-indicator")) return;

    const indicator = document.createElement("div");
    indicator.id = "ux-route-indicator";
    indicator.className = "ux-route-indicator";
    indicator.textContent = "Ruta activa · " + routeLabel(currentRoute());
    topbar.appendChild(indicator);
  }

  function buildPalette() {
    if (qs("#ux-palette")) return;

    const overlay = document.createElement("div");
    overlay.id = "ux-palette";
    overlay.className = "ux-palette";
    overlay.setAttribute("aria-hidden", "true");

    overlay.innerHTML = `
      <div class="ux-palette-panel">
        <div class="ux-palette-head">
          <div>
            <strong>Command Palette</strong>
            <span>Busca vistas, copia contexto o navega rápido.</span>
          </div>
          <button class="ux-icon-btn" id="ux-close-palette">×</button>
        </div>
        <input id="ux-palette-search" class="ux-palette-search" placeholder="Buscar: portfolio, IA, costos, evidencia..." autocomplete="off">
        <div id="ux-palette-results" class="ux-palette-results"></div>
        <div class="ux-palette-footer">
          <span>Enter: abrir</span>
          <span>Esc: cerrar</span>
          <span>Ctrl+K: abrir</span>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    qs("#ux-close-palette").addEventListener("click", closePalette);
    qs("#ux-palette-search").addEventListener("input", renderPaletteResults);
    qs("#ux-palette-search").addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        const first = qs(".ux-result");
        if (first) go(first.dataset.route);
      }
      if (event.key === "Escape") closePalette();
    });

    overlay.addEventListener("click", (event) => {
      if (event.target === overlay) closePalette();
    });

    renderPaletteResults();
  }

  function renderPaletteResults() {
    const input = qs("#ux-palette-search");
    const results = qs("#ux-palette-results");
    if (!input || !results) return;

    const query = input.value.trim().toLowerCase();
    const matches = UX.routes.filter((item) => {
      return !query || item.join(" ").toLowerCase().includes(query);
    });

    results.innerHTML = matches.map((item) => `
      <button class="ux-result" data-route="${item[0]}">
        <strong>${item[1]}</strong>
        <span>${item[2]}</span>
      </button>
    `).join("");

    qsa(".ux-result").forEach((button) => {
      button.addEventListener("click", () => go(button.dataset.route));
    });
  }

  function openPalette() {
    buildPalette();
    const overlay = qs("#ux-palette");
    const input = qs("#ux-palette-search");
    overlay.classList.add("is-open");
    overlay.setAttribute("aria-hidden", "false");
    input.value = "";
    renderPaletteResults();
    window.setTimeout(() => input.focus(), 30);
  }

  function closePalette() {
    const overlay = qs("#ux-palette");
    if (!overlay) return;
    overlay.classList.remove("is-open");
    overlay.setAttribute("aria-hidden", "true");
  }

  function copyContext() {
    const payload = [
      "HIA UX CONTEXT",
      "Route: " + currentRoute(),
      "Route label: " + routeLabel(currentRoute()),
      "Project: " + UX.projectId,
      "Root WSL: " + UX.rootWsl,
      "Root Windows: " + UX.rootWin,
      "Note: Demo seed is non-operational unless backed by real source."
    ].join("\n");

    copyText(payload, "Contexto HIA");
  }

  function copyWslCommand() {
    const command = [
      'cd "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA"',
      './01_UI/terminal/hia.ps1 project status PRJ_0001_HIA.PRODUCT'
    ].join("\n");

    copyText(command, "Comando WSL");
  }

  function enhanceCopyButtons() {
    if (qs("#ux-context-bar")) return;

    const root = qs("#view-root");
    if (!root) return;

    const bar = document.createElement("div");
    bar.id = "ux-context-bar";
    bar.className = "ux-context-bar";
    bar.innerHTML = `
      <button class="secondary-btn" id="ux-action-copy-context">Copiar contexto</button>
      <button class="secondary-btn" id="ux-action-copy-route">Copiar ruta</button>
      <button class="secondary-btn" id="ux-action-copy-wsl">Copiar WSL2</button>
    `;

    root.prepend(bar);

    qs("#ux-action-copy-context").addEventListener("click", copyContext);
    qs("#ux-action-copy-route").addEventListener("click", () => copyText(currentRoute(), "Ruta"));
    qs("#ux-action-copy-wsl").addEventListener("click", copyWslCommand);
  }

  function afterRouteRender() {
    updateRouteIndicator();
    window.setTimeout(enhanceCopyButtons, 30);
  }

  function installKeyboardShortcuts() {
    document.addEventListener("keydown", (event) => {
      const key = event.key.toLowerCase();

      if ((event.ctrlKey || event.metaKey) && key === "k") {
        event.preventDefault();
        openPalette();
        return;
      }

      if (event.key === "Escape") {
        closePalette();
        return;
      }

      if (event.altKey && key === "1") go("control-tower");
      if (event.altKey && key === "2") go("portfolio");
      if (event.altKey && key === "3") go("ai-control");
      if (event.altKey && key === "4") go("cost-center");
      if (event.altKey && key === "5") go("project-overview");
    });
  }

  function observeRouteChanges() {
    window.addEventListener("hashchange", afterRouteRender);

    const root = qs("#view-root");
    if (!root) return;

    const observer = new MutationObserver(() => {
      afterRouteRender();
    });

    observer.observe(root, { childList: true, subtree: false });
  }

  function init() {
    buildFloatingActions();
    buildPalette();
    buildRouteIndicator();
    installKeyboardShortcuts();
    observeRouteChanges();
    afterRouteRender();
    toast("UX interaction layer activo", "ok");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
