<#
========================================================================================
SCRIPT:      Invoke-HIAValidators.ps1
ID_UNICO:    HIA.TOOL.VALIDATORS.0001
VERSION:     v1.0-DRAFT
FECHA:       2026-03-02
HORA:        HH:MM (America/Santiago)
CIUDAD:      Santiago, Chile

OBJETIVO:
  Runner único y canónico para ejecutar validaciones del repositorio HIA con severidad
  controlada por -Mode.

MODOS:
  -Mode DRAFT:
    - Warnings NO rompen el build (exit 0 si no hay FAIL duro).
  -Mode CANON:
    - Warnings cuentan como FAIL (exit 1 si existe cualquier WARN o ERROR).
    - Pensado para “congelar” calidad y detectar drift.

VALIDADORES EJECUTADOS (CANÓNICOS HOY):
  1) 02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1
     - Chequea metadata mínima / estructura (según tu tooling actual).

SALIDAS:
  - Log en: 03_ARTIFACTS\LOGS\VALIDATION.RUNNER.<timestamp>.txt
  - Exit code:
      0 = OK
      1 = FAIL

COMO EJECUTAR:
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -ProjectRoot "C:\...\HIA" -Mode DRAFT
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -ProjectRoot "C:\...\HIA" -Mode CANON

NOTAS:
  - Este script NO sincroniza DERIVED blocks. Eso lo hace Invoke-HIASync.ps1.
  - Evita verbos no aprobados: solo Invoke/Test/Repair/etc.
========================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $ProjectRoot,

  [Parameter(Mandatory = $false)]
  [ValidateSet("DRAFT","CANON")]
  [string] $Mode = "DRAFT",

  [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$m, [string]$lvl = "INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$ts][$lvl] $m"
  Write-Host $line
  if ($script:RunLog) { Add-Content -LiteralPath $script:RunLog -Value $line }
}

# ---- Normalize ProjectRoot (quita comillas / CRLF accidentales) ----
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
  throw "ProjectRoot no existe: $ProjectRoot"
}

$ArtifactsDir = Join-Path $ProjectRoot "03_ARTIFACTS"
$LogsDir      = Join-Path $ArtifactsDir "LOGS"

if (-not (Test-Path -LiteralPath $ArtifactsDir)) { New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null }
if (-not (Test-Path -LiteralPath $LogsDir))      { New-Item -ItemType Directory -Force -Path $LogsDir      | Out-Null }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$script:RunLog = Join-Path $LogsDir "VALIDATION.RUNNER.$stamp.txt"
New-Item -ItemType File -Force -Path $script:RunLog | Out-Null

Log "RUN_START ProjectRoot=$ProjectRoot Mode=$Mode Force=$Force"

# ---- Guard: Git clean (opcional pero recomendado) ----
Push-Location $ProjectRoot
try {
  $porc = git status --porcelain 2>$null
  if (-not $Force -and $porc) {
    Log "Git status no está limpio. (Usa -Force si quieres ignorar.)" "ERROR"
    Log $porc "ERROR"
    exit 1
  }
} catch {
  # Si git no está disponible, no rompas por eso (pero deja evidencia)
  Log "No se pudo ejecutar 'git status'. Continuando igual. Error=$($_.Exception.Message)" "WARN"
} finally {
  Pop-Location
}

# ---- Ejecutar validadores ----
$validators = @(
  @{
    Name = "Test-HIAFileContentRecursive"
    Path = "02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1"
    Args = @("-ProjectRoot", $ProjectRoot)
  }
)

[int]$warnCount = 0
[int]$failCount = 0

foreach ($v in $validators) {
  $abs = Join-Path $ProjectRoot $v.Path
  if (-not (Test-Path -LiteralPath $abs)) {
    Log "Validator no existe: $($v.Path)" "ERROR"
    $failCount++
    continue
  }

  Log "RUN_VALIDATOR Name=$($v.Name) Path=$($v.Path)"

  # Ejecuta en un proceso pwsh separado para capturar exit code robusto y no contaminar el scope.
  $cmdArgs = @("-NoProfile","-File",$abs) + $v.Args
  $lines = & pwsh @cmdArgs 2>&1

  foreach ($ln in $lines) {
    $s = [string]$ln
    if ($s) { Add-Content -LiteralPath $script:RunLog -Value $s }
    if ($s -match "\[WARN\]" -or $s -match "^\[.*\]\[WARN\]") { $warnCount++ }
    if ($s -match "\[ERROR\]" -or $s -match "^\[.*\]\[ERROR\]" -or $s -match "Exception:") { $failCount++ }
  }

  if ($LASTEXITCODE -ne 0) {
    Log "VALIDATOR_EXIT_FAIL Name=$($v.Name) ExitCode=$LASTEXITCODE" "ERROR"
    $failCount++
  } else {
    Log "VALIDATOR_EXIT_OK Name=$($v.Name) ExitCode=0"
  }
}

# ---- Política de severidad por Mode ----
if ($Mode -eq "CANON" -and $warnCount -gt 0) {
  Log "CANON_MODE: warnings detectados => FAIL (warnCount=$warnCount)" "ERROR"
  $failCount++
}

if ($failCount -gt 0) {
  Log "RUN_END FAIL warnCount=$warnCount failCount=$failCount Log=$script:RunLog" "ERROR"
  exit 1
}

Log "RUN_END OK warnCount=$warnCount failCount=$failCount Log=$script:RunLog"
exit 0