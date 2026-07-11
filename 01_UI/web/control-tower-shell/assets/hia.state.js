// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_010D_REFRESH_CURRENT_STATE_RADAR_CLEAN_CLOSE
// GENERATED_AT......: 2026-07-11 01:14:30 -04:00
// GENERATED_UTC.....: 2026-07-11T05:14:30.9521852Z
// SOURCE............: CURRENT_STATE refreshed after PRJPB_010C browser validation
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: READ_ONLY
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
    "project":  {
                    "id":  "PRJ_0001_HIA.PRODUCT",
                    "root_wsl":  "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
                    "root_win":  "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
                    "branch":  "feat/20260405-console-v2-phase1-phase2",
                    "generated_from_head_before_commit":  "8bb4ef9",
                    "generated_from_head_message_before_commit":  "20260711_HIA_PRJPB_010C_real_ui_browser_validation_launcher"
                },
    "continuity":  {
                       "next_action":  "PRJPB_010E | implementar Portfolio mÃ­nimo real desde HIA_UI_STATE/data contract | ready",
                       "resume_recommendation":  "PRJPB_010E | implementar Portfolio mÃ­nimo real desde HIA_UI_STATE/data contract | ready",
                       "evidence_state":  "FRESH",
                       "evidence_consistency":  "CONSISTENT",
                       "session_status":  "closed",
                       "generated_local":  "2026-07-11 01:14:30 -04:00",
                       "generated_utc":  "2026-07-11T05:14:30.9521852Z",
                       "resolver_status":  "CURRENT_STATE_PRIMARY",
                       "source":  "CURRENT_STATE",
                       "current_state_source":  "CURRENT_STATE",
                       "current_state_status":  "VALID",
                       "current_state_path":  "04_PROJECTS/PRJ_0001_HIA.PRODUCT/STATE/CURRENT_STATE.json",
                       "fallback_warning":  "N/A"
                   },
    "radar":  {
                  "lite_path":  "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
                  "lite_bytes":  863,
                  "index_path":  "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
                  "index_bytes":  420082,
                  "core_path":  "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt",
                  "core_bytes":  73031
              },
    "ui":  {
               "shell_file":  "01_UI/web/control-tower-shell/index.real.v0.html",
               "state_file":  "01_UI/web/control-tower-shell/assets/hia.state.js",
               "generator_file":  "manual-script:PRJPB_010D_REFRESH_CURRENT_STATE_RADAR_CLEAN_CLOSE",
               "mode":  "read-only generated snapshot",
               "minibattle":  "PRJPB_010D",
               "browser_validation":  "PASS",
               "ui_source":  "hia.state.js:HIA_REAL_STATE"
           },
    "warnings":  [
                     "Este estado es snapshot visible read-only; no reemplaza CURRENT_STATE, BATON, BACKLOG ni RADAR.",
                     "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
                     "PRJPB_010E queda como siguiente incremento funcional; no abrir gerencia hasta completar slice mÃ­nimo Portfolio."
                 ]
});
