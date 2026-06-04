<#
ID_UNICO..........: HIA_CONTROL_TOWER_SHELL_LAUNCHER
VERSION...........: v0.1
FECHA.............: 2026-06-04
CIUDAD............: Santiago, Chile
PROYECTO..........: PRJ_0001_HIA.PRODUCT
PROPOSITO.........: Abrir HIA Control Tower Shell.
#>

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$Shell = Join-Path $Root "01_UI\web\control-tower-shell\index.html"

Write-Host "========== HIA CONTROL TOWER SHELL / START =========="
Write-Host "ROOT.............: $Root"
Write-Host "SHELL............: $Shell"
Write-Host "====================================================="
Write-Host ""

if (-not (Test-Path -LiteralPath $Shell)) {
    throw "Control Tower shell not found: $Shell"
}

Start-Process -FilePath $Shell

Write-Host "Control Tower shell abierto."
Write-Host "========== HIA CONTROL TOWER SHELL / END =========="
