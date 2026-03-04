<#
ID_UNICO..........: HIA.TOL.0020
NOMBRE_SUGERIDO...: HIA_TOL_0020_New-HIADragnDropPhase0Package.ps1
VERSION...........: v0.2-HARDENED
FECHA.............: 2026-03-04
TZ.................: America/Santiago
OBJETIVO...........: Regenerar <PROJECT_ROOT>\DragnDrop\Phase0\ con los HUMAN mínimos (deterministas) definidos por START.RITUAL.
NOTAS..............:
- Sin ZIP (compatibilidad IA cloud).
- Determinista: Phase0 se purga y se regenera completo.
- No usa verbos no aprobados (NO Validate-*).
- Canon: START.RITUAL (con punto). Fallback legacy: START_RITUAL (underscore), copiando SIEMPRE al nombre canónico.
EJECUCION..........:
pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0020_New-HIADragnDropPhase0Package.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level,[string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[HIA_TOL_0020][$ts][$Level] $Msg"
}

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

# Normalize ProjectRoot defensively (quotes/whitespace/newlines)
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
  throw "ProjectRoot no existe: [$ProjectRoot]"
}

try {
  $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
} catch { }

Write-Log "INFO" "RUN_START ProjectRoot=$ProjectRoot"

$humanRoot = Join-Path $ProjectRoot "HUMAN.README"
if (-not (Test-Path -LiteralPath $humanRoot)) {
  throw "Falta carpeta requerida: $humanRoot"
}

$ddRoot = Join-Path $ProjectRoot "DragnDrop\Phase0"
Ensure-Directory -Path $ddRoot

# Purge package dir to avoid stale/contaminated handoffs
try {
  $items = Get-ChildItem -LiteralPath $ddRoot -Force -ErrorAction Stop
  foreach ($it in $items) {
    Remove-Item -LiteralPath $it.FullName -Recurse -Force -ErrorAction Stop
  }
  Write-Log "INFO" "PURGED Phase0 dir (clean regen): $ddRoot"
} catch {
  throw "No se pudo limpiar Phase0 dir: $ddRoot | $($_.Exception.Message)"
}

# Required canon files (BATON obligatorio)
$required = @(
  @{ Name="00.0_HUMAN.GENERAL.txt";       Path=(Join-Path $humanRoot "00.0_HUMAN.GENERAL.txt") },
  @{ Name="01.0_HUMAN.USER.txt";          Path=(Join-Path $humanRoot "01.0_HUMAN.USER.txt") },
  @{ Name="04.0_HUMAN.BATON.txt";         Path=(Join-Path $humanRoot "04.0_HUMAN.BATON.txt") },
  @{ Name="07.0_HUMAN.MASTER.txt";        Path=(Join-Path $humanRoot "07.0_HUMAN.MASTER.txt") },
  @{ Name="08.0_HUMAN.SYNC.MANIFEST.txt"; Path=(Join-Path $humanRoot "08.0_HUMAN.SYNC.MANIFEST.txt") },

  # Canon: START.RITUAL (con punto). Fallback: START_RITUAL (legacy).
  @{ Name="09.0_HUMAN.START.RITUAL.txt";  Path=(Join-Path $humanRoot "09.0_HUMAN.START.RITUAL.txt") },
  @{ Name="09.0_HUMAN.START.RITUAL.txt";  Path=(Join-Path $humanRoot "09.0_HUMAN.START_RITUAL.txt"); Legacy=$true }
)

$copied = New-Object System.Collections.Generic.List[string]
$seen   = @{}

# Copy requeridos (canon-first, legacy-fallback)
foreach ($r in $required) {
  $name = [string]$r.Name
  $src  = [string]$r.Path

  # Si ya copiamos ese Name (porque el canon existía), ignorar fallback
  if ($seen.ContainsKey($name)) { continue }

  if (Test-Path -LiteralPath $src) {
    $dst = Join-Path $ddRoot $name
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $copied.Add($name) | Out-Null
    $seen[$name] = $true

    if ($r.ContainsKey("Legacy") -and $r.Legacy) {
      Write-Log "WARN" "COPIED $name (legacy source detected; consider renaming file in HUMAN.README to canon with dots)"
    } else {
      Write-Log "INFO" "COPIED $name"
    }
  }
}

# Hard fail si faltó alguno de los NOMBRES canónicos
$canonMust = @(
  "00.0_HUMAN.GENERAL.txt",
  "01.0_HUMAN.USER.txt",
  "04.0_HUMAN.BATON.txt",
  "07.0_HUMAN.MASTER.txt",
  "08.0_HUMAN.SYNC.MANIFEST.txt",
  "09.0_HUMAN.START.RITUAL.txt"
)

foreach ($n in $canonMust) {
  if (-not $seen.ContainsKey($n)) {
    $expected = Join-Path $humanRoot $n
    throw "Falta requerido (canon): $expected"
  }
}

# README (SIEMPRE se regenera; GENERATED-ONLY)
$readme = Join-Path $ddRoot "README.txt"
$stamp  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$lines  = New-Object System.Collections.Generic.List[string]

$lines.Add("==========") | Out-Null
$lines.Add("README — DragnDrop Phase0 (HIA)") | Out-Null
$lines.Add("==========") | Out-Null
$lines.Add("") | Out-Null
$lines.Add(("GENERATED_AT.: {0}" -f $stamp)) | Out-Null
$lines.Add(("PROJECT_ROOT.: {0}" -f $ProjectRoot)) | Out-Null
$lines.Add("RULES.......: GENERATED-ONLY. NO EDITAR MANUALMENTE.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("OBJETIVO:") | Out-Null
$lines.Add("Este paquete se adjunta a IA cloud para activar HIA Fase 0 (PLAN_ONLY), sin improvisar.") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("FILES_INCLUDED (copiados desde HUMAN.README):") | Out-Null
foreach ($c in ($copied | Sort-Object)) { $lines.Add((" - {0}" -f $c)) | Out-Null }
$lines.Add("") | Out-Null
$lines.Add("REGLAS_EXCLUSION (para el peatón):") | Out-Null
$lines.Add(" - NO adjuntar Raw/") | Out-Null
$lines.Add(" - NO adjuntar 03_ARTIFACTS/") | Out-Null
$lines.Add(" - NO adjuntar videos/imágenes") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("IF_MISSING: si falta un archivo esperado, re-ejecuta el trigger (no copies a mano).") | Out-Null

$lines | Set-Content -LiteralPath $readme -Encoding UTF8

Write-Log "INFO" "README_WRITTEN README.txt (regenerated)"
Write-Log "INFO" ("RUN_OK Phase0 package ready | copied={0} | dest={1}" -f @($copied).Count, $ddRoot)