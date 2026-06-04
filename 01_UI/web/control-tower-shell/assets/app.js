(function () {
  "use strict";

  const runtimeState = window.HIA_STATE || {};

  const STATE = {
    selectedProjectId: "PRJ_0001_HIA.PRODUCT",
    lastProjectId: "PRJ_0001_HIA.PRODUCT",
    global: {
      portfolioHealth: "Demo shell",
      totalProjects: 3,
      activeProjects: 1,
      blockedProjects: 0,
      humanDecisions: 1,
      connectedAIs: 3,
      operatingAIs: 1,
      globalMonthlyCost: "Manual / pending real cost model",
      costVisibility: "Visible para todos"
    },
    aiProviders: [
      {
        id: "chatgpt",
        name: "ChatGPT",
        modality: "web / plan",
        status: "Disponible",
        connection: "Pendiente test formal",
        cost: "Plan / costo global pendiente",
        recommendedFor: "Planning, governance, writing, analysis",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"]
      },
      {
        id: "codex",
        name: "Codex",
        modality: "desktop / coding",
        status: "Disponible",
        connection: "Pendiente test formal",
        cost: "Plan / uso pendiente",
        recommendedFor: "Código, refactor, repo operations",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"]
      },
      {
        id: "local-llm",
        name: "Local LLM",
        modality: "local",
        status: "Backlog",
        connection: "No conectado",
        cost: "Costo marginal bajo / hardware",
        recommendedFor: "Privacidad, offline, bajo costo variable",
        assignedProjects: []
      }
    ],
    projects: [
      {
        id: "PRJ_0001_HIA.PRODUCT",
        name: "HIA Product",
        status: "active",
        statusLabel: "Activo",
        owner: "Human + System",
        purpose: "Construir HIA como sistema multi-proyecto con AI Operating Layer.",
        next: "Implementar navegación Control Tower / Portfolio / Project Workspace.",
        aiMode: "web + desktop/CLI",
        aiAssigned: "ChatGPT + Codex",
        aiConnection: "Pendiente test formal por proveedor",
        projectCost: "Pendiente modelo real",
        tokens: "Pendiente medición",
        budget: "Pendiente definición",
        risk: "Arquitectura UI en estabilización",
        evidence: "FRESH"
      },
      {
        id: "PRJ_TEMPLATE_CLIENT",
        name: "Cliente / Proyecto futuro",
        status: "backlog",
        statusLabel: "Backlog",
        owner: "Por definir",
        purpose: "Placeholder para demostrar multi-proyecto.",
        next: "Alta formal futura.",
        aiMode: "por definir",
        aiAssigned: "por definir",
        aiConnection: "N/A",
        projectCost: "N/A",
        tokens: "N/A",
        budget: "N/A",
        risk: "No iniciado",
        evidence: "N/A"
      },
      {
        id: "PRJ_REPORTING_LAYER",
        name: "Reporting Layer",
        status: "backlog",
        statusLabel: "Feature futura",
        owner: "Por definir",
        purpose: "Reportes ejecutivos, operativos y técnicos.",
        next: "Diseñar modelo de reportes.",
        aiMode: "por definir",
        aiAssigned: "por definir",
        aiConnection: "N/A",
        projectCost: "N/A",
        tokens: "N/A",
        budget: "N/A",
        risk: "Feature futura",
        evidence: "N/A"
      }
    ],
    runtime: {
      head: runtimeState?.git?.head || "Disponible en hia.state.js / pending UI mapping",
      branch: runtimeState?.git?.branch || "Disponible en hia.state.js / pending UI mapping",
      projectContinue: runtimeState?.cli?.projectContinueSummary || "CLI state generated / pending mapping",
      generatedAt: runtimeState?.generatedAt || "N/A"
    }
  };

  const ROUTES = {
    "control-tower": {
      layer: "HIA GLOBAL",
      title: "Control Tower",
      subtitle: "Vista global de HIA: portfolio, IAs, costos, alertas y continuidad.",
      render: renderControlTower
    },
    "portfolio": {
      layer: "HIA GLOBAL",
      title: "Portfolio",
      subtitle: "Múltiples proyectos, estado, IA asignada, costo y próxima acción.",
      render: renderPortfolio
    },
    "ai-control": {
      layer: "HIA GLOBAL",
      title: "AI Control Tower",
      subtitle: "IAs disponibles, operativas, conectadas/testeadas y asignadas a proyectos.",
      render: renderAIControl
    },
    "cost-center": {
      layer: "HIA GLOBAL",
      title: "Cost Center",
      subtitle: "Costos globales, por IA y por proyecto. Visible para todos.",
      render: renderCostCenter
    },
    "project-overview": {
      layer: "PROJECT WORKSPACE",
      title: "Project Overview",
      subtitle: "KPIs, estado, riesgos y próxima acción del proyecto seleccionado.",
      render: renderProjectOverview
    },
    "project-ai": {
      layer: "PROJECT WORKSPACE",
      title: "Project AI",
      subtitle: "Configuración IA específica del proyecto seleccionado.",
      render: renderProjectAI
    },
    "project-chat": {
      layer: "PROJECT WORKSPACE",
      title: "Project Chat",
      subtitle: "Chat IA por proyecto. Backend pendiente.",
      render: renderProjectChat
    },
    "project-costs": {
      layer: "PROJECT WORKSPACE",
      title: "Project Costs",
      subtitle: "Costos, tokens y presupuesto del proyecto seleccionado.",
      render: renderProjectCosts
    },
    "project-evidence": {
      layer: "PROJECT WORKSPACE",
      title: "Project Evidence",
      subtitle: "Evidencia, BATON, RADAR, BACKLOG y decisiones humanas del proyecto.",
      render: renderProjectEvidence
    },
    "project-settings": {
      layer: "PROJECT WORKSPACE",
      title: "Project Settings",
      subtitle: "Settings del proyecto: IA, costos, contexto, permisos y fuentes.",
      render: renderProjectSettings
    },
    "reports": {
      layer: "ENTERPRISE",
      title: "Reports",
      subtitle: "Feature futura de reportes portfolio/proyecto/exportables.",
      render: renderReports
    },
    "collaboration": {
      layer: "ENTERPRISE",
      title: "Collaboration",
      subtitle: "Feature futura de roles, comentarios, asignaciones y aprobaciones.",
      render: renderCollaboration
    },
    "integrations": {
      layer: "ENTERPRISE",
      title: "Integrations",
      subtitle: "Feature futura de integraciones externas.",
      render: renderIntegrations
    },
    "knowledge-vault": {
      layer: "ENTERPRISE",
      title: "Knowledge / Vault",
      subtitle: "Obsidian o similar queda como backlog P1/P2.",
      render: renderKnowledgeVault
    },
    "admin-settings": {
      layer: "GOVERNANCE",
      title: "Admin / Settings",
      subtitle: "Settings globales, seguridad, encriptación futura y políticas.",
      render: renderAdminSettings
    }
  };

  function html(strings, ...values) {
    return strings.reduce((acc, str, index) => acc + str + (values[index] ?? ""), "");
  }

  function selectedProject() {
    return STATE.projects.find((project) => project.id === STATE.selectedProjectId) || STATE.projects[0];
  }

  function statusClass(status) {
    if (status === "active") return "active";
    if (status === "demo") return "demo";
    if (status === "blocked") return "blocked";
    return "backlog";
  }

  function renderControlTower() {
    return html`
      <section class="card hero">
        <h2>HIA Control Tower global</h2>
        <p><b>Entrada principal de HIA.</b> Desde aquí se ve el estado global, portfolio, IAs disponibles/operativas, costos, alertas y acceso rápido al último proyecto trabajado.</p>
      </section>

      <div class="grid cols-4" style="margin-top:16px">
        <div class="card"><div class="label">Proyectos visibles</div><div class="metric">${STATE.projects.length}</div><p>Demo data controlada.</p></div>
        <div class="card"><div class="label">Activos</div><div class="metric ok">${STATE.global.activeProjects}</div><p>Proyectos con operación actual.</p></div>
        <div class="card"><div class="label">IAs disponibles</div><div class="metric info">${STATE.aiProviders.length}</div><p>Inventario inicial, conexión formal pendiente.</p></div>
        <div class="card"><div class="label">Costos</div><div class="metric warn">Pendiente</div><p>Modelo global/proyecto/IA aún por implementar.</p></div>
      </div>

      <div class="grid two-one" style="margin-top:16px">
        <section class="card">
          <h2>Alertas globales</h2>
          <table class="table">
            <thead><tr><th>Alerta</th><th>Prioridad</th><th>Lectura</th></tr></thead>
            <tbody>
              <tr><td>Conexión formal de IAs</td><td>P0</td><td>Hay proveedores listados, pero falta test formal de conexión/funcionamiento.</td></tr>
              <tr><td>Cost model</td><td>P0</td><td>Costos visibles para todos, pero falta modelo real por IA/proyecto.</td></tr>
              <tr><td>Estado real UI</td><td>P0</td><td>Existe hia.state.js; falta mapearlo a arquitectura nueva.</td></tr>
            </tbody>
          </table>
        </section>

        <section class="card">
          <h2>Continue last project</h2>
          <p>Acceso rápido al último proyecto trabajado. Bookmark directo a proyecto queda como future feature.</p>
          <div class="action-row">
            <button class="primary-btn" data-route-shortcut="project-overview">Open ${STATE.lastProjectId}</button>
          </div>
        </section>
      </div>
    `;
  }

  function renderPortfolio() {
    return html`
      <section class="card">
        <h2>Portfolio multi-proyecto</h2>
        <p>HIA administra múltiples proyectos. El proyecto activo seleccionado no es todo HIA.</p>
        <div class="grid" style="margin-top:14px">
          ${STATE.projects.map((project) => `
            <article class="project-card ${project.id === STATE.selectedProjectId ? "is-selected" : ""}">
              <div class="card-head">
                <div>
                  <div class="card-title">${project.name}</div>
                  <div class="card-meta">${project.id}</div>
                </div>
                <span class="status-pill ${statusClass(project.status)}">${project.statusLabel}</span>
              </div>
              <p>${project.purpose}</p>
              <table class="table" style="margin-top:12px">
                <tbody>
                  <tr><td>IA</td><td>${project.aiAssigned}</td></tr>
                  <tr><td>Modalidad</td><td>${project.aiMode}</td></tr>
                  <tr><td>Costo</td><td>${project.projectCost}</td></tr>
                  <tr><td>Siguiente</td><td>${project.next}</td></tr>
                </tbody>
              </table>
            </article>
          `).join("")}
        </div>
      </section>
    `;
  }

  function renderAIControl() {
    return html`
      <section class="card">
        <h2>AI Control Tower global</h2>
        <p>Inventario global de IAs. La prueba formal de conexión/funcionamiento queda pendiente; no se simula como real.</p>
        <div class="grid cols-3" style="margin-top:14px">
          ${STATE.aiProviders.map((ai) => `
            <article class="ai-card">
              <div class="card-head">
                <div>
                  <div class="card-title">${ai.name}</div>
                  <div class="card-meta">${ai.modality}</div>
                </div>
                <span class="status-pill ${ai.modality.includes("local") ? "local" : "web"}">${ai.status}</span>
              </div>
              <p>${ai.recommendedFor}</p>
              <table class="table" style="margin-top:12px">
                <tbody>
                  <tr><td>Conexión</td><td>${ai.connection}</td></tr>
                  <tr><td>Costo</td><td>${ai.cost}</td></tr>
                  <tr><td>Proyectos</td><td>${ai.assignedProjects.length ? ai.assignedProjects.join(", ") : "Ninguno"}</td></tr>
                </tbody>
              </table>
            </article>
          `).join("")}
        </div>
      </section>
    `;
  }

  function renderCostCenter() {
    return html`
      <section class="card">
        <h2>Cost Center</h2>
        <p>Los costos deben ser visibles para todos. Esta vista separa costo global, costo por IA y costo por proyecto.</p>
        <div class="grid cols-3" style="margin-top:14px">
          <div class="card"><div class="label">Costo global HIA</div><div class="metric warn">Pendiente</div><p>Falta modelo real.</p></div>
          <div class="card"><div class="label">Costo por IA</div><div class="metric warn">Pendiente</div><p>Requiere proveedor/modelo/plan/API.</p></div>
          <div class="card"><div class="label">Costo por proyecto</div><div class="metric warn">Pendiente</div><p>Requiere asignación IA/proyecto.</p></div>
        </div>
        <table class="table" style="margin-top:16px">
          <thead><tr><th>Proyecto</th><th>IA</th><th>Modalidad</th><th>Costo</th><th>Tokens</th></tr></thead>
          <tbody>
            ${STATE.projects.map((project) => `
              <tr><td>${project.name}</td><td>${project.aiAssigned}</td><td>${project.aiMode}</td><td>${project.projectCost}</td><td>${project.tokens}</td></tr>
            `).join("")}
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectOverview() {
    const p = selectedProject();
    return html`
      <section class="card hero">
        <h2>${p.name}</h2>
        <p>${p.purpose}</p>
      </section>
      <div class="grid cols-3" style="margin-top:16px">
        <div class="card"><div class="label">Estado</div><div class="metric ok">${p.statusLabel}</div><p>${p.risk}</p></div>
        <div class="card"><div class="label">IA asignada</div><div class="metric info">${p.aiAssigned}</div><p>${p.aiMode}</p></div>
        <div class="card"><div class="label">Evidencia</div><div class="metric ok">${p.evidence}</div><p>Estado operacional del proyecto.</p></div>
      </div>
    `;
  }

  function renderProjectAI() {
    const p = selectedProject();
    return html`
      <section class="card">
        <h2>Project AI</h2>
        <p>Configuración IA específica del proyecto. Cada proyecto puede tener modalidad distinta.</p>
        <table class="table" style="margin-top:14px">
          <tbody>
            <tr><td>Proyecto</td><td>${p.id}</td></tr>
            <tr><td>IA asignada</td><td>${p.aiAssigned}</td></tr>
            <tr><td>Modalidad</td><td>${p.aiMode}</td></tr>
            <tr><td>Conexión</td><td>${p.aiConnection}</td></tr>
            <tr><td>Routing policy</td><td>Pendiente definir por costo, privacidad, precisión, código, documentos y research.</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectChat() {
    const p = selectedProject();
    return html`
      <section class="card">
        <h2>Project Chat — ${p.name}</h2>
        <p>Chat IA por proyecto. Backend pendiente; UI preparada para contexto del proyecto.</p>
        <div class="chat-box" style="margin-top:14px">
          <div class="chat-message"><b>System</b><p>Contexto activo: ${p.id}. Chat global queda como future feature.</p></div>
          <textarea class="chat-input" placeholder="Escribe un prompt del proyecto. Backend pendiente."></textarea>
          <div class="action-row">
            <button class="primary-btn">Enviar a IA — backend pendiente</button>
            <button class="secondary-btn">Guardar decisión</button>
            <button class="secondary-btn">Enviar a backlog</button>
          </div>
        </div>
      </section>
    `;
  }

  function renderProjectCosts() {
    const p = selectedProject();
    return html`
      <section class="card">
        <h2>Project Costs</h2>
        <p>Costos visibles para todos. Datos reales pendientes de modelo de costos.</p>
        <table class="table" style="margin-top:14px">
          <tbody>
            <tr><td>Proyecto</td><td>${p.id}</td></tr>
            <tr><td>IA asignada</td><td>${p.aiAssigned}</td></tr>
            <tr><td>Costo proyecto</td><td>${p.projectCost}</td></tr>
            <tr><td>Tokens</td><td>${p.tokens}</td></tr>
            <tr><td>Presupuesto</td><td>${p.budget}</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectEvidence() {
    const p = selectedProject();
    return html`
      <section class="card">
        <h2>Project Evidence</h2>
        <p>Vista preparada para BATON, RADAR, BACKLOG, decisiones humanas y fuentes canónicas.</p>
        <table class="table" style="margin-top:14px">
          <tbody>
            <tr><td>Proyecto</td><td>${p.id}</td></tr>
            <tr><td>Evidencia</td><td>${p.evidence}</td></tr>
            <tr><td>Runtime state</td><td>${STATE.runtime.generatedAt}</td></tr>
            <tr><td>Git branch</td><td>${STATE.runtime.branch}</td></tr>
            <tr><td>Git head</td><td>${STATE.runtime.head}</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectSettings() {
    return renderFuture("Project Settings", "Settings por proyecto: IA, costos, contexto, permisos, fuentes y workflow.");
  }

  function renderReports() {
    return renderFuture("Reports", "Reportes portfolio/proyecto/deuda/evidencia y export PDF/PPT/HTML.");
  }

  function renderCollaboration() {
    return renderFuture("Collaboration", "Roles, permisos, comentarios, asignaciones, aprobaciones e historial.");
  }

  function renderIntegrations() {
    return renderFuture("Integrations", "GitHub, Drive/OneDrive, Jira/Trello/Planner, Slack/Teams, Calendar, Email, APIs.");
  }

  function renderKnowledgeVault() {
    return renderFuture("Knowledge / Vault", "Obsidian o similar queda backlog P1/P2. Encriptación queda deuda normal/futura.");
  }

  function renderAdminSettings() {
    return renderFuture("Admin / Settings", "Settings globales: proveedores IA, políticas de modelo, presupuesto global, privacidad y seguridad.");
  }

  function renderFuture(title, description) {
    return html`
      <section class="card">
        <h2>${title}</h2>
        <p>${description}</p>
        <div class="warning" style="margin-top:14px">
          <b>Feature futura / backend pendiente</b>
          <p>No se presenta como funcionalidad real. Queda estructurada para roadmap.</p>
        </div>
      </section>
    `;
  }

  function setRoute(routeName) {
    const route = ROUTES[routeName] || ROUTES["control-tower"];
    document.getElementById("view-layer").textContent = route.layer;
    document.getElementById("view-title").textContent = route.title;
    document.getElementById("view-subtitle").textContent = route.subtitle;
    document.getElementById("view-root").innerHTML = route.render();

    document.querySelectorAll(".nav-item").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.route === routeName);
    });

    window.location.hash = routeName;
  }

  document.addEventListener("click", (event) => {
    const navButton = event.target.closest("[data-route]");
    if (navButton) {
      setRoute(navButton.dataset.route);
      return;
    }

    const shortcut = event.target.closest("[data-route-shortcut]");
    if (shortcut) {
      setRoute(shortcut.dataset.routeShortcut);
    }
  });

  document.getElementById("continue-last-project").addEventListener("click", () => {
    setRoute("project-overview");
  });

  window.addEventListener("hashchange", () => {
    setRoute(window.location.hash.replace("#", "") || "control-tower");
  });

  setRoute(window.location.hash.replace("#", "") || "control-tower");
})();
