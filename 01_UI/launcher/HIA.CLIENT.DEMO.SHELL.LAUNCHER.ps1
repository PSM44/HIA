<#
ID_UNICO..........: HIA_CLIENT_DEMO_SHELL_LAUNCHER
VERSION...........: v0.1
FECHA.............: 2026-06-04
CIUDAD............: Santiago, Chile
PROYECTO..........: PRJ_0001_HIA.PRODUCT
PROPOSITO.........: Abrir HIA Client Demo Shell navegable.
#>

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$Shell = Join-Path $Root "01_UI\web\client-shell\index.html"

Write-Host "========== HIA CLIENT DEMO SHELL / START =========="
Write-Host "ROOT.............: $Root"
Write-Host "SHELL............: $Shell"
Write-Host "==================================================="
Write-Host ""

if (-not (Test-Path -LiteralPath $Shell)) {
    throw "Client demo shell not found: $Shell"
}

Start-Process -FilePath $Shell

Write-Host "Client demo shell abierto."
Write-Host "========== HIA CLIENT DEMO SHELL / END =========="
