<#
ID_UNICO..........: HIA.TRI.0001
NOMBRE_SUGERIDO...: HIA_TRI_0001_Build-DragnDropPhase0.ps1
VERSION...........: v0.1-DRAFT
FECHA.............: 2026-03-03
TZ.................: America/Santiago
OBJETIVO...........: 1 comando para el peatón: genera Phase0 + corre test.
EJECUCION..........:
pwsh -NoProfile -File .\05_Triggers\HIA_TRI_0001_Build-DragnDropPhase0.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level,[string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[HIA_TRI_0001][$ts][$Level] $Msg"
}

$projectRoot = (Get-Location).Path
Write-Log "INFO" "RUN_START ProjectRoot=$projectRoot"

$toolBuild = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0020_New-HIADragnDropPhase0Package.ps1"
$toolTest  = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0021_Test-HIADragnDropPhase0Package.ps1"

if (-not (Test-Path -LiteralPath $toolBuild)) { throw "No existe tool: $toolBuild" }
if (-not (Test-Path -LiteralPath $toolTest))  { throw "No existe tool: $toolTest" }

Write-Log "INFO" "STEP 1/2 Build Phase0 package"
pwsh -NoProfile -File $toolBuild -ProjectRoot $projectRoot
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Build Phase0 package failed."
}

Write-Log "INFO" "STEP 2/2 Test Phase0 package"
pwsh -NoProfile -File $toolTest -ProjectRoot $projectRoot
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Test Phase0 package failed."
}

Write-Log "INFO" "RUN_OK Phase0 ready. Adjunta DragnDrop\\Phase0\\ a IA cloud (sin Raw/ni 03_ARTIFACTS)."
Write-Log "INFO" "PHASE_DONE: Phase0"
exit 0