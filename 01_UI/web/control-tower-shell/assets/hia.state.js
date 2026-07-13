// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010P_CONNECT_WORKSPACE_NAVIGATION
// GENERATED_AT......: 2026-07-13 11:27:24 -04:00
// GENERATED_UTC.....: 2026-07-13T15:27:24.5063058Z
// SOURCE............: CURRENT_STATE refreshed after navigation implementation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "fc7da4b"
  },
  "continuity": {
    "next_action": "PRJPB_010P-V | validar navegacion Control Tower Portfolio Project Workspace en navegador | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 11:27:24 -04:00",
    "generated_utc": "2026-07-13T15:27:24.5063058Z",
    "resolver_status": "CURRENT_STATE_PRIMARY",
    "source": "CURRENT_STATE",
    "current_state_status": "VALID",
    "current_state_path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
  },
  "product_state": {
    "control_tower": "DONE",
    "portfolio": "DONE",
    "navigation": "DONE_STATIC_VALIDATION",
    "real_project_registry": "DONE_BROWSER_VALIDATED",
    "project_workspace": "DONE_BROWSER_VALIDATED",
    "management_demo": "READY_AFTER_NAV_BROWSER_VALIDATION"
  },
  "next_slice": {
    "id": "PRJPB_010P-V",
    "target": "Three-screen navigation browser validation",
    "target_global": "window.HIA_NAVIGATION_STATE",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Three-screen navigation implemented with static validation PASS.",
    "Human browser validation remains pending PRJPB_010P-V.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});