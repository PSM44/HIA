<#
ID_UNICO..........: HIA.TRI.0003
NOMBRE_SUGERIDO...: HIA_TRI_0003_Build-DragnDropPhase2.ps1
VERSION...........: v0.1-DRAFT
FECHA.............: 2026-03-05
TZ................: America/Santiago
CIUDAD............: Santiago, Chile

OBJETIVO...........:
  Trigger "peatón-first" (1 comando) para generar y testear DragnDrop\Phase2\
  usando tools canónicos (dev).

REGLAS.............:
  - No editar DragnDrop manualmente (generated-only).
  - Default IncludeRadar=None (toggle manual se hace en tools, no en trigger).
  - Si falla build o test, el trigger debe FAIL (no imprimir RUN_OK).

EJECUCION..........:
  pwsh -NoProfile -File .\05_Triggers\HIA_TRI_0003_Build-DragnDropPhase2.ps1

SALIDA.............:
  - DragnDrop\Phase2\ regenerado
  - PASS/FAIL por tester
  - Instrucción para adjuntar a IA cloud (sin Raw/ni 03_ARTIFACTS)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param(
    [ValidateSet("INFO","WARN","ERROR")] [string]$Level,
    [string]$Msg
  )
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host ("[HIA_TRI_0003][{0}][{1}] {2}" -f $ts,$Level,$Msg)
}

$projectRoot = (Get-Location).Path
Write-Log "INFO" ("RUN_START ProjectRoot={0}" -f $projectRoot)

$toolBuild = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0021_New-HIADragnDropPackage.ps1"
$toolTest  = Join-Path $projectRoot "02_TOOLS\HIA_TOL_0022_Test-HIADragnDropPackage.ps1"

if (-not (Test-Path -LiteralPath $toolBuild)) { throw "FAIL: No existe tool build: $toolBuild" }
if (-not (Test-Path -LiteralPath $toolTest))  { throw "FAIL: No existe tool test : $toolTest" }

Write-Log "INFO" "STEP 1/2 Build Phase2 package (IncludeRadar=None default)"
pwsh -NoProfile -File $toolBuild -ProjectRoot $projectRoot -Phase "Phase2" -IncludeRadar "None"
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Build Phase2 package failed."
}

Write-Log "INFO" "STEP 2/2 Test Phase2 package (IncludeRadar=None default)"
pwsh -NoProfile -File $toolTest -ProjectRoot $projectRoot -Phase "Phase2" -IncludeRadar "None"
if ($LASTEXITCODE -ne 0) {
  throw "FAIL: Test Phase2 package failed."
}

Write-Log "INFO" "RUN_OK Phase2 ready. Adjunta DragnDrop\Phase2\ a IA cloud (sin Raw/ni 03_ARTIFACTS)."
Write-Log "INFO" "PHASE_DONE: Phase2"
exit 0
Write-Log "INFO" "PHASE_DONE: Phase2"
exit 0