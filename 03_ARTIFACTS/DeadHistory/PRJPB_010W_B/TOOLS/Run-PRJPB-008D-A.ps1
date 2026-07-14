# ==========
# PRJPB_008D-A / UX UI EVALUATION REGISTRY
# ==========
#
# PURPOSE:
# Show UX/UI evaluation registry files.
#
# USAGE:
# powershell -ExecutionPolicy Bypass -File ".\02_TOOLS\Run-PRJPB-008D-A.ps1"

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ProjectId = "PRJ_0001_HIA.PRODUCT"
$UxDir = Join-Path $Root "04_PROJECTS\$ProjectId\UX_EVAL"

Set-Location $Root

if (-not (Test-Path $UxDir)) {
    throw "Missing UX_EVAL directory: $UxDir"
}

Write-Host "========== HIA UX/UI EVALUATION REGISTRY =========="
Get-ChildItem -Path $UxDir -File |
    Select-Object Name, Length, LastWriteTime |
    Sort-Object Name |
    Format-Table -AutoSize |
    Out-String -Width 240 |
    Write-Host
