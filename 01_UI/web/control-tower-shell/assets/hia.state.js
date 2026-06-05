// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009N_D_R_REFRESHED_REAL_READONLY_STATE
// GENERATED_AT......: 2026-06-05 14:10:54 -0400
// SOURCE............: BATON + BACKLOG + RADAR + GIT + HIA CLI
// MODE..............: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    generated_from_head_before_commit: "518bd96",
    generated_from_head_message_before_commit: "20260605_HIA_PRJPB_009N_D_R_refresh_control_tower_state"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_009N-C | implementar estado real read-only visible en Control Tower Shell | ready",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    source: "BATON/BACKLOG/HIA CLI",
    generated_local: "2026-06-05 14:10:54 -0400"
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
    snapshot_policy: "versioned snapshot generated before final commit; commit hash self-reference is intentionally not a hard freshness gate",
    minibattle: "PRJPB_009N-E"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CLI/BATON/RADAR vivo, no este archivo generado.",
    "No ejecutar cambios desde esta capa UI.",
    "TD_STATE_SELF_REFERENCE_001: un snapshot versionado no puede conocer el hash del commit final que lo contiene; usar generated_from_head_before_commit."
  ])
});
