// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010O_FORMALIZE_BROWSER_PASS
// GENERATED_AT......: 2026-07-13 11:13:45 -04:00
// GENERATED_UTC.....: 2026-07-13T15:13:45.7582850Z
// SOURCE............: CURRENT_STATE refreshed after human browser validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "3031a35"
  },
  "continuity": {
    "next_action": "PRJPB_010P | conectar Control Tower y Portfolio con Project Workspace real | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 11:13:45 -04:00",
    "generated_utc": "2026-07-13T15:13:45.7582850Z",
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
    "project_workspace": "DONE_BROWSER_VALIDATED",
    "management_demo": "READY_FOR_NAVIGATION_INTEGRATION"
  },
  "next_slice": {
    "id": "PRJPB_010P",
    "target": "Project Workspace navigation integration",
    "target_global": "window.HIA_NAVIGATION_STATE",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Project Workspace browser validation PASS by human console verification.",
    "Control Tower and Portfolio navigation integration remains pending PRJPB_010P.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});