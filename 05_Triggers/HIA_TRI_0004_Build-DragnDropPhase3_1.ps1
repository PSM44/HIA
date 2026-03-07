<#
ID_UNICO..........: HIA.TRI.0004
NOMBRE_SUGERIDO...: HIA_TRI_0004_Build-DragnDropPhase3_1.ps1
VERSION...........: v0.1-DRAFT
FECHA.............: 2026-03-04
TZ.................: America/Santiago
OBJETIVO...........: 1 comando para el peatón: genera Phase3.1 + corre test.
EJECUCION.:
  pwsh -NoProfile -File .\05_Triggers\HIA_TRI_0004_Build-DragnDropPhase3_1.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level,[string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[HIA_TRI_0004][$ts][$Level] $Msg"
}

$projectRoot = (Get-Location).Path
Write-Log "INFO" "RUN_START ProjectRoot=$projectRoot"

$toolBuild = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0021_New-HIADragnDropPackage.ps1"
$toolTest  = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0022_Test-HIADragnDropPackage.ps1"

if (-not (Test-Path -LiteralPath $toolBuild)) { throw "No existe tool: $toolBuild" }
if (-not (Test-Path -LiteralPath $toolTest))  { throw "No existe tool: $toolTest" }

Write-Log "INFO" "STEP 1/2 Build Phase3.1 package (IncludeRadar=None default)"
pwsh -NoProfile -File $toolBuild -ProjectRoot $projectRoot -Phase "Phase3.1" -IncludeRadar "None"
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Build Phase3.1 package failed."
}

Write-Log "INFO" "STEP 2/2 Test Phase3.1 package (IncludeRadar=None default)"
pwsh -NoProfile -File $toolTest -ProjectRoot $projectRoot -Phase "Phase3.1" -IncludeRadar "None"
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Test Phase3.1 package failed."
}

Write-Log "INFO" "RUN_OK Phase3.1 ready. Adjunta DragnDrop\Phase3.1\ a IA cloud (sin Raw/ni 03_ARTIFACTS)."
Write-Log "INFO" "PHASE_DONE: Phase3.1"
exit 0