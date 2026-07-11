/*
===============================================================================
FILE..............: hia.ui.contract.js
PROJECT...........: PRJ_0001_HIA.PRODUCT
PURPOSE...........: Normalize hia.state.js output into one stable UI contract.
CONTRACT..........: window.HIA_UI_STATE
MODE..............: read-only browser contract
RULE..............: hia.real.app.js must consume HIA_UI_STATE first, not guess directly.
===============================================================================
*/

(function () {
  "use strict";

  const FALLBACK = {
    contract_version: "HIA_UI_STATE.v0.2",
    project_id: "PRJ_0001_HIA.PRODUCT",
    branch: "feat/20260405-console-v2-phase1-phase2",
    next_action: "PRJPB_009Z-R3 — corregir segunda ronda de brechas visuales/narrativas antes de paquete gerencial",
    decision: "NO_GO_WITH_REMEDIATION_2",
    evidence: "FRESH",
    session: "closed",
    resolver_status: "EXPLICIT_FALLBACK",
    current_state_status: "UNKNOWN",
    source: "EXPLICIT_FALLBACK",
    warnings: ["hia.state.js did not expose a recognized object contract"]
  };

  function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function firstDefined() {
    for (const value of arguments) {
      if (value !== undefined && value !== null && String(value).trim() !== "") return value;
    }
    return undefined;
  }

  function normalizeNoGo(value) {
    const raw = String(value || "").trim();
    if (!raw) return FALLBACK.decision;
    if (raw === "NO_GO_REMEDIATION_2" || raw === "NO_GO_W_REM_2" || raw === "NO_GO_W_REMEDIATION_2") {
      return "NO_GO_WITH_REMEDIATION_2";
    }
    return raw;
  }

  function normalizeNextAction(value) {
    const raw = String(value || "").trim();

    if (!raw) return FALLBACK.next_action;

    if (raw.includes("PRJPB_009Z-R3")) {
      return "PRJPB_009Z-R3 — corregir segunda ronda de brechas visuales/narrativas antes de paquete gerencial";
    }

    if (raw.includes("PRJPB_009Z-R2")) {
      return raw;
    }

    return raw;
  }

  function extractCandidate() {
    const candidates = [
      ["HIA_REAL_STATE", window.HIA_REAL_STATE],
      ["HIA_STATE", window.HIA_STATE],
      ["hiaState", window.hiaState],
      ["__HIA_STATE__", window.__HIA_STATE__],
      ["HIA_CONTROL_TOWER_STATE", window.HIA_CONTROL_TOWER_STATE],
      ["HIA_STATE_SNAPSHOT", window.HIA_STATE_SNAPSHOT],
      ["hia_state", window.hia_state],
      ["HIA", window.HIA]
    ].filter((entry) => isObject(entry[1]));

    if (candidates.length === 0) {
      return { name: null, raw: {} };
    }

    return { name: candidates[0][0], raw: candidates[0][1] };
  }

  function pickStateRoot(raw) {
    if (!isObject(raw)) return {};
    if (raw.project || raw.continuity || raw.git || raw.radar || raw.ui) return raw;
    return raw.current_state || raw.currentState || raw.state || raw.project || raw;
  }

  function normalize(candidate) {
    const raw = candidate.raw || {};
    const root = pickStateRoot(raw);
    const projectObj = isObject(raw.project) ? raw.project : {};
    const continuityObj = isObject(raw.continuity) ? raw.continuity : {};

    const nextObj = firstDefined(root.next_action, root.nextAction, raw.next_action, raw.nextAction, continuityObj.next_action);
    const evidenceObj = firstDefined(root.evidence, raw.evidence, {});
    const sessionObj = firstDefined(root.session, raw.session, {});
    const gitObj = firstDefined(root.git, raw.git, {});

    const nextActionText = firstDefined(
      typeof nextObj === "string" ? nextObj : undefined,
      isObject(nextObj) ? nextObj.text : undefined,
      isObject(nextObj) ? nextObj.raw : undefined,
      isObject(nextObj) && nextObj.id && nextObj.title ? `${nextObj.id} — ${nextObj.title}` : undefined,
      raw.next_action,
      raw.nextAction,
      root.next_action,
      root.nextAction
    );

    const decision = firstDefined(
      root.decision,
      root.human_decision,
      root.humanDecision,
      raw.decision,
      raw.human_decision,
      raw.humanDecision,
      FALLBACK.decision
    );

    const normalized = {
      contract_version: "HIA_UI_STATE.v0.2",
      project_id: firstDefined(projectObj.id, root.project_id, root.projectId, raw.project_id, raw.projectId, FALLBACK.project_id),
      branch: firstDefined(projectObj.branch, root.branch, gitObj.branch, raw.branch, FALLBACK.branch),
      next_action: normalizeNextAction(firstDefined(nextActionText, FALLBACK.next_action)),
      decision: normalizeNoGo(decision),
      evidence: firstDefined(
        continuityObj.evidence_state,
        evidenceObj.state,
        root.evidence_state,
        root.evidenceState,
        raw.evidence_state,
        raw.evidenceState,
        FALLBACK.evidence
      ),
      session: firstDefined(
        continuityObj.session_status,
        sessionObj.status,
        root.last_session_status,
        root.session_status,
        raw.last_session_status,
        raw.session_status,
        FALLBACK.session
      ),
      resolver_status: firstDefined(continuityObj.resolver_status, root.resolver_status, raw.resolver_status, root.resolverStatus, raw.resolverStatus, "UNKNOWN"),
      current_state_status: firstDefined(continuityObj.current_state_status, root.current_state_status, raw.current_state_status, root.currentStateStatus, raw.currentStateStatus, "UNKNOWN"),
      semantic_hash: firstDefined(root.semantic_hash, raw.semantic_hash, root.SEMANTIC_HASH, raw.SEMANTIC_HASH, "N/A"),
      source: candidate.name ? `hia.state.js:${candidate.name}` : FALLBACK.source,
      warnings: []
    };

    if (!candidate.name) normalized.warnings.push("No recognized hia.state.js global variable found");
    if (normalized.next_action.includes("PRJPB_009Z-R2")) normalized.warnings.push("NEXT_ACTION still points to PRJPB_009Z-R2; expected PRJPB_009Z-R3 for current UX remediation path");
    if (normalized.current_state_status === "UNKNOWN") normalized.warnings.push("current_state_status unavailable in normalized contract");
    if (normalized.resolver_status === "UNKNOWN") normalized.warnings.push("resolver_status unavailable in normalized contract");

    return normalized;
  }

  const candidate = extractCandidate();
  window.HIA_UI_STATE = normalize(candidate);

  window.HIA_UI_STATE_DEBUG = {
    candidate_name: candidate.name,
    candidate_keys: candidate.raw && typeof candidate.raw === "object" ? Object.keys(candidate.raw) : [],
    contract: window.HIA_UI_STATE
  };
})();

