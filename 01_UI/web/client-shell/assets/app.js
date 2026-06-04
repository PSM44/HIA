(function () {
  "use strict";

  const STATE = {
    projectId: "PRJ_0001_HIA.PRODUCT",
    shellVersion: "v0.1",
    currentFocus: "Crear front-end app shell navegable para demo cliente.",
    nextActionHuman: "Conectar estado real CLI/BATON/RADAR a la interfaz.",
    nextActionCode: "PRJPB_009K",
    repoStatus: "Limpio",
    evidenceStatus: "Disponible",
    architecture: "HTML/CSS/JS sin build, PWA-ready, migrable a Vite/React/Next.",
    debts: [
      {
        id: "TD_FRONTEND_DYNAMIC_STATE/P0",
        title: "Estado real aún vive en CLI",
        detail: "La UI ya puede mostrar un panel de estado, pero todavía falta conectarlo a una fuente generada desde CLI/BATON/RADAR."
      },
      {
        id: "TD_CLI_ENCODING_MOJIBAKE/P1",
        title: "Mojibake CLI",
        detail: "La consola aún puede mostrar caracteres corruptos en palabras con tilde."
      },
      {
        id: "TD_AI_MEMORY_STATUS/P2",
        title: "AI_MEMORY missing",
        detail: "No bloquea la demo, pero afecta continuidad avanzada."
      }
    ]
  };

  const ROUTES = {
    "client-summary": {
      title: "Resumen para Cliente",
      subtitle: "Qué es HIA, por qué existe y qué valor entrega.",
      render: renderClientSummary
    },
    "guided-demo": {
      title: "Demo guiada",
      subtitle: "Flujo paso a paso para abrir, revisar y validar la demo.",
      render: renderGuidedDemo
    },
    "active-project": {
      title: "Proyecto activo",
      subtitle: "Qué se está construyendo ahora y qué viene después.",
      render: renderActiveProject
    },
    "real-status": {
      title: "Estado real",
      subtitle: "Panel preparado para mostrar estado vivo desde CLI/BATON/RADAR.",
      render: renderRealStatus
    },
    "evidence": {
      title: "Evidencia",
      subtitle: "Qué prueba que el estado mostrado tiene respaldo.",
      render: renderEvidence
    },
    "tech-debt": {
      title: "Deuda técnica",
      subtitle: "Problemas conocidos, no ocultos.",
      render: renderTechDebt
    },
    "support": {
      title: "Comandos / Soporte",
      subtitle: "Comandos WSL2 Bash explicados por propósito y orden.",
      render: renderSupport
    }
  };

  function html(strings, ...values) {
    return strings.reduce((acc, str, index) => acc + str + (values[index] ?? ""), "");
  }

  function renderClientSummary() {
    return html`
      <div class="ribbon client">CLIENTE — Resumen ejecutivo navegable</div>
      <section class="card hero">
        <h2>Qué es HIA</h2>
        <p><b>HIA es una capa operativa para trabajar con IA sin perder control.</b> Ordena decisiones humanas, ejecución técnica, evidencia, validación y continuidad. Permite avanzar proyectos con IA sin depender de memoria de chat ni comandos improvisados.</p>
      </section>

      <div class="grid cols-3" style="margin-top:16px">
        <section class="card">
          <div class="label">Estado</div>
          <div class="metric warn">App shell</div>
          <p>Ya no estamos mirando un reporte estático: ahora probamos una interfaz navegable.</p>
        </section>
        <section class="card">
          <div class="label">Repositorio</div>
          <div class="metric ok">${STATE.repoStatus}</div>
          <p>Los últimos cambios están guardados y enviados a Git.</p>
        </section>
        <section class="card">
          <div class="label">Arquitectura</div>
          <div class="metric ok">PWA-ready</div>
          <p>${STATE.architecture}</p>
        </section>
      </div>
    `;
  }

  function renderGuidedDemo() {
    return html`
      <div class="ribbon client">CLIENTE — Flujo guiado</div>
      <section class="card">
        <h2>Flujo de demo</h2>
        <div class="stepper">
          <div class="step current">
            <div class="label">Paso 1</div>
            <h3>Entiende HIA</h3>
            <p>Lee el resumen para cliente. Debe quedar claro qué problema resuelve.</p>
          </div>
          <div class="step next">
            <div class="label">Paso 2</div>
            <h3>Abre demo</h3>
            <p>Usa el comando WSL2 Bash para abrir la demo visual.</p>
          </div>
          <div class="step later">
            <div class="label">Paso 3</div>
            <h3>Valida evidencia</h3>
            <p>Revisa estado, evidencia y deuda visible antes de presentar.</p>
          </div>
        </div>
      </section>

      <div class="ribbon qa">QA — Checklist interactivo</div>
      <section class="card">
        <h2>Smoke como cliente</h2>
        <div class="checklist">
          ${[
            "Entiendo qué es HIA en menos de 60 segundos.",
            "Entiendo qué está pasando ahora.",
            "Sé qué comando ejecutar primero.",
            "Entiendo para qué sirve cada comando.",
            "Puedo distinguir cliente, dev, QA, evidencia y deuda.",
            "No veo basura técnica bloqueante en la portada."
          ].map((item, index) => `<label class="check-item"><input type="checkbox" data-check="${index}"><span>${item}</span></label>`).join("")}
        </div>
      </section>
    `;
  }

  function renderActiveProject() {
    return html`
      <div class="ribbon client">CLIENTE — Proyecto activo</div>
      <section class="card">
        <h2>Qué estamos construyendo ahora</h2>
        <p>${STATE.currentFocus}</p>
        <div class="grid cols-2" style="margin-top:16px">
          <div class="step current">
            <div class="label">Ahora</div>
            <h3>App shell navegable</h3>
            <p>Crear una interfaz donde se pueda navegar y testear como cliente.</p>
          </div>
          <div class="step next">
            <div class="label">Siguiente</div>
            <h3>${STATE.nextActionHuman}</h3>
            <p>Código interno: ${STATE.nextActionCode}.</p>
          </div>
        </div>
      </section>
    `;
  }

  function renderRealStatus() {
    return html`
      <div class="ribbon dev">DEV UX/UI — Estado visible en UI</div>
      <section class="card">
        <h2>Estado real del proyecto</h2>
        <p>Hoy este estado todavía viene desde CLI. Esta pantalla deja preparada la ubicación visual para conectarlo después a un generador de estado real.</p>
        <table class="table" style="margin-top:14px">
          <thead><tr><th>Campo</th><th>Estado mostrado</th><th>Fuente futura</th></tr></thead>
          <tbody>
            <tr><td>Proyecto</td><td>${STATE.projectId}</td><td>PROJECT.CONFIG / CLI</td></tr>
            <tr><td>Repo</td><td>${STATE.repoStatus}</td><td>git status</td></tr>
            <tr><td>Evidencia</td><td>${STATE.evidenceStatus}</td><td>project continue / resolver</td></tr>
            <tr><td>Trabajo actual</td><td>${STATE.currentFocus}</td><td>BATON NEXT_ACTION</td></tr>
            <tr><td>Siguiente</td><td>${STATE.nextActionHuman}</td><td>BATON / BACKLOG</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderEvidence() {
    return html`
      <div class="ribbon evidence">EVIDENCE / AUDIT — Respaldo</div>
      <section class="card">
        <h2>Evidencia disponible</h2>
        <p>El objetivo no es llenar la portada de logs. Es mostrar que existe respaldo y dejar el detalle donde corresponde.</p>
        <div class="grid cols-3" style="margin-top:16px">
          <div class="step"><h3>Git</h3><p>Commits y push respaldan cambios.</p></div>
          <div class="step"><h3>RADAR</h3><p>Inventario y freshness de archivos.</p></div>
          <div class="step"><h3>Artifacts</h3><p>Reportes de MiniBattles y feedback humano.</p></div>
        </div>
      </section>
    `;
  }

  function renderTechDebt() {
    return html`
      <div class="ribbon debt">TECH DEBT — Problemas conocidos</div>
      <section class="card">
        <h2>Deuda visible</h2>
        <div class="grid cols-3">
          ${STATE.debts.map((debt) => `
            <div class="step">
              <div class="label">${debt.id}</div>
              <h3>${debt.title}</h3>
              <p>${debt.detail}</p>
            </div>
          `).join("")}
        </div>
      </section>
    `;
  }

  function renderSupport() {
    const step1 = `cd "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA\\01_UI\\launcher\\HIA.CLIENT.DEMO.SHELL.LAUNCHER.ps1"`;

    const step2 = `cd "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location 'C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA'; .\\01_UI\\terminal\\hia.ps1 project continue PRJ_0001_HIA.PRODUCT"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location 'C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA'; .\\01_UI\\terminal\\hia.ps1 project status PRJ_0001_HIA.PRODUCT"`;

    return html`
      <div class="ribbon dev">DEV UX/UI — Soporte de ejecución</div>
      <section class="grid cols-2">
        <div class="card">
          <h2>PASO 1 — Abrir app shell</h2>
          <p>Usa este comando primero. Abre la interfaz navegable de cliente.</p>
          <div class="cmd" id="cmd-step1">${step1}</div>
          <div class="action-row">
            <button class="primary-btn" data-copy="cmd-step1">Copiar PASO 1</button>
          </div>
        </div>
        <div class="card">
          <h2>PASO 2 — Ver estado real en CLI</h2>
          <p>Usa este comando después. Temporalmente el estado real aún se consulta por CLI; luego se conectará a la UI.</p>
          <div class="cmd" id="cmd-step2">${step2}</div>
          <div class="action-row">
            <button class="primary-btn" data-copy="cmd-step2">Copiar PASO 2</button>
          </div>
        </div>
      </section>
    `;
  }

  function setRoute(routeName) {
    const route = ROUTES[routeName] || ROUTES["client-summary"];
    document.getElementById("view-title").textContent = route.title;
    document.getElementById("view-subtitle").textContent = route.subtitle;
    document.getElementById("view-root").innerHTML = route.render();

    document.querySelectorAll(".nav-item").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.route === routeName);
    });

    window.location.hash = routeName;
  }

  function showToast(message) {
    let toast = document.querySelector(".toast");
    if (!toast) {
      toast = document.createElement("div");
      toast.className = "toast";
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add("show");
    setTimeout(() => toast.classList.remove("show"), 1800);
  }

  function copyById(id) {
    const node = document.getElementById(id);
    if (!node) return;
    const text = node.innerText;
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(() => showToast("Comando copiado."));
    } else {
      const area = document.createElement("textarea");
      area.value = text;
      document.body.appendChild(area);
      area.select();
      document.execCommand("copy");
      document.body.removeChild(area);
      showToast("Comando copiado.");
    }
  }

  document.addEventListener("click", (event) => {
    const navButton = event.target.closest("[data-route]");
    if (navButton) {
      setRoute(navButton.dataset.route);
      return;
    }

    const copyButton = event.target.closest("[data-copy]");
    if (copyButton) {
      copyById(copyButton.dataset.copy);
    }
  });

  window.addEventListener("hashchange", () => {
    setRoute(window.location.hash.replace("#", "") || "client-summary");
  });

  setRoute(window.location.hash.replace("#", "") || "client-summary");
})();
