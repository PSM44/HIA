<#
========================================================================================
SCRIPT:      Invoke-HIAPhase0.ps1
ID_UNICO:    HIA.TRG.PHASE0.0001
VERSION:     v1.0-DRAFT
FECHA:       2026-03-03
TZ:          America/Santiago
CIUDAD:      Santiago, Chile

PHASE0 OBJETIVO:
  Preparar el repo y la sesión para que un peatón ejecute HIA sin pensar:
    - Smoke local (Sync WhatIf + Validators DRAFT + RADAR)
    - Instrucciones claras de qué subir a IA cloud (DragnDrop\Phase0)
    - Checklist mínimo de outputs esperados

ACCIONES:
  -Action Start:
      1) Ejecuta Invoke-HIASmoke.ps1 (default: Sync -WhatIf + Validators DRAFT + RADAR)
      2) Imprime instrucción de subir DragnDrop\Phase0 a IA cloud
  -Action Close:
      1) Ejecuta Validators CANON (requiere git limpio)
      2) Ejecuta RADAR refresh final
      3) (Opcional) Git checkpoint si existe tool

USO (PEATÓN):
  pwsh -NoProfile -File .\05_Triggers\Phase0\Invoke-HIAPhase0.ps1 -ProjectRoot "C:\...\HIA" -Action Start
  pwsh -NoProfile -File .\05_Triggers\Phase0\Invoke-HIAPhase0.ps1 -ProjectRoot "C:\...\HIA" -Action Close

========================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string] $ProjectRoot,

  [Parameter(Mandatory=$true)]
  [ValidateSet("Start","Close")]
  [string] $Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-HIATrgLog([string]$m, [ValidateSet("INFO","WARN","ERROR")] [string]$lvl="INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$lvl] $m"
}

# Normalize + guardrail placeholders
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

if ($ProjectRoot -match '<PROJECT_ROOT>' -or $ProjectRoot -match '^\s*<.*>\s*$') {
  throw "ProjectRoot contiene placeholder '<PROJECT_ROOT>'. Reemplázalo por ruta real (ej: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA)."
}
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$toolsDir   = Join-Path $ProjectRoot "02_TOOLS"
$smoke      = Join-Path $toolsDir "Invoke-HIASmoke.ps1"
$validators = Join-Path $toolsDir "Invoke-HIAValidators.ps1"
$radar      = Join-Path $toolsDir "RADAR.ps1"
$gitCheckpoint = Join-Path $toolsDir "HIA_TOL_0008_Invoke-HIAGitCheckpoint.ps1"

$ddPhase0 = Join-Path $ProjectRoot "DragnDrop\Phase0"

Write-HIATrgLog "PHASE0 $Action RUN_START ProjectRoot=$ProjectRoot"

if ($Action -eq "Start") {

  if (-not (Test-Path -LiteralPath $smoke)) { throw "Falta tool: $smoke" }
  Write-HIATrgLog "STEP 1/2 SMOKE"
  & pwsh -NoProfile -File $smoke -ProjectRoot $ProjectRoot
  if ($LASTEXITCODE -ne 0) { throw "SMOKE falló. Revisa output/logs." }

  Write-HIATrgLog "STEP 2/2 IA INPUTS (DragnDrop)"
  if (-not (Test-Path -LiteralPath $ddPhase0)) {
    Write-HIATrgLog "WARN: No existe DragnDrop\Phase0: $ddPhase0" "WARN"
  }

  Write-Host ""
  Write-Host "==================== PHASE0 - INSTRUCCIÓN PARA IA CLOUD ===================="
  Write-Host "1) Sube TODO el contenido de esta carpeta a la IA cloud:"
  Write-Host "   $ddPhase0"
  Write-Host ""
  Write-Host "2) Exige a la IA cloud que responda:"
  Write-Host "   - 'acuso leído'"
  Write-Host "   - Lista exacta de nombres de archivos leídos (uno por línea)"
  Write-Host ""
  Write-Host "3) Si la IA cloud reporta error, revisa: HUMAN.README\10.0_HUMAN.HIA.TROUBLE.txt"
  Write-Host "========================================================================="
  Write-Host ""

  Write-HIATrgLog "PHASE0 START OK"
  exit 0
}

if ($Action -eq "Close") {

  if (-not (Test-Path -LiteralPath $validators)) { throw "Falta tool: $validators" }
  Write-HIATrgLog "STEP 1/3 VALIDATORS CANON (requiere git limpio)"
  & pwsh -NoProfile -File $validators -ProjectRoot $ProjectRoot -Mode CANON
  if ($LASTEXITCODE -ne 0) { throw "VALIDATORS CANON falló. Deja git limpio o usa checkpoint/commit." }

  if (Test-Path -LiteralPath $radar) {
    Write-HIATrgLog "STEP 2/3 RADAR refresh"
    & pwsh -NoProfile -File $radar -RootPath $ProjectRoot
    if ($LASTEXITCODE -ne 0) { throw "RADAR falló." }
  } else {
    Write-HIATrgLog "WARN: RADAR.ps1 no existe, se omite." "WARN"
  }

  if (Test-Path -LiteralPath $gitCheckpoint) {
    Write-HIATrgLog "STEP 3/3 GIT CHECKPOINT (opcional)"
    & pwsh -NoProfile -File $gitCheckpoint -ProjectRoot $ProjectRoot -Message "PHASE0 close checkpoint"
  } else {
    Write-HIATrgLog "STEP 3/3 GIT CHECKPOINT omitido (tool no existe)" "WARN"
  }

  Write-HIATrgLog "PHASE0 CLOSE OK"
  exit 0
}

throw "Acción inválida: $Action"