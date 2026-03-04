<#
========================================================================================
SCRIPT:      Invoke-HIASmoke.ps1
ID_UNICO:    HIA.TOOL.SMOKE.0001
VERSION:     v1.0-DRAFT
FECHA:       2026-03-03
HORA:        HH:MM (America/Santiago)
CIUDAD:      Santiago, Chile

OBJETIVO (SMOKE / 01.00_TEST):
  Ejecutar en 1 solo comando el “smoke test” operacional del repo HIA:
    1) Sync (modo seguro: -WhatIf por defecto)
    2) Validators (DRAFT por defecto)
    3) RADAR refresh
  Resultado:
    - ExitCode 0 si todo OK
    - ExitCode 1 si algo falla

USO (PEATÓN / COPY-PASTE):
  # Desde <PROJECT_ROOT>
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIASmoke.ps1 -ProjectRoot "<PROJECT_ROOT>"

EJEMPLO (REAL):
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIASmoke.ps1 -ProjectRoot "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"

NOTAS IMPORTANTES:
  - NO escribas "-ProjectRoot ..." solo en la consola. Eso NO ejecuta nada.
    Siempre debe ir después del comando pwsh -File ... (o de un script/función).
  - "<PROJECT_ROOT>" es placeholder documental. En ejecución usa la ruta real.

DEPENDENCIAS (deben existir en 02_TOOLS):
  - Invoke-HIASync.ps1
  - Invoke-HIAValidators.ps1
  - RADAR.ps1

========================================================================================
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string] $ProjectRoot,

  [Parameter(Mandatory = $false)]
  [ValidateSet("DRAFT","CANON")]
  [string] $ValidatorsMode = "DRAFT",

  # Por defecto el smoke NO aplica cambios del sync: solo reporta.
  [switch] $ApplySync
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-HIASmokeLog([string]$m, [string]$lvl = "INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$lvl] $m"
}

# --- Normalize ProjectRoot ---
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

if ($ProjectRoot -match '<PROJECT_ROOT>' -or $ProjectRoot -match '^\s*<.*>\s*$') {
  Write-HIASmokeLog "ProjectRoot contiene placeholder '<PROJECT_ROOT>'. Reemplázalo por la ruta real (ej: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA)." "ERROR"
  exit 1
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
  Write-HIASmokeLog "ProjectRoot no existe: $ProjectRoot" "ERROR"
  exit 1
}

$toolsDir = Join-Path $ProjectRoot "02_TOOLS"
$sync      = Join-Path $toolsDir "Invoke-HIASync.ps1"
$validators= Join-Path $toolsDir "Invoke-HIAValidators.ps1"
$radar     = Join-Path $toolsDir "RADAR.ps1"

foreach ($p in @($sync,$validators,$radar)) {
  if (-not (Test-Path -LiteralPath $p)) {
    Write-HIASmokeLog "Falta dependencia: $p" "ERROR"
    exit 1
  }
}

Write-HIASmokeLog "RUN_START ProjectRoot=$ProjectRoot ApplySync=$ApplySync ValidatorsMode=$ValidatorsMode"

[int]$fail = 0

# 1) SYNC
try {
  if ($ApplySync) {
    Write-HIASmokeLog "STEP 1/3 SYNC (APPLY) -> $sync"
    & pwsh -NoProfile -File $sync -ProjectRoot $ProjectRoot
  } else {
    Write-HIASmokeLog "STEP 1/3 SYNC (WHATIF) -> $sync"
    & pwsh -NoProfile -File $sync -ProjectRoot $ProjectRoot -WhatIf
  }
  if ($LASTEXITCODE -ne 0) { throw "SYNC exitcode=$LASTEXITCODE" }
} catch {
  Write-HIASmokeLog "SYNC_FAIL $($_.Exception.Message)" "ERROR"
  $fail++
}

# 2) VALIDATORS
try {
  Write-HIASmokeLog "STEP 2/3 VALIDATORS Mode=$ValidatorsMode -> $validators"
  & pwsh -NoProfile -File $validators -ProjectRoot $ProjectRoot -Mode $ValidatorsMode
  if ($LASTEXITCODE -ne 0) { throw "VALIDATORS exitcode=$LASTEXITCODE" }
} catch {
  Write-HIASmokeLog "VALIDATORS_FAIL $($_.Exception.Message)" "ERROR"
  $fail++
}

# 3) RADAR
try {
  Write-HIASmokeLog "STEP 3/3 RADAR -> $radar"
  & pwsh -NoProfile -File $radar -RootPath $ProjectRoot
  if ($LASTEXITCODE -ne 0) { throw "RADAR exitcode=$LASTEXITCODE" }
} catch {
  Write-HIASmokeLog "RADAR_FAIL $($_.Exception.Message)" "ERROR"
  $fail++
}

if ($fail -gt 0) {
  Write-HIASmokeLog "RUN_END FAIL failCount=$fail" "ERROR"
  exit 1
}

Write-HIASmokeLog "RUN_END OK"
exit 0