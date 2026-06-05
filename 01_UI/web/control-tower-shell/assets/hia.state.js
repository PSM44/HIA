// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009O_HARDENED_GENERATED_STATE
// GENERATED_AT......: 2026-06-05 15:46:35 -04:00
// SOURCE............: HIA_CONTROL_TOWER_STATE_GENERATOR.ps1 + HIA CLI + Git + RADAR
// MODE..............: READ_ONLY_SNAPSHOT
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    generated_from_head_before_commit: "a577ff6",
    generated_from_head_message_before_commit: "20260605_HIA_PRJPB_009N_H4_refresh_control_tower_state"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_009O | READY - endurecer generador hia.state.js como tool reutilizable y eliminar patch manual.",
    resume_recommendation: "PRJPB_009O | READY - endurecer generador hia.state.js como tool reutilizable y eliminar patch manual.",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    generated_local: "2026-06-05 15:46:35 -04:00",
    resolver_status: "CLI_RESOLVER_ALIGNED_CONTINUE_STATUS_REVIEW",
    source: "HIA CLI project continue/status"
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
    generator_file: "02_TOOLS/HIA_CONTROL_TOWER_STATE_GENERATOR.ps1",
    mode: "read-only generated snapshot",
    minibattle: "PRJPB_009O"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CLI/BATON/RADAR vivo.",
    "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto: crear CURRENT_STATE machine-readable."
  ])
});
