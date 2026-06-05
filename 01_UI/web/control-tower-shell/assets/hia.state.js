// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009N_F_REPAIR_NEXT_ACTION_RESOLVER_STATE
// GENERATED_AT......: 2026-06-05 14:14:06 -0400
// SOURCE............: BATON + BACKLOG + RADAR + GIT + HIA CLI
// MODE..............: READ_ONLY_SNAPSHOT
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "PRJ_0001_HIA.PRODUCT",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "feat/20260405-console-v2-phase1-phase2",
    generated_from_head_before_commit: "a3d45c2",
    generated_from_head_message_before_commit: "20260605_HIA_PRJPB_009N_E_snapshot_state_policy"
  }),
  continuity: Object.freeze({
    next_action: "PRJPB_009N-F | reparar resolver NEXT_ACTION vivo y reconciliar Control Tower state | ready",
    resolver_status: "CLI_STILL_STALE_OVERRIDE_WITH_CANONICAL_TARGET",
    evidence_state: "FRESH",
    evidence_consistency: "CONSISTENT",
    session_status: "closed",
    source: "BATON/BACKLOG/HIA CLI with explicit canonical fallback",
    generated_local: "2026-06-05 14:14:06 -0400"
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
    minibattle: "PRJPB_009N-F"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CLI/BATON/RADAR vivo, salvo cuando el resolver CLI esté declarado stale en resolver_status.",
    "TD_NEXT_ACTION_RESOLVER_001: reparar parser CLI para no requerir fallback documental."
  ])
});
