(function () {
  "use strict";

  let portfolioViewMode = "cards";

  const runtimeState = window.HIA_STATE || {};

  const STATE = {
    selectedProjectId: "PRJ_0001_HIA.PRODUCT",
    lastProjectId: "PRJ_0001_HIA.PRODUCT",
    generatedAt: runtimeState.generatedAt || "Pendiente conexión real",
    git: {
      branch: runtimeState?.git?.branch || "Pendiente conexión real",
      head: runtimeState?.git?.head || "Pendiente conexión real",
      status: runtimeState?.git?.status || "Pendiente conexión real"
    },
    global: {
      totalProjects: 3,
      activeProjects: 1,
      blockedProjects: 0,
      humanDecisions: 1,
      availableAIs: 4,
      testedAIs: "Pendiente health check",
      operatingAIs: "Pendiente health check",
      globalCost: "Pendiente modelo real",
      costPolicy: "Visible para todos"
    },
    aiProviders: [
      {
        id: "chatgpt",
        name: "ChatGPT",
        modality: "Web / Plan",
        status: "Demo: disponible",
        connection: "Demo: health check pendiente",
        generalCost: "Demo: USD 25/mes",
        costModel: "Plan mensual / costo fijo demo",
        privacyRisk: "Medio: web",
        recommendedFor: "Planificación, análisis, governance, redacción",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"],
        modeCosts: [
          { name: "Web plan", value: "USD 25/mes demo" },
          { name: "API", value: "USD 0.01–0.08/1K tokens demo" },
          { name: "Desktop", value: "Incluido en plan demo" },
          { name: "Proyecto actual", value: "USD 18/mes demo" }
        ]
      },
      {
        id: "codex",
        name: "Codex",
        modality: "Desktop / Coding",
        status: "Demo: disponible",
        connection: "Demo: health check pendiente",
        generalCost: "Demo: incluido en plan",
        costModel: "Plan / uso coding demo",
        privacyRisk: "Medio: repo/code context",
        recommendedFor: "Código, refactor, repo operations",
        assignedProjects: ["PRJ_0001_HIA.PRODUCT"],
        modeCosts: [
          { name: "Desktop", value: "Incluido demo" },
          { name: "API", value: "Pendiente demo" },
          { name: "Repo ops", value: "USD 12/sesión demo" },
          { name: "Proyecto actual", value: "USD 42/mes demo" }
        ]
      },
      {
        id: "claude",
        name: "Claude",
        modality: "Web / posible CLI",
        status: "Demo: candidato",
        connection: "Demo: no testeado",
        generalCost: "Demo: USD 20/mes",
        costModel: "Plan/API demo",
        privacyRisk: "Medio: web",
        recommendedFor: "UX critique, documentos largos, razonamiento narrativo",
        assignedProjects: ["PRJ_TEMPLATE_CLIENT"],
        modeCosts: [
          { name: "Web plan", value: "USD 20/mes demo" },
          { name: "API", value: "USD 0.01–0.09/1K tokens demo" },
          { name: "CLI", value: "Pendiente demo" },
          { name: "Proyecto actual", value: "USD 0 demo" }
        ]
      },
      {
        id: "local-llm",
        name: "Local LLM",
        modality: "Local",
        status: "Demo: future integration",
        connection: "Demo: no conectado",
        generalCost: "Demo: costo marginal bajo",
        costModel: "Hardware/local demo",
        privacyRisk: "Bajo si es local",
        recommendedFor: "Privacidad, bajo costo variable, offline",
        assignedProjects: ["PRJ_REPORTING_LAYER"],
        modeCosts: [
          { name: "Ollama/local", value: "USD 0 API demo" },
          { name: "Hardware", value: "Costo hundido demo" },
          { name: "Electricidad", value: "USD 3/mes demo" },
          { name: "Proyecto actual", value: "USD 0 demo" }
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
        purpose: "Construir HIA como Control Tower multi-proyecto con operación IA, costos y evidencia.",
        nextAction: "Implementar HIA Control Tower Shell v0.2 basada en Stitch saneado.",
        aiAssigned: "ChatGPT + Codex",
        aiMode: "Web + Desktop/CLI",
        aiConnection: "Pendiente health check formal",
        cost: "Demo: USD 72/mes",
        tokens: "Demo: 1.2M tokens/mes",
        budget: "Demo: USD 150/mes",
        evidence: "FRESH según CLI / resolver",
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
        aiAssigned: "Por definir",
        aiMode: "Por definir",
        aiConnection: "N/A",
        cost: "Demo: USD 25/mes",
        tokens: "Demo: 280K tokens/mes",
        budget: "Demo: USD 80/mes",
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
        aiAssigned: "Por definir",
        aiMode: "Por definir",
        aiConnection: "N/A",
        cost: "Demo: USD 8/mes",
        tokens: "Demo: 90K tokens/mes",
        budget: "Demo: USD 30/mes",
        evidence: "N/A",
        risk: "Feature futura",
        lastActivity: "N/A"
      }
    ],
    roadmap: [
      { item: "Obsidian / similar", priority: "P1/P2", status: "Future integration" },
      { item: "Encriptación", priority: "P2", status: "Deuda técnica normal" },
      { item: "Health checks IA", priority: "P0", status: "Pendiente" },
      { item: "Modelo real de costos", priority: "P0", status: "Pendiente" },
      { item: "Conectar hia.state.js fino", priority: "P0", status: "Siguiente" }
    ]
  };

  const ROUTES = {
    "control-tower": ["HIA GLOBAL", "Torre de Control HIA", "Vista ejecutiva global: portfolio, IAs, costos, alertas y continuidad.", renderControlTower],
    "portfolio": ["HIA GLOBAL", "Portafolio", "Vista multi-proyecto: estado, IA asignada, costos y próxima acción.", renderPortfolio],
    "ai-control": ["HIA GLOBAL", "Control de IA", "Inventario global de IAs, modalidad, conexión, costo y asignación a proyectos.", renderAIControl],
    "cost-center": ["HIA GLOBAL", "Centro de Costos", "Costos globales, por IA, por proyecto y por sesión. Visible para todos.", renderCostCenter],
    "project-overview": ["PROJECT WORKSPACE", "Workspace / Vista General", "KPIs, estado, riesgos y próxima acción del proyecto seleccionado.", renderProjectOverview],
    "project-ai-chat": ["PROJECT WORKSPACE", "IA / Chat del Proyecto", "IA asignada y chat IA por proyecto. Backend pendiente.", renderProjectAIChat],
    "project-costs": ["PROJECT WORKSPACE", "Costos del Proyecto", "Presupuesto, tokens, modalidad IA y costos del proyecto.", renderProjectCosts],
    "project-evidence": ["PROJECT WORKSPACE", "Evidencia del Proyecto", "BATON, RADAR, BACKLOG, artifacts y decisiones humanas.", renderProjectEvidence],
    "reports": ["ENTERPRISE", "Informes", "Reportabilidad futura: portfolio, proyecto, deuda, evidencia y exportables.", () => renderFuture("Informes", "Reportes ejecutivos, operativos, técnicos, PDF/PPT/HTML.")],
    "collaboration": ["ENTERPRISE", "Colaboración", "Roles, comentarios, asignaciones, aprobaciones e historial.", () => renderFuture("Colaboración", "Feature futura para trabajo multiusuario y decisiones trazables.")],
    "integrations": ["ENTERPRISE", "Integraciones", "GitHub, Drive/OneDrive, Jira/Trello/Planner, Slack/Teams, Calendar, Email y APIs.", () => renderFuture("Integraciones", "Feature futura. No declarar conectores como reales sin implementación.")],
    "knowledge-vault": ["ENTERPRISE", "Bóveda / Conocimiento", "Obsidian o similar como integración futura P1/P2.", renderKnowledgeVault],
    "settings": ["GOVERNANCE", "Configuración Global", "Settings globales, políticas IA, privacidad, seguridad y deuda técnica.", renderSettings]
  };

  function html(strings, ...values) {
    return strings.reduce((acc, str, index) => acc + str + (values[index] ?? ""), "");
  }

  function project() {
    return STATE.projects.find((p) => p.id === STATE.selectedProjectId) || STATE.projects[0];
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
        <span>Fuente: seed UX PRJPB_009M-C</span>
      </div>
    `;
  }

  function openProject(projectId) {
    STATE.selectedProjectId = projectId;
    const label = document.getElementById("sidebar-project");
    if (label) label.textContent = projectId;
    setRoute("project-overview");
  }

  function renderControlTower() {
    return html`
      ${demoRibbon()}
      <section class="card hero">
        <h2>Entrada global de HIA</h2>
        <p><b>HIA es una plataforma de desarrollo, continuidad, trazabilidad y control de proyectos.</b> Reduce dispersión operativa y coordina trabajo colaborativo entre humanos e IAs. Todo dato demo queda marcado como no operacional.</p>
      </section>

      <section class="kpi-strip">
        <div class="card"><div class="label">Proyectos visibles</div><div class="metric">${STATE.global.totalProjects}</div><p>Incluye placeholders controlados.</p></div>
        <div class="card"><div class="label">Proyectos activos</div><div class="metric ok">${STATE.global.activeProjects}</div><p>Trabajo operativo actual.</p></div>
        <div class="card"><div class="label">IAs disponibles</div><div class="metric info">${STATE.global.availableAIs}</div><p>No implica conexión testeada.</p></div>
        <div class="card"><div class="label">Costo global</div><div class="metric warn">Pendiente</div><p>Modelo real aún no definido.</p></div>
      </section>

      <section class="grid two-one" style="margin-top:16px">
        <div class="card">
          <h2>Alertas ejecutivas</h2>
          <div class="alert-list">
            <div class="alert p0"><b>P0 · Health checks IA pendientes</b><p>No usar “conectado/testeado/operando” sin evidencia técnica.</p></div>
            <div class="alert p0"><b>P0 · Modelo de costos pendiente</b><p>Costos visibles para todos, pero falta fuente/cálculo/proveedor/proyecto.</p></div>
            <div class="alert p1"><b>P1 · Bóveda / Obsidian futura</b><p>Integración knowledge/vault queda en backlog P1/P2.</p></div>
          </div>
        </div>

        <div class="card">
          <h2>Continue last project</h2>
          <p>Acceso rápido al último proyecto trabajado. Bookmark directo por proyecto queda como future feature.</p>
          <div class="action-row">
            <button class="primary-btn" data-route-shortcut="project-overview">Abrir ${STATE.lastProjectId}</button>
          </div>
        </div>
      </section>

      <section class="grid cols-2" style="margin-top:16px">
        <div class="card">
          <h2>Estado técnico parcial</h2>
          <table class="table">
            <tbody>
              <tr><td>Branch</td><td>${STATE.git.branch}</td></tr>
              <tr><td>HEAD</td><td>${STATE.git.head}</td></tr>
              <tr><td>State generated</td><td>${STATE.generatedAt}</td></tr>
            </tbody>
          </table>
        </div>
        <div class="card">
          <h2>Regla anti-humo</h2>
          <p>No se declaran métricas, costos, conexiones ni tests como reales sin evidencia. Esta shell toma Stitch como arquitectura visual, pero sanea los datos.</p>
        </div>
      </section>
    `;
  }

  function renderPortfolio() {
    const cards = `
      <section class="project-grid" style="margin-top:16px">
        ${STATE.projects.map((p) => `
          <article class="project-card clickable ${p.id === STATE.selectedProjectId ? "is-selected" : ""}" data-project-id="${p.id}">
            <div class="card-head">
              <div>
                <div class="card-title">${p.name}</div>
                <div class="card-meta">${p.id}</div>
              </div>
              <span class="status-pill ${statusClass(p.status)}">${p.statusLabel}</span>
            </div>
            <p>${p.purpose}</p>
            <table class="table" style="margin-top:12px">
              <tbody>
                <tr><td>Owner</td><td>${p.owner}</td></tr>
                <tr><td>IA</td><td>${p.aiAssigned}</td></tr>
                <tr><td>Modalidad</td><td>${p.aiMode}</td></tr>
                <tr><td>Costo demo</td><td>${p.cost}</td></tr>
                <tr><td>Siguiente</td><td>${p.nextAction}</td></tr>
              </tbody>
            </table>
            <div class="action-row"><button class="primary-btn" data-project-id="${p.id}">Abrir workspace</button></div>
          </article>
        `).join("")}
      </section>`;

    const list = `
      <section class="project-list" style="margin-top:16px">
        ${STATE.projects.map((p) => `
          <div class="project-row" data-project-id="${p.id}">
            <div><b>${p.name}</b><div class="card-meta">${p.id}</div></div>
            <span class="status-pill ${statusClass(p.status)}">${p.statusLabel}</span>
            <div>${p.aiAssigned}</div>
            <div>${p.cost}</div>
            <div>${p.lastActivity}</div>
            <button class="primary-btn" data-project-id="${p.id}">Abrir</button>
          </div>
        `).join("")}
      </section>`;

    return html`
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
    return html`
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
                <div class="card-title">${ai.name}</div>
                <div class="card-meta">${ai.modality}</div>
              </div>
              <span class="status-pill ${providerClass(ai.modality)}">${ai.status}</span>
            </div>
            <p>${ai.recommendedFor}</p>
            <div class="mode-cost-grid">
              ${ai.modeCosts.map((m) => `
                <div class="mode-cost">
                  <div class="name">${m.name}</div>
                  <div class="value">${m.value}</div>
                </div>
              `).join("")}
            </div>
            <table class="table" style="margin-top:12px">
              <tbody>
                <tr><td>Conexión</td><td>${ai.connection}</td></tr>
                <tr><td>Costo general</td><td>${ai.generalCost}</td></tr>
                <tr><td>Riesgo privacidad</td><td>${ai.privacyRisk}</td></tr>
                <tr><td>Proyectos</td><td>${ai.assignedProjects.length ? ai.assignedProjects.join(", ") : "Ninguno"}</td></tr>
              </tbody>
            </table>
            <div class="source-note">Demo seed: reemplazar por health check + modelo de costos real.</div>
          </article>
        `).join("")}
      </section>
    `;
  }

  function renderCostCenter() {
    return html`
      <section class="card hero">
        ${demoRibbon()}
        <h2>Centro de Costos</h2>
        <p>Costos visibles para todos. Esta vista separa costo global, por IA, por proyecto y por sesión. No se muestran cifras exactas sin modelo real.</p>
      </section>

      <section class="grid cols-4" style="margin-top:16px">
        <div class="card"><div class="label">Costo global HIA</div><div class="metric warn">USD 108</div><p>Demo mensual / no real.</p></div>
        <div class="card"><div class="label">Costo por IA</div><div class="metric warn">4 IAs</div><p>Demo por modalidad.</p></div>
        <div class="card"><div class="label">Costo por proyecto</div><div class="metric warn">3</div><p>Demo portfolio.</p></div>
        <div class="card"><div class="label">Tokens</div><div class="metric warn">1.57M</div><p>Demo mensual / no real.</p></div>
      </section>

      <section class="grid two-one" style="margin-top:16px">
        <div class="card">
          <h2>Desglose por proyecto</h2>
          <table class="table">
            <thead><tr><th>Proyecto</th><th>IA</th><th>Modalidad</th><th>Costo</th><th>Tokens</th></tr></thead>
            <tbody>
              ${STATE.projects.map((p) => `<tr><td>${p.name}</td><td>${p.aiAssigned}</td><td>${p.aiMode}</td><td>${p.cost}</td><td>${p.tokens}</td></tr>`).join("")}
            </tbody>
          </table>
        </div>
        <div class="card">
          <h2>Local vs Web</h2>
          <div class="chart-placeholder">Pendiente modelo comparativo real</div>
        </div>
      </section>
    `;
  }

  function renderProjectOverview() {
    const p = project();
    return html`
      <section class="card hero">
        <h2>${p.name}</h2>
        <p>${p.purpose}</p>
      </section>
      <section class="grid cols-4" style="margin-top:16px">
        <div class="card"><div class="label">Estado</div><div class="metric ok">${p.statusLabel}</div><p>${p.risk}</p></div>
        <div class="card"><div class="label">IA asignada</div><div class="metric info">${p.aiAssigned}</div><p>${p.aiMode}</p></div>
        <div class="card"><div class="label">Costo</div><div class="metric warn">Pendiente</div><p>${p.cost}</p></div>
        <div class="card"><div class="label">Evidencia</div><div class="metric ok">${p.evidence}</div><p>Según estado CLI actual.</p></div>
      </section>
      <section class="card" style="margin-top:16px">
        <h2>Próxima acción</h2>
        <p>${p.nextAction}</p>
      </section>
    `;
  }

  function renderProjectAIChat() {
    const p = project();
    return html`
      <section class="chat-layout">
        <div class="card chat-panel">
          <h2>Chat IA del Proyecto</h2>
          <p>Chat por proyecto. Backend pendiente; no se simula IA real.</p>
          <div class="chat-message"><b>Sistema</b><p>Contexto activo: ${p.id}. IA asignada: ${p.aiAssigned}. Modalidad: ${p.aiMode}.</p></div>
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
              <tr><td>Proyecto</td><td>${p.id}</td></tr>
              <tr><td>IA asignada</td><td>${p.aiAssigned}</td></tr>
              <tr><td>Modalidad</td><td>${p.aiMode}</td></tr>
              <tr><td>Conexión</td><td>${p.aiConnection}</td></tr>
              <tr><td>Routing policy</td><td>Pendiente definir.</td></tr>
            </tbody>
          </table>
        </div>
      </section>
    `;
  }

  function renderProjectCosts() {
    const p = project();
    return html`
      <section class="card hero">
        <h2>Costos del Proyecto</h2>
        <p>Vista por proyecto. Costos visibles para todos, pero todavía pendientes de modelo real.</p>
      </section>
      <section class="grid cols-3" style="margin-top:16px">
        <div class="card"><div class="label">Costo proyecto</div><div class="metric warn">Pendiente</div><p>${p.cost}</p></div>
        <div class="card"><div class="label">Tokens</div><div class="metric warn">Pendiente</div><p>${p.tokens}</p></div>
        <div class="card"><div class="label">Presupuesto</div><div class="metric warn">Pendiente</div><p>${p.budget}</p></div>
      </section>
      <section class="card" style="margin-top:16px">
        <h2>Detalle</h2>
        <table class="table">
          <tbody>
            <tr><td>IA asignada</td><td>${p.aiAssigned}</td></tr>
            <tr><td>Modalidad</td><td>${p.aiMode}</td></tr>
            <tr><td>Conexión</td><td>${p.aiConnection}</td></tr>
            <tr><td>Regla</td><td>No mostrar costo exacto sin fuente, modelo, fecha y cálculo.</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderProjectEvidence() {
    const p = project();
    return html`
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
            <tr><td>Proyecto</td><td>${p.id}</td></tr>
            <tr><td>Evidencia</td><td>${p.evidence}</td></tr>
            <tr><td>Branch</td><td>${STATE.git.branch}</td></tr>
            <tr><td>HEAD</td><td>${STATE.git.head}</td></tr>
            <tr><td>Generated at</td><td>${STATE.generatedAt}</td></tr>
          </tbody>
        </table>
      </section>
    `;
  }

  function renderKnowledgeVault() {
    return html`
      <section class="card hero">
        <h2>Bóveda / Conocimiento</h2>
        <p>Obsidian o similar queda como integración futura P1/P2. No es core obligatorio de esta iteración.</p>
      </section>
      <section class="grid cols-3" style="margin-top:16px">
        <div class="future-card"><h3>Obsidian / similar</h3><p>Backlog P1/P2.</p></div>
        <div class="future-card"><h3>Fuentes canónicas</h3><p>BATON, RADAR, BACKLOG, artifacts.</p></div>
        <div class="future-card"><h3>Vector / RAG futuro</h3><p>Future integration, no implementado.</p></div>
      </section>
    `;
  }

  function renderSettings() {
    return html`
      <section class="card hero">
        <h2>Configuración Global</h2>
        <p>Settings globales: proveedores IA, políticas de modelo, presupuesto, privacidad, seguridad y deuda técnica.</p>
      </section>
      <section class="grid cols-3" style="margin-top:16px">
        <div class="future-card"><h3>Política IA</h3><p>Pendiente: costo, privacidad, precisión, código, documentos, research.</p></div>
        <div class="future-card"><h3>Encriptación</h3><p>Deuda técnica normal / P2.</p></div>
        <div class="future-card"><h3>Presupuesto global</h3><p>Pendiente modelo real de costos.</p></div>
      </section>
    `;
  }

  function renderFuture(title, description) {
    return html`
      <section class="card hero">
        <h2>${title}</h2>
        <p>${description}</p>
      </section>
      <section class="footer-note">
        <b>Future feature / backend pendiente</b>
        <p>No se presenta como funcionalidad operativa real.</p>
      </section>
    `;
  }

  function setRoute(routeName) {
    const route = ROUTES[routeName] || ROUTES["control-tower"];
    document.getElementById("view-layer").textContent = route[0];
    document.getElementById("view-title").textContent = route[1];
    document.getElementById("view-subtitle").textContent = route[2];
    document.getElementById("view-root").innerHTML = route[3]();

    document.querySelectorAll(".nav-item").forEach((button) => {
      button.classList.toggle("is-active", button.dataset.route === routeName);
    });

    window.location.hash = routeName;
  }

  document.addEventListener("click", (event) => {
    const nav = event.target.closest("[data-route]");
    if (nav) {
      setRoute(nav.dataset.route);
      return;
    }
    const projectTarget = event.target.closest("[data-project-id]");
    if (projectTarget) {
      openProject(projectTarget.dataset.projectId);
      return;
    }

    const viewTarget = event.target.closest("[data-portfolio-view]");
    if (viewTarget) {
      portfolioViewMode = viewTarget.dataset.portfolioView;
      setRoute("portfolio");
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

  setRoute(window.location.hash.replace("#", "") || "control-tower");
})();
