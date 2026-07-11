// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010G_REFRESH_STATE_RADAR_POST_PORTFOLIO
// GENERATED_AT......: 2026-07-11 12:45:31 -04:00
// GENERATED_UTC.....: 2026-07-11T16:45:31.2453763Z
// SOURCE............: CURRENT_STATE refreshed after Portfolio browser validation
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
                    "generated_from_head_before_commit":  "029dd26",
                    "generated_from_head_message_before_commit":  "20260711_HIA_PRJPB_010F_R4_rewrite_portfolio_ascii_clean"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010H | integrar navegacion real Control Tower Portfolio y preparar slice multi-proyecto | ready",
                       "resume_recommendation":  "PRJPB_010H | integrar navegacion real Control Tower Portfolio y preparar slice multi-proyecto | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "active",
                       "generated_local":  "2026-07-11 12:45:31 -04:00",
                       "generated_utc":  "2026-07-11T16:45:31.2453763Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
                       "fallback_warning":  "N/A"
                   },
    "radar":  {
                  "lite_path":  "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
                  "index_path":  "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
                  "core_path":  "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt",
                  "registry_path":  "03_ARTIFACTS/RADAR/Radar.Registry.ACTIVE.txt"
              },
    "ui":  {
               "shell_file":  "01_UI/web/control-tower-shell/index.real.v0.html",
               "portfolio_file":  "01_UI/web/control-tower-shell/portfolio.real.v0.html",
               "state_file":  "01_UI/web/control-tower-shell/assets/hia.state.js",
               "portfolio_js":  "01_UI/web/control-tower-shell/assets/hia.portfolio.real.js",
               "mode":  "read-only generated snapshot",
               "minibattle":  "PRJPB_010G",
               "control_tower_browser_validation":  "PASS",
               "portfolio_browser_validation":  "PASS",
               "ui_source":  "hia.state.js:HIA_REAL_STATE"
           },
    "warnings":  [
                     "This state is a read-only visible snapshot; CURRENT_STATE remains canonical.",
                     "PRJPB_010H is the next functional slice after Portfolio real minimum."
                 ]
});