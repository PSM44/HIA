(function () {
  "use strict";

  const RUNTIME_STATE = window.HIA_RUNTIME_STATE || null;

  const STATE = {
    systemName: "HIA",
    projectId: "PRJ_0001_HIA.PRODUCT",
    selectedProjectId: "PRJ_0001_HIA.PRODUCT",
    shellVersion: "v0.2-portfolio",
    repoStatus: "Limpio",
    evidenceStatus: "Disponible",
    architecture: "HTML/CSS/JS sin build, PWA-ready, migrable a Vite/React/Next.",
    currentFocus: "Crear app shell portfolio/client-demo PWA-ready.",
    nextActionHuman: "Generar estado real desde CLI/BATON/RADAR para alimentar la app shell.",
    nextActionCode: "PRJPB_009K",
    portfolioNote: "Demo data controlada: estructura multi-proyecto preparada; falta conexión real a inventario de proyectos.",
    projects: [
      {
        id: "PRJ_0001_HIA.PRODUCT",
        name: "HIA Product",
        status: "active",
        statusLabel: "Activo",
        purpose: "Construir el framework HIA, dashboard, CLI, evidencia y app shell cliente.",
        next: "Generar estado real para la app shell desde CLI/BATON/RADAR.",
        evidence: "FRESH",
        owner: "Human + System"
      },
      {
        id: "PRJ_TEMPLATE_CLIENT",
        name: "Cliente / Proyecto futuro",
        status: "backlog",
        statusLabel: "Backlog",
        purpose: "Placeholder para demostrar que HIA puede administrar múltiples proyectos.",
        next: "Pendiente de alta formal.",
        evidence: "N/A",
        owner: "Por definir"
      },
      {
        id: "PRJ_REPORTING_LAYER",
        name: "Reporting Layer",
        status: "backlog",
        statusLabel: "Feature futura",
        purpose: "Reportes ejecutivos, operativos y técnicos por proyecto y portfolio.",
        next: "Diseñar modelo de reportes.",
        evidence: "N/A",
        owner: "Por definir"
      }
    ],
    futureFeatures: [
      {
        id: "TD_PORTFOLIO_MULTI_PROJECT/P0",
        title: "Portfolio multi-proyecto",
        detail: "Representar HIA como sistema portfolio, no como proyecto único."
      },
      {
        id: "TD_REPORTING_LAYER/P1",
        title: "Reportes",
        detail: "Reportes gerenciales, operativos, técnicos, deuda, RADAR/BATON/BACKLOG y export PDF/PPT/HTML."
      },
      {
        id: "TD_COLLABORATION_LAYER/P1",
        title: "Colaboración",
        detail: "Roles, permisos, comentarios, asignaciones, aprobaciones e historial de decisiones."
      },
      {
        id: "TD_INTEGRATIONS_LAYER/P1",
        title: "Integraciones",
        detail: "GitHub, Drive/OneDrive, Jira/Trello/Planner, Slack/Teams, Calendar, Email, Obsidian y APIs."
      }
    ],
    aiOperatingLayer: {
      activeAI: "ChatGPT / GPT-5.5 Thinking",
      activeMode: "Planning + Review",
      activeRuntime: "Web",
      status: "UI preparada / backend pendiente",
      privacyMode: "Web / no local todavía",
      costMode: "Presupuesto no conectado",
      selectedContext: "PRJ_0001_HIA.PRODUCT + BATON + BACKLOG + RADAR",
      recommendedNext: "Agregar conexión real a estado CLI/BATON/RADAR antes de activar chat real."
    },
    aiProviders: [
      {
        name: "ChatGPT",
        type: "Web",
        status: "Operando en esta conversación",
        recommendedFor: "Planning, review, UX, estrategia, síntesis"
      },
      {
        name: "Codex",
        type: "Cloud / Code agent",
        status: "Disponible futuro",
        recommendedFor: "Cambios de código, refactors, tests"
      },
      {
        name: "Claude",
        type: "Web / Desktop",
        status: "Disponible futuro",
        recommendedFor: "Documentos largos, revisión, escritura"
      },
      {
        name: "OpenCode",
        type: "CLI",
        status: "Disponible futuro",
        recommendedFor: "Ejecución local controlada"
      },
      {
        name: "Local LLM / Ollama",
        type: "Local",
        status: "Pendiente integración",
        recommendedFor: "Privacidad, bajo costo, offline parcial"
      }
    ],
    costControl: {
      sessionBudget: "Pendiente",
      estimatedTokens: "No conectado",
      estimatedCost: "No conectado",
      currentRisk: "Medio: aún sin budget guardrail",
      recommendation: "Usar IA web para planning/review; local para tareas repetitivas cuando esté integrado."
    },
    contextPanel: [
      { label: "Portfolio activo", value: "HIA System / Portfolio" },
      { label: "Proyecto seleccionado", value: "PRJ_0001_HIA.PRODUCT" },
      { label: "BATON", value: "04.0_PROJECT.BATON.txt" },
      { label: "BACKLOG", value: "PROJECT.BACKLOG.txt" },
      { label: "RADAR", value: "Radar.*.ACTIVE.txt" },
      { label: "Fuente canónica", value: "Human + repo artifacts" }
    ],
    debts: [
      {
        id: "TD_FRONTEND_DYNAMIC_STATE/P0",
        title: "Estado real aún no conectado",
        detail: "La UI ya tiene paneles; falta generar/embeber estado real desde CLI/BATON/RADAR."
      },
      {
        id: "TD_PWA_RUNTIME/P1",
        title: "PWA real requiere localhost/HTTPS",
        detail: "file:// sirve para demo local, pero instalación real requiere servidor local o HTTPS."
      },
      {
        id: "TD_CLI_ENCODING_MOJIBAKE/P1",
        title: "Mojibake CLI",
        detail: "La consola aún puede mostrar caracteres corruptos en palabras con tilde."
      }
    ]
  };

  const ROUTES = {
    "client-summary": {
      title: "Resumen para Cliente",
      subtitle: "Qué es HIA como sistema multi-proyecto y qué valor entrega.",
      render: renderClientSummary
    },
    "portfolio": {
      title: "Portfolio HIA",
      subtitle: "Vista de múltiples proyectos, estado global y próximas acciones.",
      render: renderPortfolio
    },
    "active-project": {
      title: "Proyecto activo seleccionado",
      subtitle: "Detalle operacional del proyecto seleccionado dentro del portfolio.",
      render: renderActiveProject
    },
    "ai-cockpit": {
      title: "AI Cockpit",
      subtitle: "Qué IA está operando, en qué modo y con qué contexto.",
      render: renderAICockpit
    },
    "ai-chat": {
      title: "Chat IA",
      subtitle: "Workbench de conversación IA preparado; backend pendiente.",
      render: renderAIChat
    },
    "ai-selector": {
      title: "Selector IA",
      subtitle: "Router de IAs/modelos por costo, privacidad, tarea y runtime.",
      render: renderAISelector
    },
    "cost-control": {
      title: "Costos / Tokens",
      subtitle: "Control de presupuesto, tokens y riesgo de gasto.",
      render: renderCostControl
    },
    "context-panel": {
      title: "Contexto activo",
      subtitle: "Contexto, memoria, handoff y fuentes canónicas.",
      render: renderContextPanel
    },
    "guided-demo": {
      title: "Demo guiada",
      subtitle: "Flujo paso a paso para abrir, revisar y validar la demo.",
      render: renderGuidedDemo
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
    "reports": {
      title: "Reportes",
      subtitle: "Feature futura para reportabilidad ejecutiva, operativa y técnica.",
      render: renderReports
    },
    "collaboration": {
      title: "Colaboración",
      subtitle: "Feature futura para trabajo multiusuario, decisiones y aprobaciones.",
      render: renderCollaboration
    },
    "integrations": {
      title: "Integraciones",
      subtitle: "Feature futura para conectar HIA con aplicaciones externas.",
      render: renderIntegrations
    },
    "tech-debt": {
      title: "Deuda técnica",
      subtitle: "Problemas conocidos y features futuras no ocultas.",
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

  function selectedProject() {
    return STATE.projects.find((project) => project.id === STATE.selectedProjectId) || STATE.projects[0];
  }

  function statusClass(status) {
    if (status === "active") return "active";
    if (status === "demo") return "demo";
    if (status === "blocked") return "blocked";
    return "backlog";
  }

  function renderClientSummary() {
    return html`
      <div class="ribbon client">CLIENTE — Resumen portfolio</div>
      <section class="card hero">
        <h2>Qué es HIA</h2>
        <p><b>HIA es una capa operativa multi-proyecto para trabajar con IA sin perder control.</b> Ordena decisiones humanas, ejecución técnica, evidencia, validación, continuidad y portfolio. No administra solo un proyecto: permite operar varios proyectos con estado, trazabilidad, gobierno común y una capa visible de operación IA.</p>
      </section>

      <div class="grid cols-3" style="margin-top:16px">
        <section class="card">
          <div class="label">Sistema</div>
          <div class="metric ok">Portfolio</div>
          <p>HIA debe ver múltiples proyectos, no solo el proyecto activo seleccionado.</p>
        </section>
        <section class="card">
          <div class="label">Proyecto seleccionado</div>
          <div class="metric warn">${STATE.projectId}</div>
          <p>Este proyecto es el caso actual de construcción de HIA, no todo HIA.</p>
        </section>
        <section class="card">
          <div class="label">Arquitectura</div>
          <div class="metric ok">PWA-ready</div>
          <p>${STATE.architecture}</p>
        </section>
      </div>
    `;
  }

  function renderPortfolio() {
    const active = STATE.projects.filter((p) => p.status === "active").length;
    const backlog = STATE.projects.filter((p) => p.status === "backlog").length;
    return html`
      <div class="ribbon client">CLIENTE — Portfolio HIA</div>
      <section class="portfolio-grid">
        <div class="card">
          <h2>Proyectos</h2>
          <p>${STATE.portfolioNote}</p>
          <div class="project-list" style="margin-top:14px">
            ${STATE.projects.map((project) => `
              <article class="project-card ${project.id === STATE.selectedProjectId ? "is-selected" : ""}">
                <div class="project-card-header">
                  <div>
                    <div class="project-title">${project.name}</div>
                    <div class="project-meta">${project.id}</div>
                  </div>
                  <span class="status-pill ${statusClass(project.status)}">${project.statusLabel}</span>
                </div>
                <p>${project.purpose}</p>
                <div class="project-meta">Siguiente: ${project.next}</div>
              </article>
            `).join("")}
          </div>
        </div>

        <div class="grid">
          <section class="card">
            <div class="label">Total proyectos visibles</div>
            <div class="metric">${STATE.projects.length}</div>
            <p>Demo data controlada hasta conectar inventario real.</p>
          </section>
          <section class="card">
            <div class="label">Activos</div>
            <div class="metric ok">${active}</div>
            <p>Proyectos con trabajo operativo en curso.</p>
          </section>
          <section class="card">
            <div class="label">Backlog / futuros</div>
            <div class="metric warn">${backlog}</div>
            <p>Proyectos o capas futuras registradas.</p>
          </section>
        </div>
      </section>
    `;
  }

  function renderActiveProject() {
    const p = selectedProject();
    return html`
      <div class="ribbon client">CLIENTE — Proyecto activo seleccionado</div>
      <section class="card">
        <h2>${p.name}</h2>
        <p>${p.purpose}</p>
        <div class="grid cols-3" style="margin-top:16px">
          <div class="step current">
            <div class="label">Estado</div>
            <h3>${p.statusLabel}</h3>
            <p>Proyecto seleccionado dentro del portfolio.</p>
          </div>
          <div class="step next">
            <div class="label">Siguiente acción</div>
            <h3>${p.next}</h3>
            <p>Código interno visible solo como trazabilidad: ${STATE.nextActionCode}.</p>
          </div>
          <div class="step later">
            <div class="label">Evidencia</div>
            <h3>${p.evidence}</h3>
            <p>Estado de respaldo operacional del proyecto.</p>
          </div>
        </div>
      </section>
    `;
  }


  function renderAICockpit() {
    const ai = STATE.aiOperatingLayer;
    return html`
      <div class="ribbon dev">AI OPERATING LAYER — Cockpit IA</div>
      <section class="card">
        <h2>AI Cockpit</h2>
        <p>Esta vista muestra la operación IA. Hoy es UI preparada; la conexión real con backend/modelos queda pendiente.</p>
        <div class="ai-kpi" style="margin-top:16px">
          <div class="ai-kpi-item">
            <div class="label">IA activa</div>
            <div class="ai-kpi-value">${ai.activeAI}</div>
          </div>
          <div class="ai-kpi-item">
            <div class="label">Modo</div>
            <div class="ai-kpi-value">${ai.activeMode}</div>
          </div>
          <div class="ai-kpi-item">
            <div class="label">Runtime</div>
            <div class="ai-kpi-value">${ai.activeRuntime}</div>
          </div>
          <div class="ai-kpi-item">
            <div class="label">Estado</div>
            <div class="ai-kpi-value warn">${ai.status}</div>
          </div>
        </div>
      </section>

      <section class="ai-grid" style="margin-top:16px">
        <div class="card">
          <h2>Modo operacional</h2>
          <div class="grid cols-2">
            <div class="ai-card is-primary"><h3>Planning</h3><p>Definir camino, riesgos, alcance y siguiente acción.</p></div>
            <div class="ai-card"><h3>Execution</h3><p>Ejecutar cambios vía scripts, repo y artifacts.</p></div>
            <div class="ai-card"><h3>Review / QA</h3><p>Validar, detectar fallas y registrar NO_GO si corresponde.</p></div>
            <div class="ai-card"><h3>Cost Saving</h3><p>Elegir modelo/runtime según costo, privacidad y complejidad.</p></div>
          </div>
        </div>
        <div class="card">
          <h2>Contexto seleccionado</h2>
          <p>${ai.selectedContext}</p>
          <div class="backend-note" style="margin-top:14px">
            Backend pendiente: esta pantalla todavía no invoca IA directamente ni mide tokens reales.
          </div>
        </div>
      </section>
    `;
  }

  function renderAIChat() {
    return html`
      <div class="ribbon dev">AI OPERATING LAYER — Chat IA / Workbench</div>
      <section class="chat-shell">
        <div class="chat-header">
          <h2>Chat IA</h2>
          <p>Workbench preparado para conversación con IA. No envía prompts todavía: backend pendiente.</p>
        </div>
        <div class="chat-messages">
          <div class="msg user"><b>Humano</b><p>Necesito avanzar el proyecto sin perder contexto ni control de costos.</p></div>
          <div class="msg ai"><b>IA</b><p>UI placeholder: aquí se mostrará respuesta IA, decisiones, tareas propuestas y acciones hacia backlog/evidencia.</p></div>
          <div class="backend-note">Estado: UI preparada / backend pendiente. No simula llamada real a modelo.</div>
        </div>
        <div class="chat-input">
          <input type="text" value="" placeholder="Escribe prompt futuro aquí..." disabled>
          <button class="secondary-btn" disabled>Enviar a IA</button>
        </div>
      </section>

      <section class="card" style="margin-top:16px">
        <h2>Acciones futuras del workbench</h2>
        <div class="action-row">
          <button class="secondary-btn" disabled>Guardar decisión</button>
          <button class="secondary-btn" disabled>Crear tarea</button>
          <button class="secondary-btn" disabled>Enviar a backlog</button>
          <button class="secondary-btn" disabled>Escalar a otra IA</button>
        </div>
      </section>
    `;
  }

  function renderAISelector() {
    return html`
      <div class="ribbon dev">AI OPERATING LAYER — Selector / Router IA</div>
      <section class="card">
        <h2>Selector IA</h2>
        <p>Router preparado para elegir IA según costo, privacidad, precisión, tarea y runtime. No ejecuta selección real todavía.</p>
        <div class="selector-grid" style="margin-top:16px">
          ${STATE.aiProviders.map((provider, index) => `
            <div class="model-card ${index === 0 ? "recommended" : ""}">
              <div class="label">${provider.type}</div>
              <h3>${provider.name}</h3>
              <p>${provider.recommendedFor}</p>
              <div class="project-meta">Estado: ${provider.status}</div>
            </div>
          `).join("")}
        </div>
      </section>
    `;
  }

  function renderCostControl() {
    const cost = STATE.costControl;
    return html`
      <div class="ribbon debt">AI OPERATING LAYER — Costos / Tokens</div>
      <section class="card">
        <h2>Control de costos</h2>
        <p>HIA no puede prometer control si no controla tokens, modelos y presupuesto. Esta vista deja el espacio de governance preparado.</p>
        <div class="ai-kpi" style="margin-top:16px">
          <div class="ai-kpi-item"><div class="label">Budget sesión</div><div class="ai-kpi-value">${cost.sessionBudget}</div></div>
          <div class="ai-kpi-item"><div class="label">Tokens</div><div class="ai-kpi-value">${cost.estimatedTokens}</div></div>
          <div class="ai-kpi-item"><div class="label">Costo</div><div class="ai-kpi-value">${cost.estimatedCost}</div></div>
          <div class="ai-kpi-item"><div class="label">Riesgo</div><div class="ai-kpi-value warn">${cost.currentRisk}</div></div>
        </div>
        <div class="cost-bar"><div class="cost-bar-fill"></div></div>
        <div class="backend-note" style="margin-top:14px">${cost.recommendation}</div>
      </section>
    `;
  }

  function renderContextPanel() {
    return html`
      <div class="ribbon evidence">AI OPERATING LAYER — Contexto / Memory / Handoff</div>
      <section class="card">
        <h2>Contexto activo</h2>
        <p>Panel preparado para mostrar qué contexto usa la IA antes de responder o ejecutar.</p>
        <div class="context-list" style="margin-top:16px">
          ${STATE.contextPanel.map((item) => `
            <div class="context-item">
              <div class="label">${item.label}</div>
              <h3>${item.value}</h3>
            </div>
          `).join("")}
        </div>
      </section>
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
            <p>HIA es portfolio multi-proyecto con gobierno, evidencia y continuidad.</p>
          </div>
          <div class="step next">
            <div class="label">Paso 2</div>
            <h3>Revisa portfolio</h3>
            <p>Ver proyectos, estados y siguientes acciones.</p>
          </div>
          <div class="step later">
            <div class="label">Paso 3</div>
            <h3>Valida proyecto activo</h3>
            <p>Entrar al detalle del proyecto seleccionado y revisar evidencia.</p>
          </div>
        </div>
      </section>

      <div class="ribbon qa">QA — Checklist interactivo</div>
      <section class="card">
        <h2>Smoke como cliente</h2>
        <div class="checklist">
          ${[
            "Entiendo que HIA administra múltiples proyectos.",
            "Entiendo cuál es el proyecto activo seleccionado.",
            "Entiendo que reportes, colaboración e integraciones son features futuras.",
            "Puedo navegar sin recargar.",
            "Puedo distinguir Cliente, Dev, QA, Evidencia y Deuda.",
            "No se presentan métricas falsas como reales."
          ].map((item, index) => `<label class="check-item"><input type="checkbox" data-check="${index}"><span>${item}</span></label>`).join("")}
        </div>
      </section>
    `;
  }

  function renderRealStatus() {
    return html`
      <div class="ribbon dev">DEV UX/UI — Estado visible en UI</div>
      <section class="card">
        <h2>Estado real del sistema</h2>
        <p>Hoy este panel usa estado embebido demo/controlado. El siguiente incremento debe generarlo desde CLI/BATON/RADAR.</p>
        <table class="table" style="margin-top:14px">
          <thead><tr><th>Campo</th><th>Estado mostrado</th><th>Fuente futura</th></tr></thead>
          <tbody>
            <tr><td>Sistema</td><td>${STATE.systemName}</td><td>System registry</td></tr>
            <tr><td>Portfolio</td><td>${STATE.projects.length} proyectos visibles</td><td>Project registry / filesystem</td></tr>
            <tr><td>Proyecto seleccionado</td><td>${STATE.selectedProjectId}</td><td>UI state / route param</td></tr>
            <tr><td>Repo</td><td>${STATE.repoStatus}</td><td>git status</td></tr>
            <tr><td>Evidencia</td><td>${STATE.evidenceStatus}</td><td>project continue / resolver</td></tr>
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
        <p>La evidencia debe respaldar tanto el portfolio como cada proyecto.</p>
        <div class="grid cols-3" style="margin-top:16px">
          <div class="step"><h3>Git</h3><p>Commits y push respaldan cambios del sistema.</p></div>
          <div class="step"><h3>RADAR</h3><p>Inventario y freshness de archivos.</p></div>
          <div class="step"><h3>Artifacts</h3><p>Reportes de MiniBattles y feedback humano.</p></div>
        </div>
      </section>
    `;
  }

  function renderReports() {
    return html`
      <div class="ribbon evidence">REPORTING — Feature futura</div>
      <section class="card">
        <h2>Reportes</h2>
        <p>Capa futura para reportabilidad ejecutiva, operativa y técnica.</p>
        <div class="feature-grid" style="margin-top:16px">
          <div class="future-card"><h3>Reporte portfolio</h3><p>Vista ejecutiva de múltiples proyectos.</p></div>
          <div class="future-card"><h3>Reporte por proyecto</h3><p>Estado, avances, bloqueos, evidencia y deuda.</p></div>
          <div class="future-card"><h3>Exportables</h3><p>PDF, PPT, HTML y otros formatos.</p></div>
        </div>
      </section>
    `;
  }

  function renderCollaboration() {
    return html`
      <div class="ribbon qa">COLLABORATION — Feature futura</div>
      <section class="card">
        <h2>Trabajo colaborativo</h2>
        <p>Capa futura para trabajo humano/equipo/IA con trazabilidad.</p>
        <div class="feature-grid" style="margin-top:16px">
          <div class="future-card"><h3>Roles y permisos</h3><p>Cliente, owner, developer, QA, auditor.</p></div>
          <div class="future-card"><h3>Comentarios y aprobaciones</h3><p>Decisiones, feedback y gates humanos.</p></div>
          <div class="future-card"><h3>Asignaciones</h3><p>Responsables por acción, deuda o evidencia.</p></div>
        </div>
      </section>
    `;
  }

  function renderIntegrations() {
    return html`
      <div class="ribbon dev">INTEGRATIONS — Feature futura</div>
      <section class="card">
        <h2>Integraciones</h2>
        <p>Capa futura para conectar HIA con herramientas externas.</p>
        <div class="feature-grid" style="margin-top:16px">
          <div class="future-card"><h3>Repositorios</h3><p>GitHub y proveedores Git.</p></div>
          <div class="future-card"><h3>Productividad</h3><p>Drive, OneDrive, Calendar, Email, Teams, Slack.</p></div>
          <div class="future-card"><h3>Gestión</h3><p>Jira, Trello, Planner, Obsidian y APIs internas.</p></div>
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
          ${STATE.futureFeatures.concat(STATE.debts).map((debt) => `
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
          <p>Usa este comando primero. Abre la interfaz navegable portfolio/cliente.</p>
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
