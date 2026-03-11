<#
========================================================================================
SCRIPT:   HIA_TOL_0021_New-HIADragnDropPackage.ps1
ID_UNICO: HIA.TOL.DRAGNDROP.0001
DATE......: 2026-03-03
TIME......: HH:MM
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.1-DRAFT

OBJETIVO:
  Generar DragnDrop\<Phase>\ como build output (generated-only) a partir de HUMAN.README,
  sin zip (adjuntos sueltos para IA cloud).

FUENTE DE VERDAD:
  HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt :: sección 02.50 (DD_COPY_ENTRY_ID...)

SEGURIDAD:
  - NO usa Validate-* (verbos no aprobados).
  - Limpia destino antes de copiar (para evitar drift).
  - FAIL determinista si:
      (a) no hay DD_COPY_ENTRY_ID para la Phase solicitada
      (b) falta cualquier SOURCE_FILE declarado en el manifest
  - BATON es REQUERIDO (no existe “opcional” por Phase).

USO:
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0021_New-HIADragnDropPackage.ps1 -ProjectRoot "." -Phase "Phase0"

SALIDAS:
  - DragnDrop\<Phase>\README.txt (generado)
  - Log: 03_ARTIFACTS\Logs\DRAGNDROP.<Phase>.<timestamp>.txt
========================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$true)]
  [ValidateSet("Phase0","Phase1","Phase2","Phase3.1","Phase3.2")]
  [string]$Phase,

  [Parameter(Mandatory=$false)]
  [ValidateSet("None","Index","IndexLite")]
  [string]$IncludeRadar = "None"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$File,[string]$Message,[ValidateSet("INFO","WARN","ERROR")][string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[{0}][{1}] {2}" -f $ts, $Level, $Message
  Write-Host $line
  Add-Content -LiteralPath $File -Value $line -Encoding UTF8
}

# Normalize root defensively
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

$humanDir   = Join-Path $ProjectRoot "HUMAN.README"
$ddDir      = Join-Path $ProjectRoot ("DragnDrop\{0}" -f $Phase)
$manifest   = Join-Path $humanDir "08.0_HUMAN.SYNC.MANIFEST.txt"
$logsDir    = Join-Path $ProjectRoot "03_ARTIFACTS\Logs"

if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runLog = Join-Path $logsDir ("DRAGNDROP.{0}.{1}.txt" -f $Phase, $stamp)
New-Item -ItemType File -Force -Path $runLog | Out-Null

Write-Log -File $runLog -Message ("RUN_START ProjectRoot={0} Phase={1} IncludeRadar={2}" -f $ProjectRoot,$Phase,$IncludeRadar)

if (-not (Test-Path -LiteralPath $manifest)) {
  Write-Log -File $runLog -Message ("Falta manifest: {0}" -f $manifest) -Level "ERROR"
  throw "Falta manifest: $manifest"
}

# Read manifest raw
$raw = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8

# Parse DD entries (stateful, tolera KEY: VALUE y KEY: en una línea + VALUE en la siguiente)
# We intentionally do NOT parse SYNC_ENTRY_ID. Only DD_COPY_ENTRY_ID blocks.
$lines = $raw -split '\r?\n'
$entries = @()
$current = @{}
$pendingKey = $null

function Flush-Entry {
  param([hashtable]$h)
  if ($h.Count -eq 0) { return }
  if (($h["PHASE"] -as [string]) -ne $Phase) { return }
  if (-not $h["SOURCE_FILE"] -or -not $h["TARGET_FILE"]) { return }

  $script:entries += [pscustomobject]@{
    Id     = $h["DD_COPY_ENTRY_ID"]
    Phase  = $h["PHASE"]
    Source = $h["SOURCE_FILE"]
    Target = $h["TARGET_FILE"]
    Mode   = $h["MODE"]
    Notes  = $h["NOTES"]
  }
}

foreach ($ln in $lines) {
  $t = $ln.Trim()

  if ([string]::IsNullOrWhiteSpace($t)) {
    continue
  }

  # Caso 1: venimos esperando el valor de una clave que quedó como "KEY:"
  if ($pendingKey) {
    $current[$pendingKey] = $t
    $pendingKey = $null
    continue
  }

  # Caso 2: inicia un nuevo bloque DD_COPY_ENTRY_ID
  if ($t -match '^DD_COPY_ENTRY_ID\.{2,}\s*:\s*(.*)$') {
    Flush-Entry -h $current
    $current = @{}
    $val = $Matches[1].Trim()
    if ($val) {
      $current["DD_COPY_ENTRY_ID"] = $val
    } else {
      $pendingKey = "DD_COPY_ENTRY_ID"
    }
    continue
  }

  # Caso 3: cualquier otra clave soportada
  if ($t -match '^(PHASE|SOURCE_FILE|TARGET_FILE|MODE|NOTES)\.{2,}\s*:\s*(.*)$') {
    $key = $Matches[1].Trim()
    $val = $Matches[2].Trim()

    if ($val) {
      $current[$key] = $val
    } else {
      $pendingKey = $key
    }
    continue
  }
}

Flush-Entry -h $current

if (@($entries).Count -eq 0) {
  Write-Log -File $runLog -Message ("FAIL_NO_DD_ENTRIES Phase={0} Manifest={1}" -f $Phase,$manifest) -Level "ERROR"
  throw "FAIL: no se encontraron DD_COPY_ENTRY_ID para $Phase en el manifest."
}

function Resolve-EntrySourcePath {
  param(
    [Parameter(Mandatory=$true)][pscustomobject]$Entry,
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$CurrentPhase,
    [Parameter(Mandatory=$true)][string]$LogFile
  )

  $srcAbs = Join-Path $Root $Entry.Source
  if (Test-Path -LiteralPath $srcAbs) {
    return $srcAbs
  }

  # Compat Phase0: START_RITUAL legacy (underscore) solo como fallback explícito.
  if (
    $CurrentPhase -eq "Phase0" -and
    ($Entry.Source -eq "HUMAN.README\09.0_HUMAN.START.RITUAL.txt")
  ) {
    $legacySrc = Join-Path $Root "HUMAN.README\09.0_HUMAN.START_RITUAL.txt"
    if (Test-Path -LiteralPath $legacySrc) {
      Write-Log -File $LogFile -Message ("WARN_PHASE0_LEGACY_SOURCE {0} -> {1}" -f $legacySrc,$Entry.Source) -Level "WARN"
      return $legacySrc
    }
  }

  return $srcAbs
}


# Prepare dest (clean)
if (Test-Path -LiteralPath $ddDir) {
  Write-Log -File $runLog -Message ("CLEAN_DEST {0}" -f $ddDir)
  Get-ChildItem -LiteralPath $ddDir -Force -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} else {
  New-Item -ItemType Directory -Force -Path $ddDir | Out-Null
  Write-Log -File $runLog -Message ("CREATE_DEST {0}" -f $ddDir)
}

# Copy files
$copied = @()

foreach ($e in $entries) {
  $srcAbs = Resolve-EntrySourcePath -Entry $e -Root $ProjectRoot -CurrentPhase $Phase -LogFile $runLog
  $tgtAbs = Join-Path $ProjectRoot $e.Target
  $tgtParent = Split-Path -Parent $tgtAbs

  if (-not (Test-Path -LiteralPath $tgtParent)) {
    New-Item -ItemType Directory -Force -LiteralPath $tgtParent | Out-Null
  }

  # Determinismo: si el manifest lo declara, debe existir.
  if (-not (Test-Path -LiteralPath $srcAbs)) {
    Write-Log -File $runLog -Message ("FAIL_SOURCE_MISSING id={0} src={1}" -f $e.Id,$e.Source) -Level "ERROR"
    throw "FAIL: falta source requerido: $srcAbs"
  }

  Copy-Item -LiteralPath $srcAbs -Destination $tgtAbs -Force
  $copied += (Split-Path -Leaf $tgtAbs)
  Write-Log -File $runLog -Message ("COPIED id={0} {1} -> {2}" -f $e.Id,$e.Source,$e.Target)
}
# Optional RADAR toggle (DEFAULT NONE)
$radarDir = Join-Path $ProjectRoot "03_ARTIFACTS\RADAR"

if ($IncludeRadar -ne "None") {
  if (-not (Test-Path -LiteralPath $radarDir)) {
    Write-Log -File $runLog -Message ("WARN IncludeRadar={0} pero no existe RADAR dir: {1}" -f $IncludeRadar,$radarDir) -Level "WARN"
  } else {
    $radarWanted = @("Radar.Index.ACTIVE.txt")
    if ($IncludeRadar -eq "IndexLite") {
      $radarWanted += "Radar.Lite.ACTIVE.txt"
    }

    foreach ($rf in $radarWanted) {
      $srcRadar = Join-Path $radarDir $rf
      $dstRadar = Join-Path $ddDir $rf

      if (-not (Test-Path -LiteralPath $srcRadar)) {
        Write-Log -File $runLog -Message ("WARN_RADAR_MISSING {0}" -f $srcRadar) -Level "WARN"
        continue
      }

      Copy-Item -LiteralPath $srcRadar -Destination $dstRadar -Force
      $copied += $rf
      Write-Log -File $runLog -Message ("COPIED_RADAR {0} -> DragnDrop\{1}\{2}" -f $srcRadar,$Phase,$rf)
    }
  }
}

# Generate README (contract determinista para tester + peatón)
$readme = Join-Path $ddDir "README.txt"

$readmeLines = New-Object System.Collections.Generic.List[string]
$readmeLines.Add("HIA_DRAGNDROP_README") | Out-Null
$readmeLines.Add(("DATE......: {0}" -f (Get-Date).ToString("yyyy-MM-dd"))) | Out-Null
$readmeLines.Add(("TIME......: {0}" -f (Get-Date).ToString("HH:mm"))) | Out-Null
$readmeLines.Add("TZ........: America/Santiago") | Out-Null
$readmeLines.Add("CITY......: Santiago, Chile") | Out-Null
$readmeLines.Add("VERSION...: v1.1-DRAFT") | Out-Null

# Literales exigidos por tester
$readmeLines.Add(("PHASE: {0}" -f $Phase)) | Out-Null
$readmeLines.Add(("INCLUDE_RADAR: {0}" -f $IncludeRadar)) | Out-Null
$readmeLines.Add(("GENERATED.: {0}" -f $stamp)) | Out-Null
$readmeLines.Add("RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.") | Out-Null
$readmeLines.Add("RULES.....: PROHIBIDO EDITAR A MANO.") | Out-Null
$readmeLines.Add("") | Out-Null

$readmeLines.Add("FILES_INCLUDED (copiados desde HUMAN.README y/o framework):") | Out-Null
foreach ($c in $copied | Sort-Object) { $readmeLines.Add((" - {0}" -f $c)) | Out-Null }
$readmeLines.Add("") | Out-Null

# Contract para IA cloud (reduce alucinación)
$readmeLines.Add("CLOUD_CONTRACT:") | Out-Null
$readmeLines.Add("- Responde PRIMERO: acuso leído") | Out-Null
$readmeLines.Add("- Luego lista exacta de archivos leídos (uno por línea)") | Out-Null
$readmeLines.Add("- Si falta un requerido: FAIL determinista") | Out-Null
$readmeLines.Add("- Si inventa un archivo: FAIL (alucinación)") | Out-Null
$readmeLines.Add("") | Out-Null
$readmeLines.Add("IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).") | Out-Null

$readmeLines | Set-Content -LiteralPath $readme -Encoding UTF8
Write-Log -File $runLog -Message ("README_WRITTEN {0}" -f $readme)

exit 0
