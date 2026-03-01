<# 
========================================================================================
SCRIPT:      Invoke-HIASync.ps1
ID_UNICO:    HIA.TOOL.SYNC.0002
VERSION:     v1.1-DRAFT
FECHA:       2026-02-28
HORA:        HH:MM (America/Santiago)
CIUDAD:      <CIUDAD>, <PAIS>

OBJETIVO:
  Sincronización FULL-copy de bloques DERIVED en archivos HUMAN, consumiendo:
  HUMAN.README\HIA_SYN_0001_SYNC_MANIFEST.txt

MEJORAS v1.1 (P0):
  - APPLY atómico por archivo: pre-valida todos los bloques, aplica en memoria y escribe 1 vez por target.
  - Evita "apply parcial" por fallas a mitad de run.
  - Resuelve SOURCE por ID_UNICO con padding de puntos variable (ID_UNICO\.+:).

REGLAS:
  - MODE=FULL => copia completa (no resumen).
  - Solo reemplaza entre BEGIN/END del mismo DERIVED_BLOCK_ID.
  - Fail-fast si:
      - falta bloque DERIVED,
      - falta WBS en source,
      - falta source por ID_UNICO,
      - manifest incompleto.

COMO EJECUTAR:
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIASync.ps1 -ProjectRoot "C:\...\HIA"
  (simular) agregar: -WhatIf

EXIT:
  0 OK / 1 FAIL
========================================================================================
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
param(
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$false)]
  [string]$ManifestRelativePath = "HUMAN.README\HIA_SYN_0001_SYNC_MANIFEST.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------- Normalize root ----------
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

# ---------- Paths ----------
$HumanDir   = Join-Path $ProjectRoot "HUMAN.README"
$Artifacts  = Join-Path $ProjectRoot "03_ARTIFACTS"
$LogsDir    = Join-Path $Artifacts "LOGS"
$Manifest   = Join-Path $ProjectRoot $ManifestRelativePath

# ---------- Logging ----------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$RunLog = Join-Path $LogsDir "SYNC.RUNNER.$ts.txt"

function Ensure-Dir([string]$path) {
  if (-not (Test-Path -Path $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Write-Log([string]$Message) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Write-Host $line
  Add-Content -Path $RunLog -Value $line
}

function Fail([string]$msg) {
  Write-Log "FAIL: $msg"
  throw $msg
}

# ---------- Preflight ----------
if (-not (Test-Path -Path $ProjectRoot)) { throw "ProjectRoot no existe: $ProjectRoot" }
Ensure-Dir $Artifacts
Ensure-Dir $LogsDir

New-Item -ItemType File -Path $RunLog -Force | Out-Null
Write-Log "RUN_START: ProjectRoot=$ProjectRoot"
Write-Log "MANIFEST: $Manifest"

if (-not (Test-Path -Path $Manifest)) {
  Fail "Manifest no existe: $Manifest"
}

# ---------- Parse manifest ----------
function Parse-Manifest([string]$manifestPath) {
  $lines = Get-Content -Path $manifestPath
  $entries = New-Object System.Collections.Generic.List[hashtable]

  $current = @{}
  foreach ($ln in $lines) {
    $line = $ln.TrimEnd()

    if ($line -match '^SYNC_ENTRY_ID') {
      if ($current.ContainsKey('SYNC_ENTRY_ID')) {
        $entries.Add($current)
        $current = @{}
      }
      $current['SYNC_ENTRY_ID'] = ($line -split ':\s*',2)[1].Trim()
      continue
    }

    foreach ($k in @('SOURCE_DOC_ID','SOURCE_SECTION_WBS','TARGET_FILE','DERIVED_BLOCK_ID','MODE','NOTES')) {
      if ($line -match ("^" + [regex]::Escape($k) + "\.+:\s*")) {
        $current[$k] = ($line -split ':\s*',2)[1].Trim()
      }
    }
  }

  if ($current.ContainsKey('SYNC_ENTRY_ID')) { $entries.Add($current) }
  return $entries
}

$entries = Parse-Manifest $Manifest
if ($entries.Count -eq 0) { Fail "No se encontraron SYNC entries en manifest." }
Write-Log "ENTRIES_COUNT: $($entries.Count)"

# ---------- Resolve source doc id -> file path (HUMAN.README scope) ----------
function Find-FileByDocId([string]$docId, [string]$searchDir) {
  $files = Get-ChildItem -Path $searchDir -File -Filter "*.txt" -Recurse -ErrorAction Stop
  foreach ($f in $files) {
    try {
      $raw = Get-Content -Path $f.FullName -Raw -ErrorAction Stop
      # tolerate variable padding dots and (optional) newline after ':'
      if ($raw -match ("(?ms)^ID_UNICO\.+:\s*(?:\r?\n\s*)?" + [regex]::Escape($docId) + "\s*$")) {
        return $f.FullName
      }
    } catch { }
  }
  return $null
}

# ---------- Extract WBS section from source ----------
function Extract-WbsSection([string]$filePath, [string]$wbs) {
  $raw = Get-Content -Path $filePath -Raw

  $patternStart = "(?ms)^={10,}\s*\r?\n" + [regex]::Escape($wbs) + "_.*?\r?\n={10,}\s*\r?\n"
  $m = [regex]::Match($raw, $patternStart)
  if (-not $m.Success) {
    Fail "No se encontró sección WBS '$wbs' en source: $filePath"
  }

  $startIndex = $m.Index + $m.Length
  $patternNext = "(?ms)^={10,}\s*\r?\n\d{2}\.\d{2}_.*?\r?\n={10,}\s*\r?\n"
  $m2 = [regex]::Match($raw.Substring($startIndex), $patternNext)
  if ($m2.Success) {
    return $raw.Substring($startIndex, $m2.Index).TrimEnd()
  }
  return $raw.Substring($startIndex).TrimEnd()
}

# ---------- Replace derived block in a raw string ----------
function Replace-DerivedBlockInText {
  param(
    [Parameter(Mandatory=$true)][string]$raw,
    [Parameter(Mandatory=$true)][string]$derivedId,
    [Parameter(Mandatory=$true)][string]$payload,
    [Parameter(Mandatory=$true)][string]$mode
  )

  $beginPattern = "<<<DERIVED_BEGIN\s+ID=" + [regex]::Escape($derivedId) + "\s+SOURCE=.*?MODE=.*?>>>\s*\r?\n"
  $endPattern   = "\r?\n<<<DERIVED_END\s+ID=" + [regex]::Escape($derivedId) + ">>>"

  $begin = [regex]::Match($raw, $beginPattern)
  if (-not $begin.Success) { Fail "No se encontró DERIVED_BEGIN para ID=$derivedId" }

  $end = [regex]::Match($raw, $endPattern)
  if (-not $end.Success) { Fail "No se encontró DERIVED_END para ID=$derivedId" }

  if ($mode -ne "FULL") {
    return @{ changed = $false; text = $raw; note = "SKIP_MODE_NOT_FULL" }
  }

  $start = $begin.Index + $begin.Length
  $stop  = $end.Index
  if ($stop -lt $start) { Fail "DERIVED_END antes de DERIVED_BEGIN para ID=$derivedId" }

  $before = $raw.Substring(0, $start)
  $after  = $raw.Substring($stop)

  $newPayload = $payload.TrimEnd() + "`r`n"
  $newRaw = $before + $newPayload + $after

  return @{ changed = ($newRaw -ne $raw); text = $newRaw; note = "OK" }
}

# ---------- Group entries by target file ----------
$byTarget = @{}
foreach ($e in $entries) {
  $id    = $e['SYNC_ENTRY_ID']
  $srcId = $e['SOURCE_DOC_ID']
  $wbs   = $e['SOURCE_SECTION_WBS']
  $tgt   = $e['TARGET_FILE']
  $did   = $e['DERIVED_BLOCK_ID']
  $mode  = $e['MODE']

  if ([string]::IsNullOrWhiteSpace($srcId) -or [string]::IsNullOrWhiteSpace($wbs) -or [string]::IsNullOrWhiteSpace($tgt) -or [string]::IsNullOrWhiteSpace($did)) {
    Fail "Entry incompleta: $id"
  }

  if (-not $byTarget.ContainsKey($tgt)) { $byTarget[$tgt] = New-Object System.Collections.Generic.List[hashtable] }
  $byTarget[$tgt].Add($e) | Out-Null
}

# ---------- Pre-validate ALL targets contain ALL derived blocks BEFORE any write ----------
foreach ($tgt in $byTarget.Keys) {
  $tgtPath = Join-Path $ProjectRoot $tgt
  if (-not (Test-Path -Path $tgtPath)) { Fail "Target no existe: $tgtPath" }

  $raw = Get-Content -Path $tgtPath -Raw
  foreach ($e in $byTarget[$tgt]) {
    $did = $e['DERIVED_BLOCK_ID']
    $beginNeed = "<<<DERIVED_BEGIN ID=" + $did
    $endNeed   = "<<<DERIVED_END ID=" + $did
    if ($raw -notmatch [regex]::Escape($beginNeed)) {
      Fail "No se encontró DERIVED_BEGIN para ID=$did en $tgtPath"
    }
    if ($raw -notmatch [regex]::Escape($endNeed)) {
      Fail "No se encontró DERIVED_END para ID=$did en $tgtPath"
    }
  }
}

# ---------- Apply per target (atomic write) ----------
$appliedBlocks = 0
$skippedBlocks = 0

foreach ($tgt in ($byTarget.Keys | Sort-Object)) {
  $tgtPath = Join-Path $ProjectRoot $tgt
  $raw = Get-Content -Path $tgtPath -Raw
  $newRaw = $raw
  $changedAny = $false

  foreach ($e in $byTarget[$tgt]) {
    $id    = $e['SYNC_ENTRY_ID']
    $srcId = $e['SOURCE_DOC_ID']
    $wbs   = $e['SOURCE_SECTION_WBS']
    $did   = $e['DERIVED_BLOCK_ID']
    $mode  = $e['MODE']

    Write-Log "ENTRY: $id source=$srcId::$wbs target=$tgt did=$did mode=$mode"

    $srcFile = Find-FileByDocId -docId $srcId -searchDir $HumanDir
    if (-not $srcFile) { Fail "No se encontró archivo fuente por ID_UNICO=$srcId en $HumanDir" }

    $payload = Extract-WbsSection -filePath $srcFile -wbs $wbs
    $r = Replace-DerivedBlockInText -raw $newRaw -derivedId $did -payload $payload -mode $mode
    $newRaw = $r.text

    if ($r.note -eq "SKIP_MODE_NOT_FULL") {
      Write-Log "SKIP_MODE_NOT_FULL: target=$tgtPath id=$did mode=$mode"
      $skippedBlocks++
      continue
    }

    if ($r.changed) {
      $changedAny = $true
      $appliedBlocks++
      Write-Log "PLANNED_APPLY: target=$tgtPath id=$did source=$srcId::$wbs bytes=$($payload.Length)"
    } else {
      Write-Log "NOCHANGE: target=$tgtPath id=$did"
      $skippedBlocks++
    }
  }

  if ($changedAny) {
    if ($PSCmdlet.ShouldProcess($tgtPath, "Write updated target file (atomic)")) {
      Set-Content -Path $tgtPath -Value $newRaw -NoNewline
      Write-Log "WRITE: target=$tgtPath"
    } else {
      Write-Log "WHATIF_WRITE: target=$tgtPath"
    }
  }
}

Write-Log "SUMMARY: applied_blocks=$appliedBlocks skipped_blocks=$skippedBlocks entries=$($entries.Count)"
Write-Log "RUN_END: OK"
exit 0