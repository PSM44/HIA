(function () {
  "use strict";

  function byId(id) { return document.getElementById(id); }
  function safe(value) { if (value === undefined || value === null || value === "") return "-"; return String(value); }
  function text(id, value) { var el = byId(id); if (el) el.textContent = safe(value); }
  function chip(label, value, mode) { var span = document.createElement("span"); span.className = "chip" + (mode ? " " + mode : ""); span.textContent = label + ": " + safe(value); return span; }

  function classifyGate(state, debug) {
    var sourceOk = !!state && state.source === "hia.state.js:HIA_REAL_STATE";
    var candidateOk = !!debug && debug.candidate_name === "HIA_REAL_STATE";
    var evidenceOk = !!state && state.evidence === "FRESH";
    var currentOk = !!state && state.current_state_status === "VALID";
    if (sourceOk && candidateOk && evidenceOk && currentOk) return { status: "PASS", text: "Portfolio is consuming real HIA state through HIA_UI_STATE.", mode: "ok" };
    if (state && state.source === "EXPLICIT_FALLBACK") return { status: "WARN", text: "Portfolio loaded, but source is EXPLICIT_FALLBACK. Do not use as real state.", mode: "warn" };
    return { status: "WARN", text: "Portfolio loaded with incomplete validation. Review source labels and warnings.", mode: "warn" };
  }

  function renderProjectsRegistry() {
    var registry = window.HIA_PROJECTS_REAL || null;
    var host = byId("realProjectsRegistry");
    if (!host) return;

    if (!registry || !Array.isArray(registry.projects)) {
      host.textContent = "Project registry missing. No synthetic projects shown.";
      window.HIA_PROJECTS_REAL_VIEW = Object.freeze({ rendered_at: new Date().toISOString(), status: "MISSING", project_count: 0, no_fake_data: true });
      return;
    }

    host.innerHTML = "";
    var summary = document.createElement("div");
    summary.className = "value";
    summary.textContent = String(registry.project_count || registry.projects.length) + " real project(s) from " + String(registry.source || "UNKNOWN");
    host.appendChild(summary);

    var table = document.createElement("table");
    registry.projects.forEach(function (p) {
      var tr = document.createElement("tr");
      var left = document.createElement("td");
      var right = document.createElement("td");
      left.textContent = p.project_id || "UNKNOWN";
      right.innerHTML =
        "<div class='mono'>" + String(p.path || "UNKNOWN") + "</div>" +
        "<div>Evidence: " + String(p.evidence || "UNKNOWN") + " | Session: " + String(p.session || "UNKNOWN") + "</div>" +
        "<div>Next: " + String(p.next_action || "UNKNOWN") + "</div>" +
        "<div class='muted'>Source: " + String(p.source || "UNKNOWN") + "</div>";
      tr.appendChild(left);
      tr.appendChild(right);
      table.appendChild(tr);
    });
    host.appendChild(table);

    window.HIA_PROJECTS_REAL_VIEW = Object.freeze({
      rendered_at: new Date().toISOString(),
      status: "PASS",
      project_count: registry.projects.length,
      source: registry.source || null,
      no_fake_data: registry.no_fake_data === true
    });
  }

  function render() {
    var state = window.HIA_UI_STATE || {};
    var debug = window.HIA_UI_STATE_DEBUG || {};
    var warnings = Array.isArray(state.warnings) ? state.warnings : [];

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

    var current = byId("currentStateStatus");
    if (current) { current.textContent = "current_state_status: " + safe(state.current_state_status || "UNKNOWN"); current.className = "chip " + (state.current_state_status === "VALID" ? "ok" : "warn"); }
    var resolver = byId("resolverStatus");
    if (resolver) { resolver.textContent = "resolver_status: " + safe(state.resolver_status || "UNKNOWN"); resolver.className = "chip " + (state.resolver_status === "CURRENT_STATE_PRIMARY" ? "ok" : "warn"); }

    var gate = classifyGate(state, debug);
    var banner = byId("gateBanner");
    if (banner) { banner.textContent = gate.status + " - " + gate.text; banner.style.borderColor = gate.mode === "ok" ? "rgba(134,239,172,.45)" : "rgba(253,230,138,.45)"; banner.style.color = gate.mode === "ok" ? "#bbf7d0" : "#fde68a"; }

    var chips = byId("gateChips");
    if (chips) {
      chips.innerHTML = "";
      chips.appendChild(chip("source", state.source || "missing", state.source === "hia.state.js:HIA_REAL_STATE" ? "ok" : "warn"));
      chips.appendChild(chip("candidate", debug.candidate_name || "missing", debug.candidate_name === "HIA_REAL_STATE" ? "ok" : "warn"));
      chips.appendChild(chip("evidence", state.evidence || "missing", state.evidence === "FRESH" ? "ok" : "warn"));
      chips.appendChild(chip("contract", state.contract_version || "missing", state.contract_version === "HIA_UI_STATE.v0.2" ? "ok" : "warn"));
    }

    var warn = byId("warnings");
    if (warn) {
      warn.innerHTML = "";
      if (warnings.length === 0) { var li = document.createElement("li"); li.textContent = "No warnings exposed by HIA_UI_STATE."; warn.appendChild(li); }
      else { warnings.forEach(function (item) { var li = document.createElement("li"); li.textContent = String(item); warn.appendChild(li); }); }
    }

    renderProjectsRegistry();

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

  try {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", render);
    else render();
  } catch (err) {
    window.HIA_PORTFOLIO_REAL_MINIMUM_ERROR = String(err && err.stack ? err.stack : err);
    var banner = byId("gateBanner");
    if (banner) { banner.textContent = "FAIL - Portfolio render error. Check window.HIA_PORTFOLIO_REAL_MINIMUM_ERROR."; banner.style.borderColor = "rgba(252,165,165,.45)"; banner.style.color = "#fca5a5"; }
  }
})();