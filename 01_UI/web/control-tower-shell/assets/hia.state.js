// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009Q_CURRENT_STATE_PRIMARY_CONTROL_TOWER_GENERATOR
// GENERATED_AT......: 2026-07-13 19:49:08 -04:00
// GENERATED_UTC.....: 2026-07-13T23:49:08.8900371Z
// SEMANTIC_HASH.....: 9684254747617B6FCB121A78755BE6690FB577746597C69B2761306CD552053E
// SOURCE............: CURRENT_STATE primary with CLI fallback
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: WRITE
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    generated_from_head_before_commit: "29f2a53",
    generated_from_head_message_before_commit: "20260713_HIA_fix_optional_last_session_projection"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_010V | ejecutar gate final de release candidate para demo gerencial | ready",
    resume_recommendation: "PRJPB_010V | ejecutar gate final de release candidate para demo gerencial | ready",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    generated_local: "2026-07-13 19:49:08 -04:00",
    generated_utc: "2026-07-13T23:49:08.8900371Z",
    resolver_status: "CURRENT_STATE_PRIMARY",
    source: "CURRENT_STATE",
    current_state_source: "CURRENT_STATE",
    current_state_status: "VALID",
    current_state_path: "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
    fallback_warning: "N/A"
  }),
  radar: Object.freeze({
    lite_path: "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
    lite_bytes: 72366,
    index_path: "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
    index_bytes: 174719,
    core_path: "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt",
    core_bytes: 1215871
  }),
  ui: Object.freeze({
    shell_file: "01_UI/web/control-tower-shell/index.html",
    state_file: "01_UI/web/control-tower-shell/assets/hia.state.js",
    generator_file: "02_TOOLS/HIA_CONTROL_TOWER_STATE_GENERATOR.ps1",
    mode: "read-only generated snapshot",
    minibattle: "PRJPB_010V"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza CURRENT_STATE, BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
    "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto mientras exista fallback heuristico."
  ])
});