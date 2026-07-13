/*
===============================================================================
FILE..............: hia.project.workspace.real.js
PROJECT...........: PRJ_0001_HIA.PRODUCT
MINIBATTLE........: PRJPB_010N
PURPOSE...........: Expose real read-only Project Workspace contract.
GLOBAL............: window.HIA_PROJECT_WORKSPACE_REAL
SOURCE............: CURRENT_STATE + BATON + BACKLOG + DELIVERY + Git
NO_FAKE_DATA......: YES
===============================================================================
*/

window.HIA_PROJECT_WORKSPACE_REAL = Object.freeze({
  "schema": "HIA_PROJECT_WORKSPACE_REAL.v0.1",
  "generated_local": "2026-07-12 22:37:24 -04:00",
  "generated_utc": "2026-07-13T02:37:24.4782289Z",
  "mode": "READ_ONLY",
  "no_fake_data": true,
  "source_contract": {
    "primary": "STATE/CURRENT_STATE.json",
    "supporting": [
      "BATON/04.0_PROJECT.BATON.txt",
      "AGILE/PROJECT.BACKLOG.txt",
      "DELIVERY",
      "git"
    ],
    "generator": "HIA_PRJPB_010N_IMPLEMENT_PROJECT_WORKSPACE_R2.ps1"
  },
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "head": "396bb4457ef1c5540aa29357bc8b3a8ae3b23732",
    "head_short": "396bb44"
  },
  "continuity": {
    "current_objective": "Session closed after PRJPB_010M. Next slice is Project Workspace real minimum.",
    "next_action": "PRJPB_010N | implementar Project Workspace real minimum read-only desde evidencia del proyecto | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "write_mode": "READ_ONLY"
  },
  "product_state": {
    "control_tower": "DONE",
    "portfolio": "DONE",
    "navigation": "DONE",
    "real_project_registry": "DONE_BROWSER_VALIDATED",
    "project_workspace": "NEXT",
    "management_demo": "NOT_READY_UNTIL_PROJECT_WORKSPACE"
  },
  "counts": {
    "technical_debt": 1,
    "backlog": 1,
    "ideas": 1,
    "deliveries_shown": 12
  },
  "technical_debt": [
    "TD-010Z-005 | OPEN | Multi-proyecto esta en registry real minimo con 1 proyecto; falta seleccion/interaccion de proyecto y escalamiento a multiples proyectos reales."
  ],
  "backlog": [
    "BL-010S | PLANNED | Convertir aprendizajes de Temp/RunDir y dirty whitelist en candidato Skill/GRC reusable."
  ],
  "ideas": [
    "IDEA-005 | Usar Project Workspace como puente a gerencia: estado, evidencia, riesgo, siguiente decision, no solo backlog tecnico."
  ],
  "latest_deliveries": [
    {
      "name": "PRJPB_010Z-R2.SESSION_CLOSE.20260711_223547.txt",
      "bytes": 10159,
      "modified_local": "2026-07-11 22:35:47 -04:00"
    },
    {
      "name": "PRJPB_010M.DEFINE_NEXT_FUNCTIONAL_SLICE.20260711_220458.txt",
      "bytes": 2341,
      "modified_local": "2026-07-11 22:04:58 -04:00"
    },
    {
      "name": "PRJPB_010L.FORMALIZE_REAL_PROJECT_REGISTRY_VALIDATION.20260711_215343.txt",
      "bytes": 1346,
      "modified_local": "2026-07-11 21:53:43 -04:00"
    },
    {
      "name": "PRJPB_010K-R3.IMPLEMENT_REAL_PROJECT_REGISTRY.20260711_214412.txt",
      "bytes": 1342,
      "modified_local": "2026-07-11 21:44:12 -04:00"
    },
    {
      "name": "PRJPB_010J.DEFINE_REAL_MULTIPROJECT_SLICE.20260711_212153.txt",
      "bytes": 1705,
      "modified_local": "2026-07-11 21:21:54 -04:00"
    },
    {
      "name": "PRJPB_010I.FORMALIZE_NAV_BROWSER_VALIDATION.20260711_211800.txt",
      "bytes": 1852,
      "modified_local": "2026-07-11 21:18:00 -04:00"
    },
    {
      "name": "PRJPB_010H.CONTROL_TOWER_PORTFOLIO_NAVIGATION.20260711_133137.txt",
      "bytes": 1309,
      "modified_local": "2026-07-11 13:31:37 -04:00"
    },
    {
      "name": "PRJPB_010G.REFRESH_STATE_RADAR_POST_PORTFOLIO.20260711_124531.txt",
      "bytes": 1024,
      "modified_local": "2026-07-11 12:46:26 -04:00"
    },
    {
      "name": "PRJPB_010F-R4.REWRITE_PORTFOLIO_ASCII_CLEAN.20260711_123721.txt",
      "bytes": 1246,
      "modified_local": "2026-07-11 12:37:22 -04:00"
    },
    {
      "name": "PRJPB_010F-R3.PORTFOLIO_BROWSER_VALIDATION_ENCODING_FIX.20260711_122659.txt",
      "bytes": 1155,
      "modified_local": "2026-07-11 12:26:59 -04:00"
    },
    {
      "name": "PRJPB_010E.PORTFOLIO_REAL_MINIMUM.20260711_115703.txt",
      "bytes": 1163,
      "modified_local": "2026-07-11 11:57:03 -04:00"
    },
    {
      "name": "PRJPB_010D.REFRESH_CURRENT_STATE_RADAR_CLEAN_CLOSE.20260711_011430.txt",
      "bytes": 1399,
      "modified_local": "2026-07-11 01:14:31 -04:00"
    }
  ],
  "missing_or_not_integrated": [
    "Project costs are not integrated.",
    "Project AI/chat backend is not integrated.",
    "Human decision register is not normalized into a dedicated workspace contract.",
    "Strict final-HEAD RADAR freshness is not guaranteed.",
    "Browser validation is pending PRJPB_010O."
  ],
  "validation": {
    "source_files_exist": true,
    "only_real_project": true,
    "write_actions_exposed": false,
    "browser_validation_status": "PENDING_PRJPB_010O",
    "implementation_gate": "PASS_STATIC"
  }
});

(function () {
  "use strict";

  const workspace = window.HIA_PROJECT_WORKSPACE_REAL;
  const byId = (id) => document.getElementById(id);
  const text = (value, fallback) => {
    if (value === undefined || value === null || String(value).trim() === "") {
      return fallback || "Not available";
    }
    return String(value);
  };
  const escapeHtml = (value) => text(value, "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");

  function renderList(targetId, items, emptyText) {
    const target = byId(targetId);
    if (!target) return;
    if (!Array.isArray(items) || items.length === 0) {
      target.innerHTML = `<li class="muted">${escapeHtml(emptyText || "No records found")}</li>`;
      return;
    }
    target.innerHTML = items.map((item) => `<li>${escapeHtml(item)}</li>`).join("");
  }

  function renderDeliveries() {
    const target = byId("deliveryRows");
    if (!target) return;
    const items = Array.isArray(workspace.latest_deliveries) ? workspace.latest_deliveries : [];
    if (items.length === 0) {
      target.innerHTML = `<tr><td colspan="3" class="muted">No delivery evidence found.</td></tr>`;
      return;
    }
    target.innerHTML = items.map((item) => `
      <tr>
        <td class="mono">${escapeHtml(item.name)}</td>
        <td>${escapeHtml(item.modified_local)}</td>
        <td class="mono">${escapeHtml(item.bytes)}</td>
      </tr>
    `).join("");
  }

  function render() {
    byId("projectId").textContent = text(workspace.project.id);
    byId("branch").textContent = text(workspace.project.branch);
    byId("head").textContent = text(workspace.project.head_short);
    byId("objective").textContent = text(workspace.continuity.current_objective);
    byId("nextAction").textContent = text(workspace.continuity.next_action);
    byId("evidence").textContent = `${text(workspace.continuity.evidence_state)} / ${text(workspace.continuity.evidence_consistency)}`;
    byId("session").textContent = text(workspace.continuity.session_status);
    byId("writeMode").textContent = text(workspace.continuity.write_mode);
    byId("sourcePrimary").textContent = text(workspace.source_contract.primary);
    byId("generated").textContent = text(workspace.generated_local);

    byId("debtCount").textContent = text(workspace.counts.technical_debt, "0");
    byId("backlogCount").textContent = text(workspace.counts.backlog, "0");
    byId("ideaCount").textContent = text(workspace.counts.ideas, "0");
    byId("deliveryCount").textContent = text(workspace.counts.deliveries_shown, "0");

    renderList("debtList", workspace.technical_debt, "No technical debt records found.");
    renderList("backlogList", workspace.backlog, "No backlog records found.");
    renderList("missingList", workspace.missing_or_not_integrated, "No missing-data declarations.");
    renderDeliveries();

    const gate = byId("gateBanner");
    gate.textContent = "PASS_STATIC - Real Project Workspace contract loaded. Browser validation pending PRJPB_010O.";
    gate.classList.add("pass");

    window.HIA_PROJECT_WORKSPACE_REAL_VIEW = Object.freeze({
      status: "PASS_STATIC",
      source: workspace.source_contract.primary,
      project_id: workspace.project.id,
      no_fake_data: workspace.no_fake_data,
      write_mode: workspace.mode,
      browser_validation_status: workspace.validation.browser_validation_status
    });
  }

  render();
})();