// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010Z_R2_SESSION_CLOSE
// GENERATED_AT......: 2026-07-11 22:35:47 -04:00
// GENERATED_UTC.....: 2026-07-12T02:35:47.5137712Z
// SOURCE............: CURRENT_STATE refreshed at formal session close
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "8030de6"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010N | implementar Project Workspace real minimum read-only desde evidencia del proyecto | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "closed",
                       "generated_local":  "2026-07-11 22:35:47 -04:00",
                       "generated_utc":  "2026-07-12T02:35:47.5137712Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
                   },
    "product_state":  {
                          "control_tower":  "DONE",
                          "portfolio":  "DONE",
                          "navigation":  "DONE",
                          "real_project_registry":  "DONE_BROWSER_VALIDATED",
                          "project_workspace":  "NEXT",
                          "management_demo":  "NOT_READY_UNTIL_PROJECT_WORKSPACE"
                      },
    "next_slice":  {
                       "id":  "PRJPB_010N",
                       "target":  "Project Workspace real minimum",
                       "target_global":  "window.HIA_PROJECT_WORKSPACE_REAL",
                       "mode":  "READ_ONLY",
                       "no_fake_data":  true
                   },
    "warnings":  [
                     "Session closed; next implementation is PRJPB_010N.",
                     "Strict RADAR freshness against final HEAD may require a post-close runtime RADAR refresh."
                 ]
});