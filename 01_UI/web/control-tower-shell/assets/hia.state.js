// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009N_C_R_CONTROL_TOWER_REAL_READONLY_STATE
// GENERATED_AT......: 2026-06-05 14:04:00 -0400
// SOURCE............: BATON + BACKLOG + RADAR + GIT + HIA CLI
// TARGET............: control-tower-shell
// MODE..............: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ============================================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    head_short: "2710986",
    head_message: "20260605_HIA_PRJPB_009N_C_real_readonly_state_control_tower"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_009N-C | implementar estado real read-only visible en Control Tower Shell | ready",
    evidence_state: "- EVIDENCE_STATE: FRESH.",
    session_status: "closed",
    source: "BATON/BACKLOG/HIA CLI",
    generated_local: "2026-06-05 14:04:00 -0400"
  }),
  radar: Object.freeze({
    lite_path: "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
    lite_bytes: 991,
    index_path: "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
    index_bytes: 108020,
    core_path: "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt",
    core_bytes: 1116339
  }),
  ui: Object.freeze({
    shell_file: "01_UI/web/control-tower-shell/index.html",
    state_file: "01_UI/web/control-tower-shell/assets/hia.state.js",
    mode: "read-only visible state",
    minibattle: "PRJPB_009N-C-R"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CLI/BATON/RADAR vivo, no este archivo generado.",
    "No ejecutar cambios desde esta capa UI."
  ])
});
