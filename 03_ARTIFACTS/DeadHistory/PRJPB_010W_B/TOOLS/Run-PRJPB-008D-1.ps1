# ==========
# PRJPB_008D-1 / DASHBOARD UI FUNCTIONAL EVAL
# ==========
#
# PURPOSE:
# Verify dashboard UI v0.1 static functional checks and show UX_EVAL registry.
#
# USAGE:
# powershell -ExecutionPolicy Bypass -File ".\02_TOOLS\Run-PRJPB-008D-1.ps1"

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ProjectId = "PRJ_0001_HIA.PRODUCT"
$DashboardPath = Join-Path $Root "01_UI\web\HIA.MANAGEMENT.DASHBOARD.v0.1.html"
$UxDir = Join-Path $Root "04_PROJECTS\$ProjectId\UX_EVAL"

Set-Location $Root

Write-Host "========== HIA DASHBOARD UI FUNCTIONAL EVAL =========="
Write-Host "DASHBOARD_PATH...: $DashboardPath"
Write-Host "UX_DIR...........: $UxDir"

if (-not (Test-Path $DashboardPath)) { throw "Missing dashboard." }
if (-not (Test-Path $UxDir)) { throw "Missing UX_EVAL." }

$Html = Get-Content -Path $DashboardPath -Raw

$Checks = [ordered]@{
    "HAS_READY_LANE"             = ($Html -match "Listo")
    "HAS_NEXT_LANE"              = ($Html -match "Próximamente")
    "HAS_FUTURE_LANE"            = ($Html -match "Futuro")
    "HAS_GAPS_SECTION"           = ($Html -match "Brechas que NO se deben ocultar")
    "HAS_COMMANDS_SECTION"       = ($Html -match "Comandos demo mínimos")
    "HAS_FILTER_SCRIPT"          = ($Html -match "function setFilter" -and $Html -match "classList.toggle")
    "DECLARES_RADAR_STALE"       = ($Html -match "RADAR" -and $Html -match "Stale")
}

foreach ($Key in $Checks.Keys) {
    $Status = if ($Checks[$Key]) { "PASS" } else { "FAIL" }
    Write-Host "$($Key.PadRight(26)) : $Status"
}

Write-Host ""
Write-Host "UX_EVAL_FILES:"
Get-ChildItem -Path $UxDir -File |
    Select-Object Name, Length, LastWriteTime |
    Sort-Object Name |
    Format-Table -AutoSize |
    Out-String -Width 240 |
    Write-Host
