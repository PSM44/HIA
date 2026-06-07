(function () {
  "use strict";

  const fallback = {
    contract_version: "HIA_UI_STATE.v0.1",
    project_id: "PRJ_0001_HIA.PRODUCT",
    branch: "feat/20260405-console-v2-phase1-phase2",
    next_action: "PRJPB_009Z-R3 — corregir segunda ronda de brechas visuales/narrativas antes de paquete gerencial",
    decision: "NO_GO_WITH_REMEDIATION_2",
    evidence: "FRESH",
    session: "closed",
    source: "EXPLICIT_FALLBACK",
    warnings: ["HIA_UI_STATE was not available when hia.real.app.js loaded"]
  };

  function firstDefined() {
    for (const value of arguments) {
      if (value !== undefined && value !== null && String(value).trim() !== "") return value;
    }
    return undefined;
  }

  function normalizeDecision(value) {
    const v = String(value || "").trim();
    if (!v || v === "NO_GO_REMEDIATION_2" || v === "NO_GO_W_REM_2" || v === "NO_GO_W_REMEDIATION_2") {
      return "NO_GO_WITH_REMEDIATION_2";
    }
    return v;
  }

  function normalizeNext(value) {
    const v = String(value || "").trim();
    if (!v) return fallback.next_action;
    if (v.includes("PRJPB_009Z-R3")) return "PRJPB_009Z-R3 — corregir segunda ronda de brechas visuales/narrativas antes de paquete gerencial";
    return v;
  }

  function getState() {
    const contract = window.HIA_UI_STATE && typeof window.HIA_UI_STATE === "object" ? window.HIA_UI_STATE : null;

    if (!contract) return fallback;

    return {
      contract_version: firstDefined(contract.contract_version, fallback.contract_version),
      project_id: firstDefined(contract.project_id, fallback.project_id),
      branch: firstDefined(contract.branch, fallback.branch),
      next_action: normalizeNext(firstDefined(contract.next_action, fallback.next_action)),
      decision: normalizeDecision(firstDefined(contract.decision, fallback.decision)),
      evidence: firstDefined(contract.evidence, fallback.evidence),
      session: firstDefined(contract.session, fallback.session),
      source: firstDefined(contract.source, "HIA_UI_STATE"),
      resolver_status: firstDefined(contract.resolver_status, "UNKNOWN"),
      current_state_status: firstDefined(contract.current_state_status, "UNKNOWN"),
      semantic_hash: firstDefined(contract.semantic_hash, "N/A"),
      warnings: Array.isArray(contract.warnings) ? contract.warnings : []
    };
  }

  const state = getState();

  function setText(id, value) {
    const node = document.getElementById(id);
    if (node) node.textContent = value || "N/A";
  }

  const next = normalizeNext(state.next_action);
  const decision = normalizeDecision(state.decision);

  setText("activeProject", state.project_id);
  setText("activeNext", next);
  setText("portfolioNext", next);
  setText("projectNext", next);
  setText("activeDecision", decision);
  setText("kpiDecision", decision.includes("NO_GO") ? "NO_GO" : decision);
  setText("kpiEvidence", state.evidence);
  setText("branch", state.branch);
  setText("footerBranch", state.branch);
  setText("evidence", state.evidence);
  setText("session", state.session);

  const breadcrumb = document.getElementById("breadcrumb");
  const scopeBadge = document.getElementById("scopeBadge");

  const views = {
    control: { crumb: "HIA Global > Control Tower", scope: "Scope actual: HIA Global" },
    portfolio: { crumb: "HIA Global > Portfolio", scope: "Scope actual: Portfolio" },
    project: { crumb: "HIA Global > Portfolio > PRJ_0001_HIA.PRODUCT", scope: "Scope actual: Proyecto seleccionado" },
    evidence: { crumb: "HIA Global > Evidence > PRJ_0001_HIA.PRODUCT", scope: "Scope actual: Evidence / Proyecto" },
    settings: { crumb: "HIA Global > Settings", scope: "Scope actual: HIA Global Settings" }
  };

  function activate(viewId) {
    document.querySelectorAll(".view").forEach(v => v.classList.remove("active"));
    document.querySelectorAll(".nav button").forEach(b => b.classList.remove("active"));

    const view = document.getElementById(viewId);
    const nav = document.querySelector(`.nav button[data-view="${viewId}"]`);
    if (view) view.classList.add("active");
    if (nav) nav.classList.add("active");

    if (breadcrumb) breadcrumb.textContent = views[viewId]?.crumb || "";
    if (scopeBadge) scopeBadge.textContent = views[viewId]?.scope || "";
  }

  document.querySelectorAll(".nav button[data-view]").forEach(btn => {
    btn.addEventListener("click", () => activate(btn.dataset.view));
  });

  document.querySelectorAll("[data-view-jump]").forEach(btn => {
    btn.addEventListener("click", () => activate(btn.dataset.viewJump));
  });

  window.HIA_REAL_UI_STATE = state;
})();
