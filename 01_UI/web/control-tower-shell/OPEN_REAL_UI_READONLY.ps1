#requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$UiFile = Join-Path $Here "index.real.v0.html"

Write-Host "============================================================"
Write-Host "HIA Real UI Read-Only Launcher"
Write-Host "============================================================"
Write-Host "Mode: READ_ONLY"
Write-Host "File: $UiFile"
Write-Host ""
Write-Host "Expected DevTools checks:"
Write-Host "  window.HIA_UI_STATE.source"
Write-Host "  window.HIA_UI_STATE_DEBUG.candidate_name"
Write-Host ""
Write-Host "Expected values:"
Write-Host "  hia.state.js:HIA_REAL_STATE"
Write-Host "  HIA_REAL_STATE"
Write-Host ""

Start-Process -FilePath $UiFile
