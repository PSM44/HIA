(function () {
  "use strict";

  function byId(id) {
    return document.getElementById(id);
  }

  function text(id, value) {
    const el = byId(id);
    if (!el) return;
    el.textContent = value === undefined || value === null || value === "" ? "a"" : String(value);
  }

  function chip(label, value, mode) {
    const span = document.createElement("span");
    span.className = "chip" + (mode ? " " + mode : "");
    span.textContent = label + ": " + value;
    return span;
  }

  function classifyGate(state, debug) {
    const sourceOk = state && state.source === "hia.state.js:HIA_REAL_STATE";
    const candidateOk = debug && debug.candidate_name === "HIA_REAL_STATE";
    const evidenceOk = state && state.evidence === "FRESH";
    const currentOk = state && state.current_state_status === "VALID";

    if (sourceOk && candidateOk && evidenceOk && currentOk) {
      return {
        status: "PASS",
        text: "Portfolio is consuming real HIA state through HIA_UI_STATE.",
        mode: "ok"
      };
    }

    if (state && state.source === "EXPLICIT_FALLBACK") {
      return {
        status: "WARN",
        text: "Portfolio loaded, but source is EXPLICIT_FALLBACK. Do not use as real state.",
        mode: "warn"
      };
    }

    return {
      status: "WARN",
      text: "Portfolio loaded with incomplete validation. Review source labels and warnings.",
      mode: "warn"
    };
  }

  function render() {
    const state = window.HIA_UI_STATE || {};
    const debug = window.HIA_UI_STATE_DEBUG || {};
    const warnings = Array.isArray(state.warnings) ? state.warnings : [];

    text("projectId", state.project_id);
    text("branch", state.branch);
    text("nextAction", state.next_action);
    text("decision", state.decision);
    text("session", state.session);
    text("evidence", state.evidence);
    text("contractVersion", state.contract_version);
    text("source", state.source);
    text("sourceLabel", state.source || "missing");
    text("candidate", debug.candidate_name || "missing");
    text("semanticHash", state.semantic_hash || "N/A");

    const current = byId("currentStateStatus");
    if (current) {
      current.textContent = "current_state_status: " + (state.current_state_status || "UNKNOWN");
      current.className = "chip " + (state.current_state_status === "VALID" ? "ok" : "warn");
    }

    const resolver = byId("resolverStatus");
    if (resolver) {
      resolver.textContent = "resolver_status: " + (state.resolver_status || "UNKNOWN");
      resolver.className = "chip " + (state.resolver_status === "CURRENT_STATE_PRIMARY" ? "ok" : "warn");
    }

    const gate = classifyGate(state, debug);
    const banner = byId("gateBanner");
    if (banner) {
      banner.textContent = gate.status + " a" " + gate.text;
      banner.style.borderColor = gate.mode === "ok" ? "rgba(134,239,172,.45)" : "rgba(253,230,138,.45)";
      banner.style.color = gate.mode === "ok" ? "#bbf7d0" : "#fde68a";
    }

    const chips = byId("gateChips");
    if (chips) {
      chips.innerHTML = "";
      chips.appendChild(chip("source", state.source || "missing", state.source === "hia.state.js:HIA_REAL_STATE" ? "ok" : "warn"));
      chips.appendChild(chip("candidate", debug.candidate_name || "missing", debug.candidate_name === "HIA_REAL_STATE" ? "ok" : "warn"));
      chips.appendChild(chip("evidence", state.evidence || "missing", state.evidence === "FRESH" ? "ok" : "warn"));
      chips.appendChild(chip("contract", state.contract_version || "missing", state.contract_version === "HIA_UI_STATE.v0.2" ? "ok" : "warn"));
    }

    const warn = byId("warnings");
    if (warn) {
      warn.innerHTML = "";
      if (warnings.length === 0) {
        const li = document.createElement("li");
        li.textContent = "No warnings exposed by HIA_UI_STATE.";
        warn.appendChild(li);
      } else {
        warnings.forEach(function (item) {
          const li = document.createElement("li");
          li.textContent = String(item);
          warn.appendChild(li);
        });
      }
    }

    window.HIA_PORTFOLIO_REAL_MINIMUM = Object.freeze({
      rendered_at: new Date().toISOString(),
      gate: gate.status,
      source: state.source,
      candidate_name: debug.candidate_name,
      project_id: state.project_id,
      next_action: state.next_action,
      evidence: state.evidence,
      current_state_status: state.current_state_status,
      resolver_status: state.resolver_status
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", render);
  } else {
    render();
  }
})();
