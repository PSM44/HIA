(function () {
  "use strict";

  const fallback = {
    project_id: "PRJ_0001_HIA.PRODUCT",
    branch: "feat/20260405-console-v2-phase1-phase2",
    next_action: "PRJPB_009Z-R3 — corregir segunda ronda de brechas visuales/narrativas antes de paquete gerencial",
    decision: "NO_GO_WITH_REMEDIATION_2",
    evidence: "FRESH",
    session: "closed",
    source: "EXPLICIT_FALLBACK"
  };

  function firstDefined(...values) {
    for (const value of values) {
      if (value !== undefined && value !== null && String(value).trim() !== "") return value;
    }
    return undefined;
  }

  function discoverState() {
    const candidates = [
      window.HIA_STATE,
      window.hiaState,
      window.__HIA_STATE__,
      window.HIA_CONTROL_TOWER_STATE,
      window.HIA_STATE_SNAPSHOT,
      window.hia_state,
      window.HIA
    ].filter(Boolean);

    const raw = candidates[0] || {};
    const current = raw.current_state || raw.currentState || raw.state || raw.project || raw;

    const nextObj = current.next_action || current.nextAction || raw.next_action || raw.nextAction || {};
    const evidenceObj = current.evidence || raw.evidence || {};
    const sessionObj = current.session || raw.session || {};
    const gitObj = current.git || raw.git || {};

    const nextText = firstDefined(
      typeof nextObj === "string" ? nextObj : undefined,
      nextObj.text,
      nextObj.raw,
      nextObj.title && nextObj.id ? `${nextObj.id} — ${nextObj.title}` : undefined,
      raw.next_action,
      raw.nextAction,
      current.next_action,
      current.nextAction
    );

    return {
      project_id: firstDefined(current.project_id, current.projectId, raw.project_id, raw.projectId, fallback.project_id),
      branch: firstDefined(current.branch, gitObj.branch, raw.branch, fallback.branch),
      next_action: firstDefined(nextText, fallback.next_action),
      decision: firstDefined(current.decision, current.human_decision, raw.decision, raw.human_decision, fallback.decision),
      evidence: firstDefined(evidenceObj.state, current.evidence_state, raw.evidence_state, raw.evidenceState, fallback.evidence),
      session: firstDefined(sessionObj.status, current.last_session_status, raw.last_session_status, raw.session_status, fallback.session),
      source: candidates[0] ? "HIA_STATE_JS_DISCOVERED" : fallback.source
    };
  }

  const state = discoverState();

  function setText(id, value) {
    const node = document.getElementById(id);
    if (node) node.textContent = value || "N/A";
  }

  function normalizeDecision(value) {
    const v = String(value || "").trim();
    if (!v || v === "NO_GO_REMEDIATION_2" || v === "NO_GO_W_REM_2") return "NO_GO_WITH_REMEDIATION_2";
    return v;
  }

  function normalizeNext(value) {
    const v = String(value || "").trim();
    if (v.includes("PRJPB_009Z-R3")) return v;
    return fallback.next_action;
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
