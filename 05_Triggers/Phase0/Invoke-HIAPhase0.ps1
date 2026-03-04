<#
========================================================================================
SCRIPT:      Invoke-HIAPhase0.ps1
ID_UNICO:    HIA.TRG.PHASE0.0002
VERSION:     v1.1-DRAFT
FECHA:       2026-03-03
HORA:        HH:MM (America/Santiago)
TZ:          America/Santiago
CIUDAD:      Santiago, Chile

PHASE0 OBJETIVO (PEATON):
  Ejecutar el Start/Close de Phase0 sin pensar:
    - Start:
      1) Smoke local
      2) Generar DragnDrop\Phase0 (generated-only) desde HUMAN.README
      3) Imprimir instrucciones claras para IA cloud (sin zip)
    - Close:
      1) Validators CANON (si aplica)
      2) RADAR refresh (si existe)
      3) (Opcional) Git checkpoint

NOTAS:
  - NO usa Validate-* (verbos no aprobados).
  - Este trigger es el “botón” del peatón. Helpers viven en 02_TOOLS.

USAGE:
  pwsh -NoProfile -File .\05_Triggers\Phase0\Invoke-HIAPhase0.ps1 -ProjectRoot "." -Action Start
  pwsh -NoProfile -File .\05_Triggers\Phase0\Invoke-HIAPhase0.ps1 -ProjectRoot "." -Action Close
========================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$true)]
  [ValidateSet("Start","Close")]
  [string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Message,[ValidateSet("INFO","WARN","ERROR")][string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host ("[{0}][{1}] {2}" -f $ts,$Level,$Message)
}

# Normalize root defensively
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$toolsDir   = Join-Path $ProjectRoot "02_TOOLS"
$smoke      = Join-Path $toolsDir "Invoke-HIASmoke.ps1"
$validators = Join-Path $toolsDir "Invoke-HIAValidators.ps1"
$radar      = Join-Path $toolsDir "RADAR.ps1"
$gitCheckpoint = Join-Path $toolsDir "HIA_TOL_0008_Invoke-HIAGitCheckpoint.ps1"
$ddBuilder  = Join-Path $toolsDir "HIA_TOL_0021_New-HIADragnDropPackage.ps1"

$ddPhase0   = Join-Path $ProjectRoot "DragnDrop\Phase0"

Write-Log ("PHASE0 {0} RUN_START ProjectRoot={1}" -f $Action,$ProjectRoot)

if ($Action -eq "Start") {

  if (-not (Test-Path -LiteralPath $smoke)) { throw "Falta tool: $smoke" }
  Write-Log "STEP 1/3 SMOKE"
  & pwsh -NoProfile -File $smoke -ProjectRoot $ProjectRoot
  if ($LASTEXITCODE -ne 0) { throw "SMOKE falló. Revisa output/logs." }

  if (-not (Test-Path -LiteralPath $ddBuilder)) { throw "Falta tool: $ddBuilder" }
  Write-Log "STEP 2/3 GENERATE_DRAGNDROP Phase0 (generated-only)"
  & pwsh -NoProfile -File $ddBuilder -ProjectRoot $ProjectRoot -Phase "Phase0"
  if ($LASTEXITCODE -ne 0) { throw "DragnDrop build falló." }

  Write-Log "STEP 3/3 IA INPUTS (DragnDrop)"
  if (-not (Test-Path -LiteralPath $ddPhase0)) { throw "No existe DragnDrop\\Phase0: $ddPhase0" }

  Write-Host ""
  Write-Host "==================== PHASE0 - INSTRUCCION PARA IA CLOUD ===================="
  Write-Host "1) Sube TODO el contenido de esta carpeta a la IA cloud (archivos sueltos, NO zip):"
  Write-Host "   $ddPhase0"
  Write-Host ""
  Write-Host "2) Exige a la IA cloud que responda:"
  Write-Host "   - 'acuso leído'"
  Write-Host "   - Lista exacta de nombres de archivos leídos (uno por línea)"
  Write-Host ""
  Write-Host "3) Si la IA cloud reporta error o no cumple 'acuso leído':"
  Write-Host "   Revisa: HUMAN.README\10.0_HUMAN.HIA.TROUBLE.txt"
  Write-Host "========================================================================="
  Write-Host ""

  Write-Log "PHASE0 START OK"
  exit 0
}

if ($Action -eq "Close") {

  if (-not (Test-Path -LiteralPath $validators)) { throw "Falta tool: $validators" }
  Write-Log "STEP 1/3 VALIDATORS CANON"
  & pwsh -NoProfile -File $validators -ProjectRoot $ProjectRoot -Mode CANON
  if ($LASTEXITCODE -ne 0) { throw "VALIDATORS CANON falló." }

  if (Test-Path -LiteralPath $radar) {
    Write-Log "STEP 2/3 RADAR refresh"
    & pwsh -NoProfile -File $radar -RootPath $ProjectRoot
    if ($LASTEXITCODE -ne 0) { throw "RADAR falló." }
  } else {
    Write-Log "STEP 2/3 RADAR omitido (tool no existe)" "WARN"
  }

  if (Test-Path -LiteralPath $gitCheckpoint) {
    Write-Log "STEP 3/3 GIT CHECKPOINT (opcional)"
    & pwsh -NoProfile -File $gitCheckpoint -ProjectRoot $ProjectRoot -Message "PHASE0 close checkpoint"
  } else {
    Write-Log "STEP 3/3 GIT CHECKPOINT omitido (tool no existe)" "WARN"
  }

  Write-Log "PHASE0 CLOSE OK"
  exit 0
}

throw "Acción inválida: $Action"