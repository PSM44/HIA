// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010K_R3_IMPLEMENT_REAL_PROJECT_REGISTRY
// GENERATED_AT......: 2026-07-11 21:44:12 -04:00
// GENERATED_UTC.....: 2026-07-12T01:44:12.5610307Z
// SOURCE............: CURRENT_STATE refreshed after real project registry implementation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "6f448a4"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010L | validar registry real de proyectos en navegador y refrescar continuidad | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "active",
                       "generated_local":  "2026-07-11 21:44:12 -04:00",
                       "generated_utc":  "2026-07-12T01:44:12.5610307Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json"
                   },
    "multiproject":  {
                         "status":  "IMPLEMENTED_CANDIDATE",
                         "source":  "filesystem:04_PROJECTS",
                         "registry_global":  "window.HIA_PROJECTS_REAL",
                         "registry_file":  "01_UI/web/control-tower-shell/assets/hia.projects.real.js",
                         "real_project_count":  1,
                         "no_fake_data":  true
                     },
    "ui":  {
               "portfolio_registry":  "IMPLEMENTED_CANDIDATE",
               "source":  "hia.state.js:HIA_REAL_STATE",
               "write_mode":  "READ_ONLY"
           },
    "warnings":  [
                     "Validate registry in browser before treating it as closed."
                 ]
});