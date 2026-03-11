<#
ID_UNICO..........: HIA.TOL.0020
NOMBRE_SUGERIDO...: HIA_TOL_0020_New-HIADragnDropPhase0Package.ps1
VERSION...........: v0.3-DEPRECATED
FECHA.............: 2026-03-11
TZ................: America/Santiago
OBJETIVO...........:
  Compat wrapper para Phase0.
  DEPRECATED: usar 02_TOOLS\HIA_TOL_0021_New-HIADragnDropPackage.ps1 -Phase "Phase0".
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

$generalBuilder = Join-Path $PSScriptRoot "HIA_TOL_0021_New-HIADragnDropPackage.ps1"
if (-not (Test-Path -LiteralPath $generalBuilder)) {
  throw "No existe tooling general: $generalBuilder"
}

Write-Host "[HIA_TOL_0020][WARN] DEPRECATED wrapper activo. Redirigiendo a HIA_TOL_0021 (Phase0)."
& pwsh -NoProfile -File $generalBuilder -ProjectRoot $ProjectRoot -Phase "Phase0" -IncludeRadar "None"
exit $LASTEXITCODE