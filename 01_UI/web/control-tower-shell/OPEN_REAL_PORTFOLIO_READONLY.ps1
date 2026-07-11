#requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$PortfolioFile = Join-Path $Here "portfolio.real.v0.html"

Write-Host "============================================================"
Write-Host "HIA Portfolio Real Minimum - Read-Only Launcher"
Write-Host "============================================================"
Write-Host "Mode: READ_ONLY"
Write-Host "File: $PortfolioFile"
Write-Host ""
Write-Host "Expected DevTools checks:"
Write-Host "  window.HIA_PORTFOLIO_REAL_MINIMUM"
Write-Host "  window.HIA_UI_STATE.source"
Write-Host "  window.HIA_UI_STATE_DEBUG.candidate_name"
Write-Host ""
Write-Host "Expected values:"
Write-Host "  source: hia.state.js:HIA_REAL_STATE"
Write-Host "  candidate_name: HIA_REAL_STATE"
Write-Host ""

Start-Process -FilePath $PortfolioFile
