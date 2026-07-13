// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010R_DEFINE_MANAGEMENT_READINESS
// GENERATED_AT......: 2026-07-13 14:36:02 -04:00
// GENERATED_UTC.....: 2026-07-13T18:36:02.8066528Z
// SOURCE............: CURRENT_STATE refreshed after readiness definition
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES

window.HIA_REAL_STATE = Object.freeze({
  "project": {
    "id": "PRJ_0001_HIA.PRODUCT",
    "root_win": "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    "branch": "feat/20260405-console-v2-phase1-phase2",
    "generated_from_head_before_commit": "1e097b4"
  },
  "continuity": {
    "next_action": "PRJPB_010S | implementar Management Summary real read-only | ready",
    "evidence_state": "FRESH",
    "evidence_consistency": "CONSISTENT",
    "session_status": "closed",
    "generated_local": "2026-07-13 14:36:02 -04:00",
    "generated_utc": "2026-07-13T18:36:02.8066528Z",
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
    "management_demo": "CONDITIONALLY_READY"
  },
  "next_slice": {
    "id": "PRJPB_010S",
    "target": "Management Summary real read-only",
    "target_global": "window.HIA_MANAGEMENT_SUMMARY_REAL",
    "mode": "READ_ONLY",
    "no_fake_data": true
  },
  "warnings": [
    "Management demo is conditionally ready, not production ready.",
    "Management Summary view remains pending.",
    "Legacy Open Project Workspace button observation remains non-blocking.",
    "Strict RADAR freshness against post-commit HEAD remains pending runtime refresh."
  ]
});