// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010M_DEFINE_NEXT_FUNCTIONAL_SLICE
// GENERATED_AT......: 2026-07-11 22:04:58 -04:00
// GENERATED_UTC.....: 2026-07-12T02:04:58.2169522Z
// SOURCE............: CURRENT_STATE refreshed after next-slice definition
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "5d59502"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010N | implementar Project Workspace real minimum read-only desde evidencia del proyecto | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "active",
                       "generated_local":  "2026-07-11 22:04:58 -04:00",
                       "generated_utc":  "2026-07-12T02:04:58.2169522Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
                   },
    "multiproject":  {
                         "status":  "BROWSER_VALIDATED",
                         "source":  "filesystem:04_PROJECTS",
                         "real_project_count":  1,
                         "no_fake_data":  true
                     },
    "next_slice":  {
                       "id":  "PRJPB_010N",
                       "target":  "Project Workspace real minimum",
                       "target_global":  "window.HIA_PROJECT_WORKSPACE_REAL",
                       "mode":  "READ_ONLY",
                       "no_fake_data":  true
                   },
    "warnings":  [
                     "PRJPB_010N is not implemented yet.",
                     "Session close is safe after PRJPB_010M if requested."
                 ]
});