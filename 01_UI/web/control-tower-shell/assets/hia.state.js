// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010L_FORMALIZE_REAL_PROJECT_REGISTRY_VALIDATION
// GENERATED_AT......: 2026-07-11 21:53:43 -04:00
// GENERATED_UTC.....: 2026-07-12T01:53:43.1771457Z
// SOURCE............: CURRENT_STATE refreshed after browser validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "751f105"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010M | definir proximo slice funcional post registry real y preparar cierre de sesion si corresponde | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "active",
                       "generated_local":  "2026-07-11 21:53:43 -04:00",
                       "generated_utc":  "2026-07-12T01:53:43.1771457Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
                   },
    "multiproject":  {
                         "status":  "BROWSER_VALIDATED",
                         "source":  "filesystem:04_PROJECTS",
                         "registry_global":  "window.HIA_PROJECTS_REAL",
                         "registry_view_global":  "window.HIA_PROJECTS_REAL_VIEW",
                         "real_project_count":  1,
                         "no_fake_data":  true
                     },
    "ui":  {
               "portfolio_gate":  "PASS",
               "projects_registry_view":  "PASS",
               "source":  "hia.state.js:HIA_REAL_STATE",
               "write_mode":  "READ_ONLY"
           },
    "warnings":  [
                     "Next slice PRJPB_010M should decide whether to close session or continue functional expansion."
                 ]
});