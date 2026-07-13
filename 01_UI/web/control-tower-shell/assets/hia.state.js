// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010N_IMPLEMENT_PROJECT_WORKSPACE_REAL_MINIMUM
// GENERATED_AT......: 2026-07-12 22:37:24 -04:00
// GENERATED_UTC.....: 2026-07-13T02:37:24.4782289Z
// SOURCE............: CURRENT_STATE refreshed after PRJPB_010N
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ===========================================================

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "396bb44"
  },
  "continuity": {
    "next_action": "PRJPB_010O | validar Project Workspace real minimum en navegador y formalizar cierre de loop | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-12 22:37:24 -04:00",
    "generated_utc": "2026-07-13T02:37:24.4782289Z",
    "resolver_status": "CURRENT_STATE_PRIMARY",
    "source": "CURRENT_STATE",
    "current_state_status": "VALID",
    "current_state_path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
  },
  "product_state": {
    "control_tower": "DONE",
    "portfolio": "DONE",
    "navigation": "DONE",
    "real_project_registry": "DONE_BROWSER_VALIDATED",
    "project_workspace": "DONE_STATIC_VALIDATION",
    "management_demo": "NOT_READY_UNTIL_BROWSER_VALIDATION"
  },
  "next_slice": {
    "id": "PRJPB_010O",
    "target": "Project Workspace browser validation",
    "target_global": "window.HIA_PROJECT_WORKSPACE_REAL_VIEW",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Project Workspace static implementation PASS; browser validation pending PRJPB_010O.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});