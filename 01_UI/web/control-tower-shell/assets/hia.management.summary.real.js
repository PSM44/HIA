(() => {
  "use strict";

  const state = window.HIA_REAL_STATE || {};
  const readiness = window.HIA_MANAGEMENT_READINESS || {};
  const model = window.HIA_PROJECT_WORKSPACE_MODEL || {};

  const text = (value, fallback = "Not available") => {
    if (value === null || value === undefined || value === "") return fallback;
    return String(value);
  };

  const list = (items) => {
    if (!Array.isArray(items) || items.length === 0) {
      return "<li>None recorded.</li>";
    }
    return items.map((item) => `<li>${text(item)}</li>`).join("");
  };

  const observations = Array.isArray(readiness.observations)
    ? readiness.observations
    : [];

  const gates = readiness.gates || {};
  const gateRows = Object.entries(gates).map(([key, value]) => {
    const status = text(value?.status, "UNKNOWN");
    const css = status === "PASS"
      ? "status-pass"
      : status === "PENDING"
        ? "status-pending"
        : "";
    return `
      <div class="gate">
        <span>${key.replaceAll("_", " ")}</span>
        <strong class="${css}">${status}</strong>
      </div>`;
  }).join("");

  const nextAction =
    state?.continuity?.next_action ||
    readiness?.next_slice?.title ||
    "Not available";

  const objective =
    state?.product_state?.current_objective ||
    state?.continuity?.current_objective ||
    "See CURRENT_STATE source.";

  const projectId =
    state?.project?.id ||
    readiness?.project_id ||
    "UNKNOWN_PROJECT";

  const managementStatus =
    readiness?.readiness?.management_demo ||
    "UNKNOWN";

  const modelStatus =
    model?.validation?.gate ||
    "UNKNOWN";

  const root = document.getElementById("management-summary-root");
  if (!root) {
    throw new Error("MANAGEMENT_SUMMARY_ROOT_NOT_FOUND");
  }

  root.innerHTML = `
    <section class="grid">
      <article class="card third">
        <h2>Project</h2>
        <p class="value">${text(projectId)}</p>
        <p class="meta">${text(state?.project?.branch, "Branch unavailable")}</p>
      </article>

      <article class="card third">
        <h2>Management readiness</h2>
        <p class="value">${text(managementStatus)}</p>
        <p class="meta">${text(readiness?.readiness?.reason)}</p>
      </article>

      <article class="card third">
        <h2>Workspace evidence model</h2>
        <p class="value">${text(modelStatus)}</p>
        <p class="meta">${text(model?.schema)}</p>
      </article>

      <article class="card">
        <h2>Current objective</h2>
        <p>${text(objective)}</p>
      </article>

      <article class="card">
        <h2>Next action</h2>
        <p>${text(nextAction)}</p>
      </article>

      <article class="card">
        <h2>Known observations</h2>
        <ul>
          ${observations.length
            ? observations.map((item) =>
                `<li><strong>${text(item.id)}</strong> — ${text(item.text)}</li>`
              ).join("")
            : "<li>None recorded.</li>"}
        </ul>
      </article>

      <article class="card">
        <h2>Evidence references</h2>
        <ul>
          ${list([
            "CURRENT_STATE.json",
            "BATON operational continuity",
            "PROJECT.BACKLOG planned work and debt",
            "DELIVERY execution evidence",
            "Git repository state"
          ])}
        </ul>
      </article>

      <article class="card wide">
        <h2>Readiness gates</h2>
        ${gateRows || "<p>No gates available.</p>"}
      </article>

      <article class="card">
        <h2>Boundaries</h2>
        <ul>${list(readiness?.definition?.ready_does_not_mean)}</ul>
      </article>

      <article class="card">
        <h2>Controls</h2>
        <dl>
          <dt>Write mode</dt>
          <dd>${text(readiness?.validation?.write_mode)}</dd>
          <dt>No fake data</dt>
          <dd>${readiness?.no_fake_data === true ? "PASS" : "FAIL"}</dd>
          <dt>HUMAN policy</dt>
          <dd>${text(model?.sources?.human?.duplication_policy)}</dd>
          <dt>Production readiness</dt>
          <dd>NOT CLAIMED</dd>
        </dl>
      </article>
    </section>
  `;

  window.HIA_MANAGEMENT_SUMMARY_REAL = Object.freeze({
    schema: "HIA_MANAGEMENT_SUMMARY_REAL.v0.1",
    project_id: projectId,
    management_readiness: managementStatus,
    model_gate: modelStatus,
    next_action: nextAction,
    observations_count: observations.length,
    read_only: readiness?.validation?.write_mode === "READ_ONLY",
    no_fake_data: readiness?.no_fake_data === true,
    human_not_duplicated:
      model?.sources?.human?.duplication_policy === "DO_NOT_COPY_OR_INFER",
    rendered: true
  });
})();