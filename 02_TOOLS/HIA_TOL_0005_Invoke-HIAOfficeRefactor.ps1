<#
[HIA_TOL_0005] Invoke-HIAOfficeRefactor.ps1
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.5
SCOPE.....: HIA repo (modo office)
PURPOSE...:
  One-shot refactor seguro:
    - Crea 03_ARTIFACTS (DeadHistory/Logs).
    - Mueve scripts "dated" duplicados desde 02_TOOLS a DeadHistory.
    - Crea canónicos TXT (CORE + STATE.* + PATH.ID.REGISTRY) si faltan (no pisa).
    - Append-only changelog académico en HUMAN.
    - Regenera Path→ID registry BD-friendly.
    - Smoke: Git status + (opcional) invocar validadores existentes si están.

SAFETY PRINCIPLES:
  - NO usa verbos no aprobados (NO Validate-*).
  - NO edita HUMAN existente, solo crea/append.
  - NO pisa archivos canónicos si existen.
  - NO borra nada: todo movimiento va a DeadHistory.
  - Preflight Git: si hay cambios sin commit, avisa y pide confirmación vía -Force.

USAGE:
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\02_TOOLS\HIA_TOL_0005_Invoke-HIAOfficeRefactor.ps1 -ProjectRoot "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0005_Invoke-HIAOfficeRefactor.ps1 -ProjectRoot "..." -Force

#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [switch]$Force,

  # Passthrough para HIA_TOL_0006_New-HIAPathIdRegistry.ps1
  [switch]$IncludeSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Message, [ValidateSet("INFO","WARN","ERROR")] [string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Message"
}

function Test-GitClean {
  param([string]$Root)
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) { Write-Log "Git no encontrado en PATH. Continuo sin gate Git." "WARN"; return $true }

  Push-Location $Root
  try {
    $status = git status --porcelain
    if ($status -and -not $Force) {
      Write-Log "Git status no está limpio. Haz commit/stash o re-ejecuta con -Force." "ERROR"
      Write-Host $status
      return $false
    }
    if ($status -and $Force) {
      Write-Log "Git status no está limpio, pero -Force está activo. Continuo bajo tu riesgo." "WARN"
    }
    return $true
  } finally {
    Pop-Location
  }
}

function New-Folder {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
    Write-Log "Creada carpeta: $Path"
  } else {
    Write-Log "Carpeta ya existe: $Path"
  }
}

function New-TextFileIfMissing {
  param(
    [string]$Path,
    [string]$Content
  )
  if (-not (Test-Path $Path)) {
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $Content | Out-File -FilePath $Path -Encoding utf8
    Write-Log "Creado archivo: $Path"
  } else {
    Write-Log "Archivo ya existe (no se pisa): $Path"
  }
}

function Add-HumanChangelogEntry {
  param(
    [string]$HumanFile,
    [string[]]$Lines
  )
  $dir = Split-Path $HumanFile -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

  if (-not (Test-Path $HumanFile)) {
    @(
      "HIA_HUM_0003_OFFICE.CHANGELOG.txt"
      "DATE......: 2026-03-01"
      "TIME......: 18:06"
      "TZ........: America/Santiago"
      "CITY......: Santiago, Chile"
      "VERSION......: 0.1"
      ""
      "01.00_INTRO"
      "Este archivo es append-only. Registra cambios modo office: qué se hizo, por qué y evidencia."
      ""
      "02.00_LOG"
      "-----"
    ) | Out-File -FilePath $HumanFile -Encoding utf8
  }

  $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Add-Content -Path $HumanFile -Value ""
  Add-Content -Path $HumanFile -Value "ENTRY_TS: $stamp"
  foreach ($l in $Lines) { Add-Content -Path $HumanFile -Value $l }
  Add-Content -Path $HumanFile -Value "-----"

  Write-Log "Append HUMAN changelog: $HumanFile"
}

function Move-DuplicatedDatedToolsToDeadHistory {
  param(
    [string]$ToolsDir,
    [string]$DeadHistoryToolsDir
  )

  # Regla: mover scripts con prefijo YYYYMMDD_ desde 02_TOOLS hacia DeadHistory\02_TOOLS
  $pattern = '^\d{8}_.+\.ps1$'
  $dated = Get-ChildItem -Path $ToolsDir -File -Filter "*.ps1" | Where-Object { $_.Name -match $pattern }

  if (-not $dated) {
    Write-Log "No se encontraron scripts 'dated' (YYYYMMDD_*.ps1) en $ToolsDir"
    return @()
  }

  $moved = @()
  foreach ($f in $dated) {
    $target = Join-Path $DeadHistoryToolsDir $f.Name
    if (Test-Path $target) {
      Write-Log "Ya existe en DeadHistory (no sobreescribo): $target" "WARN"
      continue
    }
    Move-Item -Path $f.FullName -Destination $target
    Write-Log "Movido a DeadHistory: $($f.Name)"
    $moved += $f.Name
  }
  return $moved
}

function Invoke-Registry {
  param([string]$Root, [switch]$IncludeSha256Local)

  $script = Join-Path $Root "02_TOOLS\HIA_TOL_0006_New-HIAPathIdRegistry.ps1"
  if (-not (Test-Path -LiteralPath $script)) {
    Write-Log "Registry script no existe aún: $script (debes crearlo primero)" "WARN"
    return
  }

  if ($IncludeSha256Local) {
    pwsh -NoProfile -File $script -ProjectRoot $Root -IncludeSha256
  } else {
    pwsh -NoProfile -File $script -ProjectRoot $Root
  }
}

function Invoke-RecursiveValidator {
  param([string]$Root)
  $script = Join-Path $Root "02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1"
  if (-not (Test-Path $script)) {
    Write-Log "Validator recursivo no existe aún: $script (lo crearás con el bloque 04.00)" "WARN"
    return
  }
  pwsh -NoProfile -File $script -ProjectRoot $Root
}

# ---------------------------
# MAIN
# ---------------------------

# Normalización defensiva de ProjectRoot (evita fallos por comillas, CR/LF o espacios)
$ProjectRoot = ($ProjectRoot -as [string])

# 1) Trim de whitespace + comillas externas
$ProjectRoot = $ProjectRoot.Trim()
$ProjectRoot = $ProjectRoot.Trim('"')
$ProjectRoot = $ProjectRoot.Trim("'")

# 2) Elimina CR/LF internos (copy/paste en prompt interactivo)
$ProjectRoot = $ProjectRoot -replace "[`r`n]", ""

# 3) Resuelve a ruta completa si existe
try {
  if (Test-Path -LiteralPath $ProjectRoot) {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
  }
} catch {
  # Si Resolve-Path falla, dejamos el string normalizado y validamos abajo
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
  throw "ProjectRoot no existe (tras normalizar). Valor recibido: [$ProjectRoot]"
}

Write-Log "RUN_START ProjectRoot=$ProjectRoot"
if (-not (Test-GitClean -Root $ProjectRoot)) { exit 2 }

$toolsDir = Join-Path $ProjectRoot "02_TOOLS"
$fwDir    = Join-Path $ProjectRoot "00_FRAMEWORK"
$humanDir = Join-Path $ProjectRoot "HUMAN.README"

# 1) Crear carpetas de artifacts
$artifacts = Join-Path $ProjectRoot "03_ARTIFACTS"
$deadHist  = Join-Path $artifacts "DeadHistory"
$deadTools = Join-Path $deadHist  "02_TOOLS"
$logsDir   = Join-Path $artifacts "Logs"

New-Folder -Path $artifacts
New-Folder -Path $deadHist
New-Folder -Path $deadTools
New-Folder -Path $logsDir

# 2) Mover duplicados dated en 02_TOOLS
$moved = @()
if (Test-Path $toolsDir) {
  $moved = Move-DuplicatedDatedToolsToDeadHistory -ToolsDir $toolsDir -DeadHistoryToolsDir $deadTools
} else {
  Write-Log "No existe 02_TOOLS: $toolsDir" "WARN"
}

# 3) Crear canónicos TXT si faltan (no pisa)
$corePath = Join-Path $fwDir "HIA_COR_0001_HIA.CORE.txt"
$livePath = Join-Path $fwDir "HIA_STA_0001_PROJECT.STATE.LIVE.txt"
$histPath = Join-Path $fwDir "HIA_STA_0002_PROJECT.STATE.HISTORY.txt"
$idReg    = Join-Path $fwDir "HIA_IDR_0001_PATH.ID.REGISTRY.txt"

New-TextFileIfMissing -Path $corePath -Content @"
HIA_COR_0001_HIA.CORE.txt
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1
OWNER.....: HUMAN (concepto) / SYSTEM (operación)
SCOPE.....: HIA (framework)

01.00_INTRO
Definición operativa de HIA. Este archivo es canónico y estable. Cambios solo por modo office con evidencia.

02.00_PRINCIPIOS
02.01 PLAN -> APPLY -> VALIDATE -> LOG
02.02 PLAN_ONLY por defecto; APPLY requiere gate humano + checkpoint + preflight.
02.03 Quarantine por defecto. Hard delete solo con orden humana y evidencia.
02.04 No usar cmdlets 'Validate-*' (verbos no aprobados). Preferir 'Test-*' / 'Get-*' / 'Set-*' / 'New-*'.
02.05 Evidencia obligatoria: RADAR pre/post, logs, y Git cuando exista.

03.00_FASES (RESUMEN)
03.01 FASE 0: Filosofía / Human-first (intención, DoD, constraints, no-alcance)
03.02 FASE 1: Políticas + routing + ejecución IA (sin tocar FS)
03.03 FASE 2: Bootstrap local (estructura, runners, artifacts)
03.04 FASE 3.1: Pre-coding (smoke)
03.05 FASE 3.2: Coding iterativo con gates

04.00_ROUTING (HIGH-LEVEL)
04.01 TaskType: ANALYZE (no changes), PLAN (no changes), APPLY (changes), VALIDATE (evidence)
04.02 Todas las acciones APPLY requieren: (a) PLAN explícito, (b) backup/quarantine, (c) post-validate

05.00_BACKLOG / ESCALAMIENTO
Registrar escalamiento futuro aquí (estructura, DB, RADAR). Mantener pocas carpetas; escalar por archivos grandes y registry por path.

"@

New-TextFileIfMissing -Path $livePath -Content @"
HIA_STA_0001_PROJECT.STATE.LIVE.txt
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

01.00_CURRENT_OBJECTIVE
- (RELLENAR) Objetivo activo del proyecto HIA.

02.00_ACTIVE_DOMAINS
- (RELLENAR) Ej: Tooling, Governance, VSCode setup, etc.

03.00_NEXT_ACTIONS (WBS)
03.01 (RELLENAR)
03.02 (RELLENAR)

04.00_GATES
04.01 Gate de APPLY: requiere PLAN + evidencia + snapshot/RADAR.

05.00_EVIDENCE_POINTERS
- RADAR: (RELLENAR)
- Git commit: (RELLENAR)
- Logs: (RELLENAR)

"@

New-TextFileIfMissing -Path $histPath -Content @"
HIA_STA_0002_PROJECT.STATE.HISTORY.txt
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

01.00_PURPOSE
Bitácora consolidada. Append-only. Registra decisiones, cambios y evidencia.

02.00_LOG
-----

"@

New-TextFileIfMissing -Path $idReg -Content @"
HIA_IDR_0001_PATH.ID.REGISTRY.txt
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

01.00_PURPOSE
Registro canónico BD-friendly: Path -> ID -> Type -> Size -> LastWrite -> Hash(optional)

02.00_SCHEMA
- ID...........: HIA_<CAT>_<NNNN> (BD-friendly)
- TYPE.........: Folder | File
- REL_PATH.....: relative path desde ProjectRoot
- SIZE_BYTES...: para File
- LASTWRITE...: ISO 8601
- SHA256......: opcional (si activas hashing)

03.00_DATA
# Generado por script: HIA_TOL_0006_New-HIAPathIdRegistry.ps1

"@

# 4) Append changelog HUMAN
$humanChangelog = Join-Path $humanDir "HIA_HUM_0003_OFFICE.CHANGELOG.txt"
$lines = @(
  "01.00_CHANGE_SUMMARY",
  "Acción: Office refactor baseline.",
  "Movimientos a DeadHistory: " + ($(if($moved.Count -gt 0){$moved -join ', '} else {'(none)'})),
  "Creación canónicos (si faltaban): HIA_COR_0001, HIA_STA_0001, HIA_STA_0002, HIA_IDR_0001",
  "Evidencia: (pendiente) Ejecutar RADAR pre/post y commitear."
)
Add-HumanChangelogEntry -HumanFile $humanChangelog -Lines $lines

# 5) Regenerar registry y validar recursivo (si existen los scripts)
Invoke-Registry -Root $ProjectRoot -IncludeSha256Local:$IncludeSha256
Invoke-RecursiveValidator -Root $ProjectRoot

Write-Log "RUN_END OK"