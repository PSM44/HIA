// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010Q_V_FORMALIZE_MODEL_VALIDATION
// GENERATED_AT......: 2026-07-13 14:18:35 -04:00
// GENERATED_UTC.....: 2026-07-13T18:18:35.0811097Z
// SOURCE............: CURRENT_STATE refreshed after human model validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "ee0d735"
  },
  "continuity": {
    "next_action": "PRJPB_010R | definir readiness y siguiente slice gerencial HIA post Workspace | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 14:18:35 -04:00",
    "generated_utc": "2026-07-13T18:18:35.0811097Z",
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
    "project_workspace": "DONE_MODEL_BROWSER_VALIDATED",
    "management_demo": "READY_FOR_READINESS_DEFINITION"
  },
  "next_slice": {
    "id": "PRJPB_010R",
    "target": "HIA readiness and next management-facing slice",
    "target_global": "TBD_AFTER_READINESS_DEFINITION",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Workspace evidence model browser validation PASS: 16 of 16 checks.",
    "HUMAN remains external authority and is not duplicated.",
    "Legacy Open Project Workspace button observation remains non-blocking.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});