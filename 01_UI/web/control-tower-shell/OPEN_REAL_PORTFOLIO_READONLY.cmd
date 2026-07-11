@echo off
setlocal
set "HIA_UI_DIR=%~dp0"
set "HIA_PORTFOLIO_FILE=%HIA_UI_DIR%portfolio.real.v0.html"

echo ============================================================
echo HIA Portfolio Real Minimum - Read-Only Launcher
echo ============================================================
echo Mode: READ_ONLY
echo File: %HIA_PORTFOLIO_FILE%
echo.
echo Expected DevTools checks:
echo   window.HIA_PORTFOLIO_REAL_MINIMUM
echo   window.HIA_UI_STATE.source
echo   window.HIA_UI_STATE_DEBUG.candidate_name
echo.
echo Expected values:
echo   gate: PASS
echo   source: hia.state.js:HIA_REAL_STATE
echo   candidate_name: HIA_REAL_STATE
echo.
start "" "%HIA_PORTFOLIO_FILE%"
endlocal