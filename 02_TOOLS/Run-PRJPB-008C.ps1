# ==========
# PRJPB_008C / BASIC MANAGEMENT UI RUNNER
# ==========
#
# PURPOSE:
# Open HIA Management Dashboard v0.1.
#
# USAGE:
# powershell -ExecutionPolicy Bypass -File ".\02_TOOLS\Run-PRJPB-008C.ps1"

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$DashboardPath = Join-Path $Root "01_UI\web\HIA.MANAGEMENT.DASHBOARD.v0.1.html"

Set-Location $Root

if (-not (Test-Path $DashboardPath)) {
    throw "Missing dashboard: $DashboardPath"
}

Write-Host "========== HIA MANAGEMENT DASHBOARD =========="
Write-Host "DASHBOARD_PATH...: $DashboardPath"
Write-Host "OPENING..........: YES"

Invoke-Item $DashboardPath
