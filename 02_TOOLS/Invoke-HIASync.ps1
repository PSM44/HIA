<# 
========================================================================================
SCRIPT:      Invoke-HIASync.ps1
ID_UNICO:    HIA.TOOL.SYNC.0002
VERSION:     v1.1-DRAFT
FECHA:       2026-02-28
HORA:        HH:MM (America/Santiago)
CIUDAD:      <CIUDAD>, <PAIS>

OBJETIVO:
  Ejecutar sincronización FULL-copy de bloques DERIVED en archivos HUMAN, consumiendo:
  HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt

CAMBIOS CLAVE (v1.1):
  - APPLY atómico por target: valida todos los DERIVED blocks primero, luego aplica en memoria y escribe 1 vez por archivo.
  - Evita APPLY parcial (tu bug de "aplica 2 y falla en el 3°").
  - Resolver SOURCE_DOC_ID tolerante: ID_UNICO\.+: (padding de puntos variable) y valor en misma línea o siguiente.

REGLAS:
  - MODE=FULL => copia completa del bloque fuente (no resumen).
  - Solo reemplaza contenido entre:
      <<<DERIVED_BEGIN ID=<DERIVED_BLOCK_ID> ... >>>
      <<<DERIVED_END ID=<DERIVED_BLOCK_ID>>>
  - Fail-fast si falta BEGIN/END, si no existe source por ID_UNICO, o no existe WBS en source.

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
  [string]$ManifestRelativePath = "HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-HIADirectory([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Write-RunLog([string]$Path, [string]$Line) {
  $dir = Split-Path -Parent $Path
  if(-not (Test-Path -LiteralPath $dir)){
    New-Item -ItemType Directory -LiteralPath $dir -Force | Out-Null
  }
  # Append (no overwrite): reduce spam de -WhatIf y conserva evidencia completa.
  Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8
}

function Fail([string]$LogPath, [string]$Message) {
  Write-RunLog $LogPath ("FAIL: {0}" -f $Message)
  throw $Message
}

if ($ProjectRoot -match '<PROJECT_ROOT>' -or $ProjectRoot -match '^\s*<.*>\s*$') {
  throw "ProjectRoot contiene placeholder '<PROJECT_ROOT>'. Reemplázalo por la ruta real (ej: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA)."
}

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

$HumanDir = Join-Path $ProjectRoot "HUMAN.README"
$ArtifactsDir = Join-Path $ProjectRoot "03_ARTIFACTS"
$LogsDir = Join-Path $ArtifactsDir "LOGS"
New-HIADirectory $ArtifactsDir
New-HIADirectory $LogsDir

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$runLog = Join-Path $LogsDir ("SYNC.RUNNER.{0}.txt" -f $ts)
New-Item -ItemType File -LiteralPath $runLog -Force | Out-Null

$manifestPath = Join-Path $ProjectRoot $ManifestRelativePath
Write-RunLog $runLog ("RUN_START: ProjectRoot={0}" -f $ProjectRoot)
Write-RunLog $runLog ("MANIFEST: {0}" -f $manifestPath)

if (-not (Test-Path -Path $manifestPath)) {
  Fail $runLog "Manifest no existe: $manifestPath"
}

function Parse-Manifest([string]$path) {
  $lines = Get-Content -Path $path
  $entries = New-Object System.Collections.Generic.List[hashtable]
  $cur = @{}

  foreach ($ln in $lines) {
    $line = $ln.TrimEnd()

    if ($line -match '^SYNC_ENTRY_ID') {
      if ($cur.ContainsKey('SYNC_ENTRY_ID')) {
        $entries.Add($cur) | Out-Null
        $cur = @{}
      }
      $cur['SYNC_ENTRY_ID'] = ($line -split ':\s*',2)[1].Trim()
      continue
    }

    foreach ($k in @('SOURCE_DOC_ID','SOURCE_SECTION_WBS','TARGET_FILE','DERIVED_BLOCK_ID','MODE','NOTES')) {
      if ($line -match ("^" + [regex]::Escape($k) + "\.+:\s*")) {
        $cur[$k] = ($line -split ':\s*',2)[1].Trim()
      }
    }
  }

  if ($cur.ContainsKey('SYNC_ENTRY_ID')) { $entries.Add($cur) | Out-Null }
  return $entries
}

function Find-FileByDocId([string]$docId, [string]$searchDir) {
  $files = Get-ChildItem -Path $searchDir -File -Filter "*.txt" -Recurse -ErrorAction Stop
  foreach ($f in $files) {
    try {
      $raw = Get-Content -Path $f.FullName -Raw -ErrorAction Stop
      if ($raw -match ("(?ms)^ID_UNICO\.+:\s*(?:\r?\n\s*)?" + [regex]::Escape($docId) + "\s*$")) {
        return $f.FullName
      }
    } catch { }
  }
  return $null
}

function Extract-WbsSection([string]$filePath, [string]$wbs, [string]$log) {
  $raw = Get-Content -Path $filePath -Raw

  $patternStart = "(?ms)^={10,}\s*\r?\n" + [regex]::Escape($wbs) + "_.*?\r?\n={10,}\s*\r?\n"
  $m = [regex]::Match($raw, $patternStart)
  if (-not $m.Success) {
    Fail $log "No se encontró sección WBS '$wbs' en source: $filePath"
  }

  $startIndex = $m.Index + $m.Length
  $patternNext = "(?ms)^={10,}\s*\r?\n\d{2}\.\d{2}_.*?\r?\n={10,}\s*\r?\n"
  $m2 = [regex]::Match($raw.Substring($startIndex), $patternNext)
  if ($m2.Success) { return $raw.Substring($startIndex, $m2.Index).TrimEnd() }
  return $raw.Substring($startIndex).TrimEnd()
}

function Require-DerivedMarkers([string]$raw, [string]$derivedId, [string]$targetPath, [string]$log) {
  $beginNeed = "<<<DERIVED_BEGIN ID=$derivedId"
  $endNeed   = "<<<DERIVED_END ID=$derivedId"
  if ($raw -notmatch [regex]::Escape($beginNeed)) {
    Fail $log "No se encontró DERIVED_BEGIN para ID=$derivedId en $targetPath"
  }
  if ($raw -notmatch [regex]::Escape($endNeed)) {
    Fail $log "No se encontró DERIVED_END para ID=$derivedId en $targetPath"
  }
}

function Replace-DerivedInText([string]$raw, [string]$derivedId, [string]$payload, [string]$mode, [string]$log) {
  if ($mode -ne "FULL") { return @{ changed=$false; text=$raw } }

  $beginPattern = "<<<DERIVED_BEGIN\s+ID=" + [regex]::Escape($derivedId) + "\s+SOURCE=.*?MODE=.*?>>>\s*\r?\n"
  $endPattern   = "\r?\n<<<DERIVED_END\s+ID=" + [regex]::Escape($derivedId) + ">>>"

  $begin = [regex]::Match($raw, $beginPattern)
  if (-not $begin.Success) { Fail $log "No se encontró DERIVED_BEGIN para ID=$derivedId" }

  $end = [regex]::Match($raw, $endPattern)
  if (-not $end.Success) { Fail $log "No se encontró DERIVED_END para ID=$derivedId" }

  $start = $begin.Index + $begin.Length
  $stop  = $end.Index
  if ($stop -lt $start) { Fail $log "DERIVED_END antes de DERIVED_BEGIN para ID=$derivedId" }

  $before = $raw.Substring(0, $start)
  $after  = $raw.Substring($stop)
  $newPayload = $payload.TrimEnd() + "`r`n"
  $newRaw = $before + $newPayload + $after
  return @{ changed=($newRaw -ne $raw); text=$newRaw }
}

$entries = Parse-Manifest $manifestPath
if ($entries.Count -eq 0) { Fail $runLog "Manifest sin entries." }
Write-RunLog $runLog ("ENTRIES_COUNT: {0}" -f $entries.Count)

# Group entries by TARGET_FILE
$byTarget = @{}
foreach ($e in $entries) {
  $id   = $e['SYNC_ENTRY_ID']
  $src  = $e['SOURCE_DOC_ID']
  $wbs  = $e['SOURCE_SECTION_WBS']
  $tgt  = $e['TARGET_FILE']
  $did  = $e['DERIVED_BLOCK_ID']
  $mode = $e['MODE']

  if ([string]::IsNullOrWhiteSpace($src) -or [string]::IsNullOrWhiteSpace($wbs) -or [string]::IsNullOrWhiteSpace($tgt) -or [string]::IsNullOrWhiteSpace($did)) {
    Fail $runLog "Entry incompleta: $id"
  }

  if (-not $byTarget.ContainsKey($tgt)) {
    $byTarget[$tgt] = New-Object System.Collections.Generic.List[hashtable]
  }
  $byTarget[$tgt].Add($e) | Out-Null
}

# PRE-VALIDATION: verify all targets contain all DERIVED markers BEFORE any write
foreach ($tgt in $byTarget.Keys) {
  $tgtPath = Join-Path $ProjectRoot $tgt
  if (-not (Test-Path -Path $tgtPath)) { Fail $runLog "Target no existe: $tgtPath" }
  $raw = Get-Content -Path $tgtPath -Raw
  foreach ($e in $byTarget[$tgt]) {
    Require-DerivedMarkers -raw $raw -derivedId $e['DERIVED_BLOCK_ID'] -targetPath $tgtPath -log $runLog
  }
}

$applied = 0
$skipped = 0

foreach ($tgt in ($byTarget.Keys | Sort-Object)) {
  $tgtPath = Join-Path $ProjectRoot $tgt
  $raw = Get-Content -Path $tgtPath -Raw
  $newRaw = $raw
  $changedAny = $false

  foreach ($e in $byTarget[$tgt]) {
    $id   = $e['SYNC_ENTRY_ID']
    $src  = $e['SOURCE_DOC_ID']
    $wbs  = $e['SOURCE_SECTION_WBS']
    $did  = $e['DERIVED_BLOCK_ID']
    $mode = $e['MODE']

    Write-RunLog $runLog "ENTRY: $id source=$src::$wbs target=$tgt did=$did mode=$mode"

    $srcFile = Find-FileByDocId -docId $src -searchDir $HumanDir
    if (-not $srcFile) { Fail $runLog "No se encontró archivo fuente por ID_UNICO=$src en $HumanDir" }

    $payload = Extract-WbsSection -filePath $srcFile -wbs $wbs -log $runLog
    $r = Replace-DerivedInText -raw $newRaw -derivedId $did -payload $payload -mode $mode -log $runLog
    $newRaw = $r.text

    if ($r.changed) {
      $changedAny = $true
      $applied++
      Write-RunLog $runLog "PLANNED_APPLY: target=$tgtPath id=$did source=$src::$wbs bytes=$($payload.Length)"
    } else {
      $skipped++
      Write-RunLog $runLog "NOCHANGE: target=$tgtPath id=$did"
    }
  }

  if ($changedAny) {
    if ($PSCmdlet.ShouldProcess($tgtPath, "Write updated target file (atomic)")) {
      Set-Content -Path $tgtPath -Value $newRaw -NoNewline
      Write-RunLog $runLog "APPLY: target=$tgtPath"
    } else {
      Write-RunLog $runLog "WHATIF: target=$tgtPath"
    }
  }
}

Write-RunLog $runLog "SUMMARY: applied=$applied skipped=$skipped entries=$($entries.Count)"
Write-RunLog $runLog "RUN_END: OK"
exit 0
