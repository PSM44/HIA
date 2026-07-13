// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010T_CONNECT_MANAGEMENT_SUMMARY_NAVIGATION
// GENERATED_AT......: 2026-07-13 15:18:41 -04:00
// GENERATED_UTC.....: 2026-07-13T19:18:41.8272229Z
// SOURCE............: CURRENT_STATE refreshed after four-screen navigation integration
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "775ac77"
  },
  "continuity": {
    "current_objective": "Management Summary is integrated into primary navigation. Full four-screen browser validation is next.",
    "next_action": "PRJPB_010T-V | validar navegacion completa de cuatro pantallas en navegador | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 15:18:41 -04:00",
    "generated_utc": "2026-07-13T19:18:41.8272229Z",
    "resolver_status": "CURRENT_STATE_PRIMARY",
    "source": "CURRENT_STATE",
    "current_state_status": "VALID",
    "current_state_path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
  },
  "product_state": {
    "control_tower": "DONE",
    "portfolio": "DONE",
    "navigation": "FOUR_SCREEN_STATIC_VALIDATION_PASS",
    "real_project_registry": "DONE_BROWSER_VALIDATED",
    "project_workspace": "DONE_MODEL_BROWSER_VALIDATED",
    "management_demo": "SUMMARY_BROWSER_VALIDATED_NAV_PENDING"
  },
  "next_slice": {
    "id": "PRJPB_010T-V",
    "target": "Four-screen primary navigation browser validation",
    "target_global": "window.HIA_MANAGEMENT_SUMMARY_REAL",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Four-screen navigation static validation PASS.",
    "Human browser validation remains pending PRJPB_010T-V.",
    "Management demo remains conditionally ready; production readiness is not claimed.",
    "Legacy Open Project Workspace button observation remains non-blocking.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});