// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010Q_DEFINE_WORKSPACE_EVIDENCE_MODEL_REPAIR_R2
// GENERATED_AT......: 2026-07-13 13:16:09 -04:00
// GENERATED_UTC.....: 2026-07-13T17:16:09.4680700Z
// SOURCE............: CURRENT_STATE refreshed after repaired evidence-model validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "39272fc"
  },
  "continuity": {
    "next_action": "PRJPB_010Q-V | validar modelo Project Workspace en navegador | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 13:16:09 -04:00",
    "generated_utc": "2026-07-13T17:16:09.4680700Z",
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
    "project_workspace": "DONE_MODEL_STATIC_VALIDATION",
    "management_demo": "READY_AFTER_MODEL_BROWSER_VALIDATION"
  },
  "next_slice": {
    "id": "PRJPB_010Q-V",
    "target": "Project Workspace evidence model browser validation",
    "target_global": "window.HIA_PROJECT_WORKSPACE_MODEL_VIEW",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Workspace evidence model static validation PASS.",
    "HUMAN remains external authority and is not duplicated.",
    "Browser validation remains pending PRJPB_010Q-V.",
    "Legacy Open Project Workspace button observation remains non-blocking."
  ]
});