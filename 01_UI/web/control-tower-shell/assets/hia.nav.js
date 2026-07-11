(function () {
  "use strict";

  function currentPage() {
    var path = String(window.location.pathname || "");
    if (path.indexOf("portfolio.real.v0.html") >= 0) return "Portfolio";
    if (path.indexOf("index.real.v0.html") >= 0) return "Control Tower";
    return "HIA UI";
  }

  function stateLabel() {
    var state = window.HIA_UI_STATE || {};
    var source = state.source || "source pending";
    var project = state.project_id || "project pending";
    return project + " | " + source;
  }

  function createLink(text, href) {
    var a = document.createElement("a");
    a.href = href;
    a.textContent = text;
    return a;
  }

  function renderNav() {
    if (document.getElementById("hiaNavShell")) return;

    var shell = document.createElement("div");
    shell.id = "hiaNavShell";
    shell.className = "hia-nav-shell";

    var title = document.createElement("div");
    title.className = "hia-nav-title";
    title.innerHTML = "<strong>" + currentPage() + "</strong> <span class='hia-nav-badge'>" + stateLabel() + "</span>";

    var actions = document.createElement("div");
    actions.className = "hia-nav-actions";
    actions.appendChild(createLink("Open Control Tower", "index.real.v0.html"));
    actions.appendChild(createLink("Open Portfolio", "portfolio.real.v0.html"));

    var refresh = document.createElement("button");
    refresh.type = "button";
    refresh.textContent = "Refresh";
    refresh.addEventListener("click", function () { window.location.reload(); });
    actions.appendChild(refresh);

    shell.appendChild(title);
    shell.appendChild(actions);

    if (document.body.firstChild) {
      document.body.insertBefore(shell, document.body.firstChild);
    } else {
      document.body.appendChild(shell);
    }

    window.HIA_NAVIGATION_STATE = Object.freeze({
      rendered_at: new Date().toISOString(),
      page: currentPage(),
      source: (window.HIA_UI_STATE || {}).source || null,
      project_id: (window.HIA_UI_STATE || {}).project_id || null,
      control_tower_href: "index.real.v0.html",
      portfolio_href: "portfolio.real.v0.html",
      write_mode: "READ_ONLY"
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", renderNav);
  } else {
    renderNav();
  }
})();