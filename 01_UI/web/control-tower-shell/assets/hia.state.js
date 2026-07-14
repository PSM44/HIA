// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009Q_CURRENT_STATE_PRIMARY_CONTROL_TOWER_GENERATOR
// GENERATED_AT......: 2026-07-14 16:37:39 -04:00
// GENERATED_UTC.....: 2026-07-14T20:37:39.4389996Z
// SEMANTIC_HASH.....: 64675147357FB100D276EB39E213426C94A2245C07DE9D73104127FAC1731469
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
    generated_from_head_before_commit: "982fdfb",
    generated_from_head_message_before_commit: "20260714.1602_PRJPB_010W-C_StateSync"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_010X-C | decidir GO/NO-GO para preparar paquete RC gerencial usando evidencia fresca | ready",
    resume_recommendation: "PRJPB_010X-C | decidir GO/NO-GO para preparar paquete RC gerencial usando evidencia fresca | ready",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    generated_local: "2026-07-14 16:37:39 -04:00",
    generated_utc: "2026-07-14T20:37:39.4389996Z",
    resolver_status: "CURRENT_STATE_PRIMARY",
    source: "CURRENT_STATE",
    current_state_source: "CURRENT_STATE",
    current_state_status: "VALID",
    current_state_path: "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
    fallback_warning: "N/A"
  }),
  radar: Object.freeze({
    lite_path: "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
    lite_bytes: 570,
    index_path: "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
    index_bytes: 171010,
    core_path: "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt",
    core_bytes: 1155182
  }),
  ui: Object.freeze({
    shell_file: "01_UI/web/control-tower-shell/index.html",
    state_file: "01_UI/web/control-tower-shell/assets/hia.state.js",
    generator_file: "02_TOOLS/HIA_CONTROL_TOWER_STATE_GENERATOR.ps1",
    mode: "read-only generated snapshot",
    minibattle: "PRJPB_010X-C"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza CURRENT_STATE, BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
    "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto mientras exista fallback heuristico."
  ])
});