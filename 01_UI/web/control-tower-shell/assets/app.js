(function () {
  "use strict";

  let portfolioViewMode = "cards";

  const runtimeState = window.HIA_STATE || {};

  const STATE = {
    selectedProjectId: "PRJ_0001_HIA.PRODUCT",
    lastProjectId: "PRJ_0001_HIA.PRODUCT",
    generatedAt: runtimeState.generatedAt || "Demo seed / pendiente conexión real",
    git: {
      branch: (runtimeState.git && runtimeState.git.branch) || "Demo seed / pendiente conexión real",
      head: (runtimeState.git && runtimeState.git.head) || "Demo seed / pendiente conexión real",
      status: (runtimeState.git && runtimeState.git.status) || "Demo seed / pendiente conexión real"
    },
    global: {
      totalProjects: 3,
      activeProjects: 1,
      blockedProjects: 0,
      humanDecisions: 1,
      availableAIs: 4,
      demoMonthlyCost: "USD 108 demo",
      demoTokens: "1.57M demo"
    },
    aiProviders: [
      {
        id: "chatgpt",
        name: "ChatGPT",
        modality: "Web / Plan / API",
        status: "Demo: disponible",
        connection: "Demo: health check pendiente",
        generalCost: "USD 25/mes demo",
        privacyRisk: "Medio: web",
        recommendedFor: "Planificación, análisis, governance, redacción",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"],
        modeCosts: [
          ["Web plan", "USD 25/mes demo"],
          ["API", "USD 0.01–0.08/1K tokens demo"],
          ["Desktop", "Incluido en plan demo"],
          ["Proyecto actual", "USD 18/mes demo"]
        ]
      },
      {
        id: "codex",
        name: "Codex",
        modality: "Desktop / Coding / Repo",
        status: "Demo: disponible",
        connection: "Demo: health check pendiente",
        generalCost: "Incluido / pendiente modelo real",
        privacyRisk: "Medio: repo/code context",
        recommendedFor: "Código, refactor, repo operations",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"],
        modeCosts: [
          ["Desktop", "Incluido demo"],
          ["API", "Pendiente demo"],
          ["Repo ops", "USD 12/sesión demo"],
          ["Proyecto actual", "USD 42/mes demo"]
        ]
      },
      {
        id: "claude",
        name: "Claude",
        modality: "Web / API / posible CLI",
        status: "Demo: candidato",
        connection: "Demo: no testeado",
        generalCost: "USD 20/mes demo",
        privacyRisk: "Medio: web",
        recommendedFor: "UX critique, documentos largos, razonamiento narrativo",
        assignedProjects: ["PRJ_TEMPLATE_CLIENT"],
        modeCosts: [
          ["Web plan", "USD 20/mes demo"],
          ["API", "USD 0.01–0.09/1K tokens demo"],
          ["CLI", "Pendiente demo"],
          ["Proyecto actual", "USD 0 demo"]
        ]
      },
      {
        id: "local-llm",
        name: "Local LLM",
        modality: "Local / Offline",
        status: "Demo: future integration",
        connection: "Demo: no conectado",
        generalCost: "Costo marginal bajo demo",
        privacyRisk: "Bajo si es local",
        recommendedFor: "Privacidad, bajo costo variable, offline",
        assignedProjects: ["PRJ_REPORTING_LAYER"],
        modeCosts: [
          ["Ollama/local", "USD 0 API demo"],
          ["Hardware", "Costo hundido demo"],
          ["Electricidad", "USD 3/mes demo"],
          ["Proyecto actual", "USD 0 demo"]
        ]
      }
    ],
    projects: [
      {
        id: "PRJ_0001_HIA.PRODUCT",
        name: "HIA Product",
        status: "active",
        statusLabel: "Activo",
        owner: "Human + System",
        purpose: "Construir HIA como plataforma multi-proyecto con continuidad, trazabilidad, control, costos e IA colaborativa.",
        nextAction: "Conectar hia.state.js fino a HIA Control Tower Shell v0.2.",
        aiAssigned: "ChatGPT + Codex",
        aiMode: "Web + Desktop/CLI",
        aiConnection: "Demo: health check pendiente",
        cost: "USD 72/mes demo",
        tokens: "1.2M tokens/mes demo",
        budget: "USD 150/mes demo",
        evidence: "FRESH según CLI",
        risk: "UI/arquitectura en estabilización",
        lastActivity: "Sesión actual"
      },
      {
        id: "PRJ_TEMPLATE_CLIENT",
        name: "Cliente / Proyecto futuro",
        status: "backlog",
        statusLabel: "Backlog",
        owner: "Por definir",
        purpose: "Placeholder controlado para validar navegación multi-proyecto.",
        nextAction: "Alta formal futura.",
        aiAssigned: "Claude demo",
        aiMode: "Web / API",
        aiConnection: "Demo: no testeado",
        cost: "USD 25/mes demo",
        tokens: "280K tokens/mes demo",
        budget: "USD 80/mes demo",
        evidence: "N/A",
        risk: "No iniciado",
        lastActivity: "N/A"
      },
      {
        id: "PRJ_REPORTING_LAYER",
        name: "Reporting Layer",
        status: "backlog",
        statusLabel: "Future feature",
        owner: "Por definir",
        purpose: "Reportes ejecutivos, operativos, técnicos y exportables.",
        nextAction: "Diseñar modelo de reportes.",
        aiAssigned: "Local LLM demo",
        aiMode: "Local / Offline",
        aiConnection: "Demo: no conectado",
        cost: "USD 8/mes demo",
        tokens: "90K tokens/mes demo",
        budget: "USD 30/mes demo",
        evidence: "N/A",
        risk: "Feature futura",
        lastActivity: "N/A"
      }
    ]
  };

  const ROUTES = {
    "control-tower": {
      layer: "HIA GLOBAL",
      title: "Torre de Control HIA",
      subtitle: "Vista ejecutiva global: portfolio, IAs, costos, alertas y continuidad.",
      render: renderControlTower
    },
    "portfolio": {
      layer: "HIA GLOBAL",
      title: "Portafolio",
      subtitle: "Vista multi-proyecto: estado, IA asignada, costos y próxima acción.",
      render: renderPortfolio
    },
    "ai-control": {
      layer: "HIA GLOBAL",
      title: "Control de IA",
      subtitle: "IAs disponibles, estado, modalidad, costo general y costo por modalidad.",
      render: renderAIControl
    },
    "cost-center": {
      layer: "HIA GLOBAL",
      title: "Centro de Costos",
      subtitle: "Costos globales, por IA, por proyecto y por sesión. Demo seed no operacional.",
      render: renderCostCenter
    },
    "project-overview": {
      layer: "PROJECT WORKSPACE",
      title: "Workspace / Vista General",
      subtitle: "KPIs, estado, riesgos y próxima acción del proyecto seleccionado.",
      render: renderProjectOverview
    },
    "project-ai-chat": {
      layer: "PROJECT WORKSPACE",
      title: "IA / Chat del Proyecto",
      subtitle: "IA asignada y chat IA por proyecto. Backend pendiente.",
      render: renderProjectAIChat
    },
    "project-costs": {
      layer: "PROJECT WORKSPACE",
      title: "Costos del Proyecto",
      subtitle: "Presupuesto, tokens, modalidad IA y costos del proyecto.",
      render: renderProjectCosts
    },
    "project-evidence": {
      layer: "PROJECT WORKSPACE",
      title: "Evidencia del Proyecto",
      subtitle: "BATON, RADAR, BACKLOG, artifacts y decisiones humanas.",
      render: renderProjectEvidence
    },
    "reports": {
      layer: "ENTERPRISE",
      title: "Informes",
      subtitle: "Reportabilidad futura.",
      render: () => renderFuture("Informes", "Reportes ejecutivos, operativos, técnicos, PDF/PPT/HTML.")
    },
    "collaboration": {
      layer: "ENTERPRISE",
      title: "Colaboración",
      subtitle: "Roles, comentarios, asignaciones y aprobaciones.",
      render: () => renderFuture("Colaboración", "Feature futura para trabajo multiusuario y decisiones trazables.")
    },
    "integrations": {
      layer: "ENTERPRISE",
      title: "Integraciones",
      subtitle: "GitHub, Drive/OneDrive, Jira/Trello/Planner, Slack/Teams, Calendar, Email y APIs.",
      render: () => renderFuture("Integraciones", "Feature futura. No declarar conectores como reales sin implementación.")
    },
    "knowledge-vault": {
      layer: "ENTERPRISE",
      title: "Bóveda / Conocimiento",
      subtitle: "Obsidian o similar como integración futura P1/P2.",
      render: renderKnowledgeVault
    },
    "settings": {
      layer: "GOVERNANCE",
      title: "Configuración Global",
      subtitle: "Settings globales, políticas IA, privacidad, seguridad y deuda técnica.",
      render: renderSettings
    }
  };

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function project() {
    return STATE.projects.find((item) => item.id === STATE.selectedProjectId) || STATE.projects[0];
  }

  function statusClass(status) {
    if (status === "active") return "active";
    if (status === "blocked") return "blocked";
    return "backlog";
  }

  function providerClass(modality) {
    return modality.toLowerCase().includes("local") ? "local" : "web";
  }

  function demoRibbon() {
    return `
      <div class="demo-ribbon">
        <div>
          <strong>Demo seed / no operacional</strong>
          <span>Los números permiten validar layout. No son costos reales ni health checks reales.</span>
        </div>
        <span>Fuente: seed UX PRJPB_009M-C-R</span>
      </div>
    `;
  }

  function renderControlTower() {
    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>Entrada global de HIA</h2>
        <p><b>HIA es una plataforma de desarrollo, continuidad, trazabilidad y control de proyectos.</b> Reduce dispersión operativa y coordina trabajo colaborativo entre humanos e IAs.</p>
      </section>

      <section class="kpi-strip">
        <div class="card"><div class="label">Proyectos visibles</div><div class="metric">${STATE.global.totalProjects}</div><p>Incluye placeholders controlados.</p></div>
        <div class="card"><div class="label">Proyectos activos</div><div class="metric ok">${STATE.global.activeProjects}</div><p>Trabajo operativo actual.</p></div>
        <div class="card"><div class="label">IAs disponibles</div><div class="metric info">${STATE.global.availableAIs}</div><p>No implica conexión testeada.</p></div>
        <div class="card"><div class="label">Costo global demo</div><div class="metric warn">${STATE.global.demoMonthlyCost}</div><p>No operacional.</p></div>
      </section>

      <section class="grid two-one" style="margin-top:16px">
        <div class="card">
          <h2>Alertas ejecutivas</h2>
          <div class="alert-list">
            <div class="alert p0"><b>P0 · Health checks IA pendientes</b><p>No usar “conectado/testeado/operando” sin evidencia técnica.</p></div>
            <div class="alert p0"><b>P0 · Modelo de costos real pendiente</b><p>El demo seed permite validar pantalla, no facturación.</p></div>
            <div class="alert p1"><b>P1/P2 · Bóveda / Obsidian futura</b><p>Integración knowledge/vault queda en backlog.</p></div>
          </div>
        </div>
        <div class="card">
          <h2>Continue last project</h2>
          <p>Acceso rápido al último proyecto trabajado. Bookmark directo por proyecto queda como future feature.</p>
          <div class="action-row">
            <button class="primary-btn" data-route-shortcut="project-overview">Abrir ${escapeHtml(STATE.lastProjectId)}</button>
          </div>
        </div>
      </section>
    `;
  }

  function renderPortfolio() {
    const cards = `
      <section class="project-grid" style="margin-top:16px">
        ${STATE.projects.map((item) => `
          <article class="project-card clickable ${item.id === STATE.selectedProjectId ? "is-selected" : ""}" data-project-id="${escapeHtml(item.id)}">
            <div class="card-head">
              <div>
                <div class="card-title">${escapeHtml(item.name)}</div>
                <div class="card-meta">${escapeHtml(item.id)}</div>
              </div>
              <span class="status-pill ${statusClass(item.status)}">${escapeHtml(item.statusLabel)}</span>
            </div>
            <p>${escapeHtml(item.purpose)}</p>
            <table class="table" style="margin-top:12px">
              <tbody>
                <tr><td>Owner</td><td>${escapeHtml(item.owner)}</td></tr>
                <tr><td>IA</td><td>${escapeHtml(item.aiAssigned)}</td></tr>
                <tr><td>Modalidad</td><td>${escapeHtml(item.aiMode)}</td></tr>
                <tr><td>Costo demo</td><td>${escapeHtml(item.cost)}</td></tr>
                <tr><td>Siguiente</td><td>${escapeHtml(item.nextAction)}</td></tr>
              </tbody>
            </table>
            <div class="action-row"><button class="primary-btn" data-project-id="${escapeHtml(item.id)}">Abrir workspace</button></div>
          </article>
        `).join("")}
      </section>
    `;

    const list = `
      <section class="project-list" style="margin-top:16px">
        ${STATE.projects.map((item) => `
          <div class="project-row" data-project-id="${escapeHtml(item.id)}">
            <div><b>${escapeHtml(item.name)}</b><div class="card-meta">${escapeHtml(item.id)}</div></div>
            <span class="status-pill ${statusClass(item.status)}">${escapeHtml(item.statusLabel)}</span>
            <div>${escapeHtml(item.aiAssigned)}</div>
            <div>${escapeHtml(item.cost)}</div>
            <div>${escapeHtml(item.lastActivity)}</div>
            <button class="primary-btn" data-project-id="${escapeHtml(item.id)}">Abrir</button>
          </div>
        `).join("")}
      </section>
    `;

    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>Portafolio multi-proyecto</h2>
        <p>Cada proyecto puede tener IA, modalidad, costos, riesgos, evidencia y settings propios. Seleccionar un proyecto abre automáticamente su workspace.</p>
      </section>
      <section class="card soft" style="margin-top:16px">
        <div class="card-head">
          <div>
            <h2>Vista de portafolio</h2>
            <p>Alterna entre cartas ejecutivas y listado operativo.</p>
          </div>
          <div class="segmented">
            <button class="${portfolioViewMode === "cards" ? "is-active" : ""}" data-portfolio-view="cards">Cartas</button>
            <button class="${portfolioViewMode === "list" ? "is-active" : ""}" data-portfolio-view="list">Listado</button>
          </div>
        </div>
      </section>
      ${portfolioViewMode === "cards" ? cards : list}
    `;
  }

  function renderAIControl() {
    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>IAs disponibles, estado y costos por modalidad</h2>
        <p>Vista global de proveedores IA. Los costos son demo seed para validar diseño; no son facturación real.</p>
      </section>
      <section class="ai-grid" style="margin-top:16px">
        ${STATE.aiProviders.map((ai) => `
          <article class="ai-card">
            <div class="card-head">
              <div>
                <div class="card-title">${escapeHtml(ai.name)}</div>
                <div class="card-meta">${escapeHtml(ai.modality)}</div>
              </div>
              <span class="status-pill ${providerClass(ai.modality)}">${escapeHtml(ai.status)}</span>
            </div>
            <p>${escapeHtml(ai.recommendedFor)}</p>
            <div class="mode-cost-grid">
              ${ai.modeCosts.map((mode) => `
                <div class="mode-cost">
                  <div class="name">${escapeHtml(mode[0])}</div>
                  <div class="value">${escapeHtml(mode[1])}</div>
                </div>
              `).join("")}
            </div>
            <table class="table" style="margin-top:12px">
              <tbody>
                <tr><td>Conexión</td><td>${escapeHtml(ai.connection)}</td></tr>
                <tr><td>Costo general</td><td>${escapeHtml(ai.generalCost)}</td></tr>
                <tr><td>Riesgo privacidad</td><td>${escapeHtml(ai.privacyRisk)}</td></tr>
                <tr><td>Proyectos</td><td>${ai.assignedProjects.length ? ai.assignedProjects.map(escapeHtml).join(", ") : "Ninguno"}</td></tr>
              </tbody>
            </table>
          </article>
        `).join("")}
      </section>
    `;
  }

  function renderCostCenter() {
    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>Centro de Costos</h2>
        <p>Costos visibles para todos. Esta vista separa costo global, por IA, por proyecto y por sesión. Las cifras son demo.</p>
      </section>
      <section class="grid cols-4" style="margin-top:16px">
        <div class="card"><div class="label">Costo global HIA</div><div class="metric warn">USD 108</div><p>Demo mensual / no real.</p></div>
        <div class="card"><div class="label">Costo por IA</div><div class="metric warn">4 IAs</div><p>Demo por modalidad.</p></div>
        <div class="card"><div class="label">Costo por proyecto</div><div class="metric warn">3</div><p>Demo portfolio.</p></div>
        <div class="card"><div class="label">Tokens</div><div class="metric warn">1.57M</div><p>Demo mensual / no real.</p></div>
      </section>
      <section class="card" style="margin-top:16px">
        <h2>Desglose por proyecto</h2>
        <table class="table">
          <thead><tr><th>Proyecto</th><th>IA</th><th>Modalidad</th><th>Costo demo</th><th>Tokens demo</th></tr></thead>
          <tbody>
            ${STATE.projects.map((item) => `<tr><td>${escapeHtml(item.name)}</td><td>${escapeHtml(item.aiAssigned)}</td><td>${escapeHtml(item.aiMode)}</td><td>${escapeHtml(item.cost)}</td><td>${escapeHtml(item.tokens)}</td></tr>`).join("")}
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectOverview() {
    const p = project();
    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>${escapeHtml(p.name)}</h2>
        <p>${escapeHtml(p.purpose)}</p>
      </section>
      <section class="grid cols-4" style="margin-top:16px">
        <div class="card"><div class="label">Estado</div><div class="metric ok">${escapeHtml(p.statusLabel)}</div><p>${escapeHtml(p.risk)}</p></div>
        <div class="card"><div class="label">IA asignada</div><div class="metric info">${escapeHtml(p.aiAssigned)}</div><p>${escapeHtml(p.aiMode)}</p></div>
        <div class="card"><div class="label">Costo demo</div><div class="metric warn">${escapeHtml(p.cost)}</div><p>No operacional.</p></div>
        <div class="card"><div class="label">Evidencia</div><div class="metric ok">${escapeHtml(p.evidence)}</div><p>Según estado CLI/demo.</p></div>
      </section>
      <section class="card" style="margin-top:16px">
        <h2>Próxima acción</h2>
        <p>${escapeHtml(p.nextAction)}</p>
      </section>
    `;
  }

  function renderProjectAIChat() {
    const p = project();
    return `
      <section class="chat-layout">
        <div class="card chat-panel">
          <h2>Chat IA del Proyecto</h2>
          <p>Chat por proyecto. Backend pendiente; no se simula IA real.</p>
          <div class="chat-message"><b>Sistema</b><p>Contexto activo: ${escapeHtml(p.id)}. IA asignada: ${escapeHtml(p.aiAssigned)}. Modalidad: ${escapeHtml(p.aiMode)}.</p></div>
          <div class="chat-message"><b>Estado</b><p>UI preparada / backend pendiente. Chat global queda como future feature.</p></div>
          <textarea class="chat-input" placeholder="Prompt del proyecto. Backend pendiente."></textarea>
          <div class="action-row">
            <button class="primary-btn">Enviar a IA — pendiente backend</button>
            <button class="secondary-btn">Guardar decisión</button>
            <button class="secondary-btn">Enviar a backlog</button>
          </div>
        </div>
        <div class="card">
          <h2>Configuración IA del proyecto</h2>
          <table class="table">
            <tbody>
              <tr><td>Proyecto</td><td>${escapeHtml(p.id)}</td></tr>
              <tr><td>IA asignada</td><td>${escapeHtml(p.aiAssigned)}</td></tr>
              <tr><td>Modalidad</td><td>${escapeHtml(p.aiMode)}</td></tr>
              <tr><td>Conexión</td><td>${escapeHtml(p.aiConnection)}</td></tr>
              <tr><td>Routing policy</td><td>Pendiente definir.</td></tr>
            </tbody>
          </table>
        </div>
      </section>
    `;
  }

  function renderProjectCosts() {
    const p = project();
    return `
      ${demoRibbon()}
      <section class="card hero">
        <h2>Costos del Proyecto</h2>
        <p>Vista por proyecto. Costos demo visibles para validar layout.</p>
      </section>
      <section class="grid cols-3" style="margin-top:16px">
        <div class="card"><div class="label">Costo proyecto</div><div class="metric warn">${escapeHtml(p.cost)}</div><p>No operacional.</p></div>
        <div class="card"><div class="label">Tokens</div><div class="metric warn">${escapeHtml(p.tokens)}</div><p>No operacional.</p></div>
        <div class="card"><div class="label">Presupuesto</div><div class="metric warn">${escapeHtml(p.budget)}</div><p>No operacional.</p></div>
      </section>
    `;
  }

  function renderProjectEvidence() {
    const p = project();
    return `
      <section class="card hero">
        <h2>Evidencia del Proyecto</h2>
        <p>HIA debe diferenciarse por evidencia, trazabilidad y decisiones humanas versionadas.</p>
      </section>
      <section class="grid cols-3" style="margin-top:16px">
        <div class="card"><h3>BATON</h3><p>Continuidad operativa del proyecto.</p><span class="tag">Disponible en repo</span></div>
        <div class="card"><h3>RADAR</h3><p>Inventario/frescura de archivos.</p><span class="tag">Generado</span></div>
        <div class="card"><h3>BACKLOG</h3><p>MiniBattles, deuda y features.</p><span class="tag">Disponible en repo</span></div>
      </section>
      <section class="card" style="margin-top:16px">
        <h2>Estado runtime parcial</h2>
        <table class="table">
          <tbody>
            <tr><td>Proyecto</td><td>${escapeHtml(p.id)}</td></tr>
            <tr><td>Evidencia</td><td>${escapeHtml(p.evidence)}</td></tr>
            <tr><td>Branch</td><td>${escapeHtml(STATE.git.branch)}</td></tr>
            <tr><td>HEAD</td><td>${escapeHtml(STATE.git.head)}</td></tr>
            <tr><td>Generated at</td><td>${escapeHtml(STATE.generatedAt)}</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderKnowledgeVault() {
    return `
      <section class="card hero">
        <h2>Bóveda / Conocimiento</h2>
        <p>Obsidian o similar queda como integración futura P1/P2. No es core obligatorio de esta iteración.</p>
      </section>
    `;
  }

  function renderSettings() {
    return `
      <section class="card hero">
        <h2>Configuración Global</h2>
        <p>Settings globales: proveedores IA, políticas de modelo, presupuesto, privacidad, seguridad y deuda técnica.</p>
      </section>
    `;
  }

  function renderFuture(title, description) {
    return `
      <section class="card hero">
        <h2>${escapeHtml(title)}</h2>
        <p>${escapeHtml(description)}</p>
      </section>
      <section class="footer-note">
        <b>Future feature / backend pendiente</b>
        <p>No se presenta como funcionalidad operativa real.</p>
      </section>
    `;
  }

  function setRoute(routeName) {
    const route = ROUTES[routeName] || ROUTES["control-tower"];
    const layerEl = document.getElementById("view-layer");
    const titleEl = document.getElementById("view-title");
    const subtitleEl = document.getElementById("view-subtitle");
    const rootEl = document.getElementById("view-root");

    if (!layerEl || !titleEl || !subtitleEl || !rootEl) {
      console.error("HIA shell mount points missing");
      return;
    }

    layerEl.textContent = route.layer;
    titleEl.textContent = route.title;
    subtitleEl.textContent = route.subtitle;
    rootEl.innerHTML = route.render();

    document.querySelectorAll(".nav-item").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.route === routeName);
    });

    window.location.hash = routeName;
  }

  function openProject(projectId) {
    STATE.selectedProjectId = projectId;
    const label = document.getElementById("sidebar-project");
    if (label) label.textContent = projectId;
    setRoute("project-overview");
  }

  document.addEventListener("click", (event) => {
    const viewTarget = event.target.closest("[data-portfolio-view]");
    if (viewTarget) {
      portfolioViewMode = viewTarget.dataset.portfolioView;
      setRoute("portfolio");
      return;
    }

    const projectTarget = event.target.closest("[data-project-id]");
    if (projectTarget) {
      openProject(projectTarget.dataset.projectId);
      return;
    }

    const nav = event.target.closest("[data-route]");
    if (nav) {
      setRoute(nav.dataset.route);
      return;
    }

    const shortcut = event.target.closest("[data-route-shortcut]");
    if (shortcut) {
      setRoute(shortcut.dataset.routeShortcut);
    }
  });

  window.addEventListener("hashchange", () => {
    setRoute(window.location.hash.replace("#", "") || "control-tower");
  });

  document.addEventListener("DOMContentLoaded", () => {
    setRoute(window.location.hash.replace("#", "") || "control-tower");
  });
})();
