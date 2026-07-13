// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010P_V_FORMALIZE_NAV_VALIDATION
// GENERATED_AT......: 2026-07-13 13:12:00 -04:00
// GENERATED_UTC.....: 2026-07-13T17:12:00.3826526Z
// SOURCE............: CURRENT_STATE refreshed after human navigation validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "425836c"
  },
  "continuity": {
    "next_action": "PRJPB_010Q | definir modelo Project Workspace para BATON BACKLOG DELIVERY sin duplicar HUMAN | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 13:12:00 -04:00",
    "generated_utc": "2026-07-13T17:12:00.3826526Z",
    "resolver_status": "CURRENT_STATE_PRIMARY",
    "source": "CURRENT_STATE",
    "current_state_status": "VALID",
    "current_state_path": "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
  },
  "product_state": {
    "control_tower": "DONE",
    "portfolio": "DONE",
    "navigation": "DONE_BROWSER_VALIDATED",
    "real_project_registry": "DONE_BROWSER_VALIDATED",
    "project_workspace": "DONE_BROWSER_VALIDATED",
    "management_demo": "READY_WITH_UX_OBSERVATION"
  },
  "next_slice": {
    "id": "PRJPB_010Q",
    "target": "Project Workspace evidence model",
    "target_global": "window.HIA_PROJECT_WORKSPACE_REAL",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Three-screen navigation browser validation PASS.",
    "Legacy Open Project Workspace button was not found visually; navigation links remain functional.",
    "UX observation must remain visible until button behavior is clarified or removed from acceptance criteria.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});