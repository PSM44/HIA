// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010J_DEFINE_REAL_MULTIPROJECT_SLICE
// GENERATED_AT......: 2026-07-11 21:21:53 -04:00
// GENERATED_UTC.....: 2026-07-12T01:21:53.8132278Z
// SOURCE............: CURRENT_STATE refreshed after navigation validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "root_wsl":  "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "bb767d7",
                    "generated_from_head_message_before_commit":  "20260711_HIA_PRJPB_010I_formalize_nav_browser_validation"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010K | implementar registry real de proyectos desde 04_PROJECTS sin mocks | ready",
                       "resume_recommendation":  "PRJPB_010K | implementar registry real de proyectos desde 04_PROJECTS sin mocks | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "active",
                       "generated_local":  "2026-07-11 21:21:53 -04:00",
                       "generated_utc":  "2026-07-12T01:21:53.8132278Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
                       "fallback_warning":  "N/A"
                   },
    "multiproject":  {
                         "status":  "DEFINED_SCOPE",
                         "source":  "filesystem:04_PROJECTS",
                         "real_project_count":  1,
                         "registry_global_candidate":  "window.HIA_PROJECTS_REAL",
                         "registry_file_candidate":  "01_UI/web/control-tower-shell/assets/hia.projects.real.js",
                         "no_fake_data":  true
                     },
    "ui":  {
               "control_tower_portfolio_navigation":  "PASS",
               "source":  "hia.state.js:HIA_REAL_STATE",
               "write_mode":  "READ_ONLY",
               "functional_ui_loop":  "CLOSED"
           },
    "warnings":  [
                     "Multi-project view is not implemented yet.",
                     "Only real 04_PROJECTS directories may be listed in PRJPB_010K.",
                     "No fake project data is allowed."
                 ]
});