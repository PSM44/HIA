async function loadConsoleData() {
  const diagnostics = document.getElementById("diagnostics");
  diagnostics.textContent = "Loading...";

  try {
    const response = await fetch("./data/console-data.json", { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    renderStatus(data.status || {});
    renderSession(data.session || {});
    renderPlans(data.plans || []);
    renderPlanSummary(data.plan_summary || {});
    renderSources(data.sources || []);
    diagnostics.textContent = JSON.stringify(data.diagnostics || {}, null, 2);
  } catch (error) {
    diagnostics.textContent = `Failed to load console-data.json\n${error.message}`;
  }
}

function renderKeyValueGrid(elementId, items) {
  const root = document.getElementById(elementId);
  root.innerHTML = "";

  Object.entries(items).forEach(([key, value]) => {
    const wrapper = document.createElement("div");
    wrapper.className = "kv";

    const keyEl = document.createElement("div");
    keyEl.className = "key";
    keyEl.textContent = key;

    const valueEl = document.createElement("div");
    valueEl.className = "value";
    valueEl.textContent = value == null ? "" : String(value);

    wrapper.appendChild(keyEl);
    wrapper.appendChild(valueEl);
    root.appendChild(wrapper);
  });
}

function renderStatus(status) {
  renderKeyValueGrid("statusGrid", status);
}

function renderSession(session) {
  renderKeyValueGrid("sessionGrid", session);
}

function renderPlanSummary(summary) {
  renderKeyValueGrid("plansSummary", summary);
}

function renderPlans(plans) {
  const tbody = document.querySelector("#plansTable tbody");
  tbody.innerHTML = "";

  plans.forEach((plan) => {
    const tr = document.createElement("tr");
    ["plan_id", "status", "task", "updated_utc"].forEach((field) => {
      const td = document.createElement("td");
      td.textContent = plan[field] == null ? "" : String(plan[field]);
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  });
}

function renderSources(sources) {
  const root = document.getElementById("sourcesGrid");
  root.innerHTML = "";

  sources.forEach((source) => {
    const wrapper = document.createElement("div");
    wrapper.className = "kv";

    const keyEl = document.createElement("div");
    keyEl.className = "key";
    keyEl.textContent = source.label || "source";

    const valueEl = document.createElement("div");
    valueEl.className = "value";
    valueEl.textContent = source.path || "";

    wrapper.appendChild(keyEl);
    wrapper.appendChild(valueEl);
    root.appendChild(wrapper);
  });
}

document.getElementById("refreshBtn").addEventListener("click", loadConsoleData);
loadConsoleData();