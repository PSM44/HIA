// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009Q_CURRENT_STATE_PRIMARY_CONTROL_TOWER_GENERATOR
// GENERATED_AT......: 2026-06-05 16:22:06 -04:00
// GENERATED_UTC.....: 2026-06-05T20:22:06.7085719Z
// SOURCE............: CURRENT_STATE primary with CLI fallback
// MODE..............: READ_ONLY_SNAPSHOT
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    generated_from_head_before_commit: "dd18a98",
    generated_from_head_message_before_commit: "20260605_HIA_PRJPB_009P_current_state_machine_readable"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_009Q | usar CURRENT_STATE como fuente primaria para generador Control Tower y reducir parsing CLI duplicado | ready",
    resume_recommendation: "PRJPB_009Q | usar CURRENT_STATE como fuente primaria para generador Control Tower y reducir parsing CLI duplicado | ready",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    generated_local: "2026-06-05 16:22:06 -04:00",
    generated_utc: "2026-06-05T20:22:06.7085719Z",
    resolver_status: "CURRENT_STATE_PRIMARY",
    source: "CURRENT_STATE",
    current_state_source: "CURRENT_STATE",
    current_state_status: "VALID",
    current_state_path: "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
    fallback_warning: "N/A"
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
    minibattle: "PRJPB_009Q"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
    "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto mientras exista fallback heuristico."
  ])
});
