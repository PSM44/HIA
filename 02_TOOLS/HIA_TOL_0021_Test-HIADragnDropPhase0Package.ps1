<#
ID_UNICO..........: HIA.TOL.0021
NOMBRE_SUGERIDO...: HIA_TOL_0021_Test-HIADragnDropPhase0Package.ps1
VERSION...........: v0.2-DEPRECATED
FECHA.............: 2026-03-11
TZ................: America/Santiago
OBJETIVO...........:
  Compat wrapper para test de Phase0.
  DEPRECATED: usar 02_TOOLS\HIA_TOL_0022_Test-HIADragnDropPackage.ps1 -Phase "Phase0".
ESTADO.............:
  Candidato a archive (no borrar todavia).
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
  throw "ProjectRoot no existe: [$ProjectRoot]"
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$generalTester = Join-Path $PSScriptRoot "HIA_TOL_0022_Test-HIADragnDropPackage.ps1"
if (-not (Test-Path -LiteralPath $generalTester)) {
  throw "No existe tooling general: $generalTester"
}

Write-Host "[HIA_TOL_0021][WARN] DEPRECATED wrapper activo. Redirigiendo a HIA_TOL_0022 (Phase0)."
& pwsh -NoProfile -File $generalTester -ProjectRoot $ProjectRoot -Phase "Phase0" -IncludeRadar "None"
exit $LASTEXITCODE