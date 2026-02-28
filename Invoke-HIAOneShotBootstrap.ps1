<# 
========================================================================================
SCRIPT:      Invoke-HIAOneShotBootstrap.ps1
ID_UNICO:    HIA.TOOL.ONES.0001
VERSION:     v1.1-DRAFT
FECHA:       2026-02-27
CIUDAD:      <CIUDAD>, <PAIS>

OBJETIVO:
  One-shot para normalizar estructura HIA, crear carpetas base, renombrar/mover HUMAN docs
  legacy, corregir metadatos internos (ID_UNICO / NOMBRE_SUGERIDO / ARCHIVO header),
  alinear SYNC manifest y opcionalmente correr validadores + RADAR si existen.

NOTAS:
  - No requiere Git.
  - Soporta -WhatIf (dry-run) y -Confirm.
  - No borra: mueve legacy a 03_ARTIFACTS\DeadHistory.
  - Evita -LiteralPath en operaciones críticas para prevenir error de binding.

COMO EJECUTAR:
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-HIAOneShotBootstrap.ps1 -ProjectRoot "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
  (simular) agrega: -WhatIf

========================================================================================
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
param(
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------- 00.10 Normalize root ----------
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

# ---------- 00.20 Paths base ----------
$HUMAN_DIR       = Join-Path $ProjectRoot "HUMAN.README"
$TOOLS_DIR       = Join-Path $ProjectRoot "02_TOOLS"
$ARTIFACTS_DIR   = Join-Path $ProjectRoot "03_ARTIFACTS"
$LOGS_DIR        = Join-Path $ARTIFACTS_DIR "LOGS"
$RADAR_DIR       = Join-Path $ARTIFACTS_DIR "RADAR"
$DEADHIST_DIR    = Join-Path $ARTIFACTS_DIR "DeadHistory"
$PROJECTS_DIR    = Join-Path $ProjectRoot "04_PROJECTS"
$FRAMEWORK_DIR   = Join-Path $ProjectRoot "00_FRAMEWORK"

# ---------- 00.30 Logging ----------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$RunLog = Join-Path $LOGS_DIR "HIA.ONES.0001.RUN.$ts.txt"

function Write-RunLog {
  param([Parameter(Mandatory=$true)][string]$Message)
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Write-Host $line
  if (Test-Path $LOGS_DIR) {
    Add-Content -Path $RunLog -Value $line
  }
}

function Ensure-Dir {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -Path $Path)) {
    if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
      Write-RunLog "DIR_CREATE: $Path"
    }
  } else {
    Write-RunLog "DIR_EXISTS: $Path"
  }
}

function Safe-Move {
  param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Destination
  )

  if (-not (Test-Path -Path $Source)) {
    Write-RunLog "SKIP_MOVE_NOT_FOUND: $Source"
    return
  }

  $dstDir = Split-Path -Parent $Destination
  Ensure-Dir -Path $dstDir

  if ($PSCmdlet.ShouldProcess("$Source -> $Destination", "Move")) {
    Move-Item -Path $Source -Destination $Destination -Force
    Write-RunLog "MOVE: $Source -> $Destination"
  }
}

function Replace-InFile {
  param(
    [Parameter(Mandatory=$true)][string]$File,
    [Parameter(Mandatory=$true)][string]$Pattern,
    [Parameter(Mandatory=$true)][string]$Replacement
  )

  if (-not (Test-Path -Path $File)) {
    Write-RunLog "SKIP_EDIT_NOT_FOUND: $File"
    return
  }

  $content = Get-Content -Path $File -Raw
  $new = [regex]::Replace($content, $Pattern, $Replacement, [System.Text.RegularExpressions.RegexOptions]::Multiline)

  if ($new -ne $content) {
    if ($PSCmdlet.ShouldProcess($File, "Edit content (regex replace)")) {
      Set-Content -Path $File -Value $new -NoNewline
      Write-RunLog "EDIT: $File | PATTERN: $Pattern"
    }
  } else {
    Write-RunLog "EDIT_NOCHANGE: $File | PATTERN: $Pattern"
  }
}

# ---------- 01.00 Preflight ----------
if (-not (Test-Path -Path $ProjectRoot)) {
  throw "ProjectRoot no existe: $ProjectRoot"
}

# Crear dirs base (logs primero)
Ensure-Dir -Path $ARTIFACTS_DIR
Ensure-Dir -Path $LOGS_DIR
Ensure-Dir -Path $RADAR_DIR
Ensure-Dir -Path $DEADHIST_DIR
Ensure-Dir -Path $HUMAN_DIR
Ensure-Dir -Path $TOOLS_DIR
Ensure-Dir -Path $PROJECTS_DIR
Ensure-Dir -Path $FRAMEWORK_DIR

# Crear log file
if ($PSCmdlet.ShouldProcess($RunLog, "Create run log")) {
  New-Item -ItemType File -Path $RunLog -Force | Out-Null
}
Write-RunLog "RUN_START: ProjectRoot=$ProjectRoot"

# ---------- 02.00 HUMAN legacy -> nombres definitivos ----------
$legacyBaton = Join-Path $HUMAN_DIR "HUMANR.BATON.txt"
$legacyRadar = Join-Path $HUMAN_DIR "HUMANR.RADAR.txt"

$newBaton    = Join-Path $HUMAN_DIR "02.00_HUMAN.BATON.txt"
$newRadar    = Join-Path $HUMAN_DIR "03.00_HUMAN.RADAR.txt"

# BATON
if ((Test-Path -Path $newBaton) -and (Test-Path -Path $legacyBaton)) {
  Safe-Move -Source $legacyBaton -Destination (Join-Path $DEADHIST_DIR ("HUMANR.BATON.$ts.txt"))
} else {
  Safe-Move -Source $legacyBaton -Destination $newBaton
}

# RADAR
if ((Test-Path -Path $newRadar) -and (Test-Path -Path $legacyRadar)) {
  Safe-Move -Source $legacyRadar -Destination (Join-Path $DEADHIST_DIR ("HUMANR.RADAR.$ts.txt"))
} else {
  Safe-Move -Source $legacyRadar -Destination $newRadar
}

# ---------- 03.00 Corrección metadatos internos ----------
# BATON
Replace-InFile -File $newBaton -Pattern '^(ID_UNICO\.\.\.\.\.\.\.\.\.\.\.\.:)\s*HUMAN\.R\.BATON\.0001\s*$' -Replacement '$1 HUMAN.BATON.0001'
Replace-InFile -File $newBaton -Pattern '^(NOMBRE_SUGERIDO\.\.\.:)\s*HUMANR\.BATON\.txt\s*$' -Replacement '$1 02.00_HUMAN.BATON.txt'
Replace-InFile -File $newBaton -Pattern '^(ARCHIVO:\s*)HUMANR\.BATON\.txt\s*$' -Replacement '$1 02.00_HUMAN.BATON.txt'

# RADAR
Replace-InFile -File $newRadar -Pattern '^(ID_UNICO\.\.\.\.\.\.\.\.\.\.\.\.:)\s*HUMAN\.R\.RADAR\.0001\s*$' -Replacement '$1 HUMAN.RADAR.0001'
Replace-InFile -File $newRadar -Pattern '^(NOMBRE_SUGERIDO\.\.\.:)\s*HUMANR\.RADAR\.txt\s*$' -Replacement '$1 03.00_HUMAN.RADAR.txt'
Replace-InFile -File $newRadar -Pattern '^(ARCHIVO:\s*)HUMANR\.RADAR\.txt\s*$' -Replacement '$1 03.00_HUMAN.RADAR.txt'

# ---------- 04.00 Alinear SYNC manifest ----------
$syncManifest = Join-Path $HUMAN_DIR "HIA_SYN_0001_SYNC_MANIFEST.txt"
Replace-InFile -File $syncManifest -Pattern '^(SOURCE_DOC_ID\.\.\.\.\.\.\.\.\.\.:)\s*HUMAN\.R\.BATON\.0001\s*$' -Replacement '$1 HUMAN.BATON.0001'
Replace-InFile -File $syncManifest -Pattern '^(SOURCE_DOC_ID\.\.\.\.\.\.\.\.\.\.:)\s*HUMAN\.R\.RADAR\.0001\s*$' -Replacement '$1 HUMAN.RADAR.0001'

# ---------- 05.00 Placeholders framework/projects ----------
$readmeFramework = Join-Path $FRAMEWORK_DIR "README.FRAMEWORK.txt"
$readmeProjects  = Join-Path $PROJECTS_DIR  "README.PROJECTS.txt"

if (-not (Test-Path -Path $readmeFramework)) {
  if ($PSCmdlet.ShouldProcess($readmeFramework, "Create placeholder")) {
@"
ID_UNICO..........: HIA.FRAME.0001
NOMBRE_SUGERIDO...: README.FRAMEWORK.txt
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-27

Proposito:
- Esta carpeta contiene el framework/metodologia HIA (Human + IA), no proyectos de aplicaciones.
- Los proyectos reales viven en 04_PROJECTS\.
"@ | Set-Content -Path $readmeFramework -NoNewline
    Write-RunLog "FILE_CREATE: $readmeFramework"
  }
}

if (-not (Test-Path -Path $readmeProjects)) {
  if ($PSCmdlet.ShouldProcess($readmeProjects, "Create placeholder")) {
@"
ID_UNICO..........: HIA.PROJ.0001
NOMBRE_SUGERIDO...: README.PROJECTS.txt
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-27

Proposito:
- Esta carpeta contiene proyectos reales (apps) desarrollados bajo HIA.
- Cada proyecto definira APP_SCOPE (Application Scope) para RADAR_CORE.
"@ | Set-Content -Path $readmeProjects -NoNewline
    Write-RunLog "FILE_CREATE: $readmeProjects"
  }
}

# ---------- 06.00 Ejecutar validadores / RADAR (si existen) ----------
$validators = Join-Path $TOOLS_DIR "Invoke-HIAValidators.ps1"
$radar      = Join-Path $TOOLS_DIR "RADAR.ps1"

if (Test-Path -Path $validators) {
  if ($PSCmdlet.ShouldProcess($validators, "Run validators (DRAFT)")) {
    Write-RunLog "RUN_VALIDATORS: $validators -Mode DRAFT"
    & pwsh -NoProfile -File $validators -Mode DRAFT | Out-Null
  }
} else {
  Write-RunLog "SKIP_VALIDATORS_NOT_FOUND: $validators"
}

if (Test-Path -Path $radar) {
  if ($PSCmdlet.ShouldProcess($radar, "Run RADAR")) {
    Write-RunLog "RUN_RADAR: $radar"
    & pwsh -NoProfile -File $radar | Out-Null
  }
} else {
  Write-RunLog "SKIP_RADAR_NOT_FOUND: $radar"
}

Write-RunLog "RUN_END: OK"
Write-Host "`nRun log: $RunLog"