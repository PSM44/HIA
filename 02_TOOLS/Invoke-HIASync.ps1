<# 
========================================================================================
SCRIPT:      Invoke-HIASync.ps1
ID_UNICO:    HIA.TOOL.SYNC.0002
VERSION:     v1.2-DRAFT
FECHA:       2026-04-26
HORA:        HH:MM (America/Santiago)
CIUDAD:      <CIUDAD>, <PAIS>

OBJETIVO:
  Ejecutar sincronización FULL-copy de bloques DERIVED en archivos HUMAN,
  y soportar chequeo de integridad de marcadores (sin aplicar cambios).

EXIT:
  0 OK / 1 FAIL
========================================================================================
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
param(
  [Parameter(Mandatory=$false)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$false)]
  [string]$ManifestRelativePath = "HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt",

  [Parameter(Mandatory=$false)]
  [ValidateSet("Apply", "Check")]
  [string]$Action = "Apply",

  [Parameter(Mandatory=$false)]
  [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-HIADirectory([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-RunLog([string]$Path, [string]$Line) {
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8
}

function Fail([string]$LogPath, [string]$Message) {
  Write-RunLog $LogPath ("FAIL: {0}" -f $Message)
  throw $Message
}

if ($CheckOnly.IsPresent) {
  $Action = "Check"
}

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
  $toolsRoot = Split-Path -Path $PSCommandPath -Parent
  $ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $toolsRoot ".."))
}
if ($ProjectRoot -match '<PROJECT_ROOT>' -or $ProjectRoot -match '^\s*<.*>\s*$') {
  throw "ProjectRoot contiene placeholder '<PROJECT_ROOT>'. Reemplázalo por la ruta real."
}

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

$HumanDir = Join-Path $ProjectRoot "HUMAN.README"
$ArtifactsDir = Join-Path $ProjectRoot "03_ARTIFACTS"
$LogsDir = Join-Path $ArtifactsDir "LOGS"
New-HIADirectory $ArtifactsDir
New-HIADirectory $LogsDir

$ts = Get-Date -Format "yyyyMMdd_HHmmss_fff"
$runLog = Join-Path $LogsDir ("SYNC.RUNNER.{0}.txt" -f $ts)
New-Item -ItemType File -Path $runLog -Force | Out-Null

$manifestPath = Join-Path $ProjectRoot $ManifestRelativePath
Write-RunLog $runLog ("RUN_START: ProjectRoot={0}" -f $ProjectRoot)
Write-RunLog $runLog ("ACTION: {0}" -f $Action)
Write-RunLog $runLog ("MANIFEST: {0}" -f $manifestPath)

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  Fail $runLog "Manifest no existe: $manifestPath"
}

function Parse-Manifest([string]$Path) {
  $lines = Get-Content -LiteralPath $Path
  $entries = New-Object System.Collections.Generic.List[hashtable]
  $cur = $null

  foreach ($ln in $lines) {
    $line = $ln.TrimEnd()

    if ($line -match '^DD_COPY_ENTRY_ID') {
      if ($null -ne $cur -and $cur.ContainsKey('SYNC_ENTRY_ID')) {
        $entries.Add($cur) | Out-Null
      }
      $cur = $null
      continue
    }

    if ($line -match '^SYNC_ENTRY_ID\.+:\s*(.+)$') {
      if ($null -ne $cur -and $cur.ContainsKey('SYNC_ENTRY_ID')) {
        $entries.Add($cur) | Out-Null
      }
      $cur = @{}
      $cur['SYNC_ENTRY_ID'] = $Matches[1].Trim()
      continue
    }

    if ($null -eq $cur) {
      continue
    }

    foreach ($k in @('SOURCE_DOC_ID','SOURCE_SECTION_WBS','TARGET_FILE','DERIVED_BLOCK_ID','MODE','NOTES')) {
      $pattern = '^' + [regex]::Escape($k) + '\.+:\s*(.*)$'
      if ($line -match $pattern) {
        $cur[$k] = $Matches[1].Trim()
      }
    }
  }

  if ($null -ne $cur -and $cur.ContainsKey('SYNC_ENTRY_ID')) {
    $entries.Add($cur) | Out-Null
  }

  return $entries
}

function Find-FileByDocId([string]$DocId, [string]$SearchDir) {
  $index = Get-SourceDocIndex -SearchDir $SearchDir
  if ($index.ById.ContainsKey($DocId)) {
    return [string]$index.ById[$DocId]
  }
  return $null
}

function Get-SourceDocIndex([string]$SearchDir) {
  $files = Get-ChildItem -Path $SearchDir -File -Filter "*.txt" -Recurse -ErrorAction Stop
  $byId = @{}
  $allIds = New-Object System.Collections.Generic.List[string]

  foreach ($f in $files) {
    try {
      $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop

      # Formato habitual: ID_UNICO..........: VALUE
      $inlineMatches = [regex]::Matches($raw, '(?im)^\s*ID_UNICO[^\r\n:]*:\s*(.+?)\s*$')
      foreach ($m in $inlineMatches) {
        $id = $m.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($id)) {
          if (-not $byId.ContainsKey($id)) {
            $byId[$id] = $f.FullName
          }
          $allIds.Add($id) | Out-Null
        }
      }

      # Formato alterno: "ID_UNICO" en línea propia y el valor en la siguiente.
      $multilineMatches = [regex]::Matches($raw, '(?im)^\s*ID_UNICO\s*$\r?\n\s*([A-Z0-9._-]+)\s*$')
      foreach ($m in $multilineMatches) {
        $id = $m.Groups[1].Value.Trim()
        if (-not [string]::IsNullOrWhiteSpace($id)) {
          if (-not $byId.ContainsKey($id)) {
            $byId[$id] = $f.FullName
          }
          $allIds.Add($id) | Out-Null
        }
      }
    } catch { }
  }

  return @{
    ById = $byId
    AllIds = @($allIds | Select-Object -Unique)
  }
}

function Get-ClosestSourceDocId {
  param(
    [Parameter(Mandatory=$true)]
    [string]$SourceDocId,
    [Parameter(Mandatory=$true)]
    [string[]]$Candidates
  )

  if ($Candidates.Count -eq 0) {
    return $null
  }

  $normalized = $SourceDocId.ToUpperInvariant()
  $noPrefix = $normalized -replace '^HIA\.', ''

  foreach ($candidate in $Candidates) {
    $cand = $candidate.ToUpperInvariant()
    if ($cand -eq ("HIA." + $normalized) -or ("HIA." + $cand) -eq $normalized) {
      return $candidate
    }
    if ($cand -eq ("HIA." + $noPrefix) -or $cand -eq $noPrefix) {
      return $candidate
    }
  }

  foreach ($candidate in $Candidates) {
    $cand = $candidate.ToUpperInvariant()
    if ($cand.Contains($normalized) -or $normalized.Contains($cand) -or $cand.Contains($noPrefix) -or $noPrefix.Contains($cand)) {
      return $candidate
    }
  }

  return $null
}

function Get-HIASourceDocIntegrityFailures {
  param(
    [Parameter(Mandatory=$true)]
    [System.Collections.Generic.List[hashtable]]$Entries,
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot
  )

  $failures = New-Object System.Collections.Generic.List[hashtable]
  $index = Get-SourceDocIndex -SearchDir $SourceRoot
  $byId = $index.ById
  $allIds = [string[]]$index.AllIds

  foreach ($e in $Entries) {
    $sourceDocId = [string]$e['SOURCE_DOC_ID']
    if (-not $byId.ContainsKey($sourceDocId)) {
      $closest = Get-ClosestSourceDocId -SourceDocId $sourceDocId -Candidates $allIds
      $failures.Add(@{
        SyncEntryId = [string]$e['SYNC_ENTRY_ID']
        SourceDocId = $sourceDocId
        SourceRoot = $SourceRoot
        Closest = $closest
      }) | Out-Null
    }
  }

  return $failures
}

function Extract-WbsSection([string]$FilePath, [string]$Wbs, [string]$Log) {
  $raw = Get-Content -LiteralPath $FilePath -Raw

  $patternStart = "(?ms)^={10,}\s*\r?\n" + [regex]::Escape($Wbs) + "_.*?\r?\n={10,}\s*\r?\n"
  $m = [regex]::Match($raw, $patternStart)
  if (-not $m.Success) {
    Fail $Log "No se encontró sección WBS '$Wbs' en source: $FilePath"
  }

  $startIndex = $m.Index + $m.Length
  $patternNext = "(?ms)^={10,}\s*\r?\n\d{2}\.\d{2}_.*?\r?\n={10,}\s*\r?\n"
  $m2 = [regex]::Match($raw.Substring($startIndex), $patternNext)
  if ($m2.Success) { return $raw.Substring($startIndex, $m2.Index).TrimEnd() }
  return $raw.Substring($startIndex).TrimEnd()
}

function Get-HIAMarkerIntegrityFailures {
  param(
    [Parameter(Mandatory=$true)]
    [System.Collections.Generic.List[hashtable]]$Entries,
    [Parameter(Mandatory=$true)]
    [string]$Root
  )

  $failures = New-Object System.Collections.Generic.List[hashtable]
  $cachedRawByTarget = @{}

  foreach ($e in $Entries) {
    $did = [string]$e['DERIVED_BLOCK_ID']
    $tgt = [string]$e['TARGET_FILE']
    $targetPath = Join-Path $Root $tgt

    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
      $failures.Add(@{ DerivedId = $did; TargetFile = $targetPath; Missing = "TARGET_FILE" }) | Out-Null
      continue
    }

    if (-not $cachedRawByTarget.ContainsKey($targetPath)) {
      $cachedRawByTarget[$targetPath] = Get-Content -LiteralPath $targetPath -Raw
    }
    $raw = [string]$cachedRawByTarget[$targetPath]

    $beginNeed = "<<<DERIVED_BEGIN ID=$did"
    $endNeed = "<<<DERIVED_END ID=$did"

    if ($raw -notmatch [regex]::Escape($beginNeed)) {
      $failures.Add(@{ DerivedId = $did; TargetFile = $targetPath; Missing = "DERIVED_BEGIN" }) | Out-Null
    }
    if ($raw -notmatch [regex]::Escape($endNeed)) {
      $failures.Add(@{ DerivedId = $did; TargetFile = $targetPath; Missing = "DERIVED_END" }) | Out-Null
    }
  }

  return $failures
}

function Replace-DerivedInText([string]$Raw, [string]$DerivedId, [string]$Payload, [string]$Mode, [string]$Log) {
  if ($Mode -ne "FULL") { return @{ changed=$false; text=$Raw } }

  $beginPattern = "<<<DERIVED_BEGIN\s+ID=" + [regex]::Escape($DerivedId) + "\s+SOURCE=.*?MODE=.*?>>>\s*\r?\n"
  $endPattern   = "\r?\n<<<DERIVED_END\s+ID=" + [regex]::Escape($DerivedId) + ">>>"

  $begin = [regex]::Match($Raw, $beginPattern)
  if (-not $begin.Success) { Fail $Log "No se encontró DERIVED_BEGIN para ID=$DerivedId" }

  $end = [regex]::Match($Raw, $endPattern)
  if (-not $end.Success) { Fail $Log "No se encontró DERIVED_END para ID=$DerivedId" }

  $start = $begin.Index + $begin.Length
  $stop  = $end.Index
  if ($stop -lt $start) { Fail $Log "DERIVED_END antes de DERIVED_BEGIN para ID=$DerivedId" }

  $before = $Raw.Substring(0, $start)
  $after  = $Raw.Substring($stop)
  $newPayload = $Payload.TrimEnd() + "`r`n"
  $newRaw = $before + $newPayload + $after
  return @{ changed=($newRaw -ne $Raw); text=$newRaw }
}

$entries = @(Parse-Manifest -Path $manifestPath)
if ($entries.Count -eq 0) { Fail $runLog "Manifest sin entries SYNC_ENTRY_ID." }
Write-RunLog $runLog ("ENTRIES_COUNT: {0}" -f $entries.Count)

foreach ($e in $entries) {
  foreach ($required in @('SOURCE_DOC_ID','SOURCE_SECTION_WBS','TARGET_FILE','DERIVED_BLOCK_ID')) {
    if ([string]::IsNullOrWhiteSpace([string]$e[$required])) {
      Fail $runLog ("Entry incompleta ({0}) en {1}" -f $required, $e['SYNC_ENTRY_ID'])
    }
  }
}

$integrityFailures = @(Get-HIAMarkerIntegrityFailures -Entries $entries -Root $ProjectRoot)
if ($integrityFailures.Count -gt 0) {
  foreach ($f in $integrityFailures) {
    $msg = "MARKER_MISSING: derived_id={0} target={1} missing={2}" -f $f.DerivedId, $f.TargetFile, $f.Missing
    Write-Host $msg -ForegroundColor Red
    Write-RunLog $runLog $msg
  }
  Write-RunLog $runLog "RUN_END: FAIL (marker integrity)"
  exit 1
}

Write-Host "OK: sync marker integrity check passed"
Write-RunLog $runLog "MARKER_INTEGRITY: OK"

$sourceDocFailures = @(Get-HIASourceDocIntegrityFailures -Entries $entries -SourceRoot $HumanDir)
if ($sourceDocFailures.Count -gt 0) {
  foreach ($f in $sourceDocFailures) {
    $msg = "SOURCE_DOC_MISSING: sync_entry_id={0} source_doc_id={1} root={2} closest={3}" -f $f.SyncEntryId, $f.SourceDocId, $f.SourceRoot, ($(if ($null -ne $f.Closest) { $f.Closest } else { "" }))
    Write-Host $msg -ForegroundColor Red
    Write-RunLog $runLog $msg
  }
  Write-RunLog $runLog "RUN_END: FAIL (source doc integrity)"
  exit 1
}

Write-Host "OK: source doc ID integrity check passed"
Write-RunLog $runLog "SOURCE_DOC_INTEGRITY: OK"

if ($Action -eq "Check") {
  Write-RunLog $runLog "RUN_END: OK (check only)"
  exit 0
}

# APPLY MODE
$byTarget = @{}
foreach ($e in $entries) {
  $tgt = [string]$e['TARGET_FILE']
  if (-not $byTarget.ContainsKey($tgt)) {
    $byTarget[$tgt] = New-Object System.Collections.Generic.List[hashtable]
  }
  $byTarget[$tgt].Add($e) | Out-Null
}

$applied = 0
$skipped = 0

foreach ($tgt in ($byTarget.Keys | Sort-Object)) {
  $tgtPath = Join-Path $ProjectRoot $tgt
  $raw = Get-Content -LiteralPath $tgtPath -Raw
  $newRaw = $raw
  $changedAny = $false

  foreach ($e in $byTarget[$tgt]) {
    $id   = [string]$e['SYNC_ENTRY_ID']
    $src  = [string]$e['SOURCE_DOC_ID']
    $wbs  = [string]$e['SOURCE_SECTION_WBS']
    $did  = [string]$e['DERIVED_BLOCK_ID']
    $mode = [string]$e['MODE']

    Write-RunLog $runLog ("ENTRY: {0} source={1}::{2} target={3} did={4} mode={5}" -f $id, $src, $wbs, $tgt, $did, $mode)

    $srcFile = Find-FileByDocId -DocId $src -SearchDir $HumanDir
    if (-not $srcFile) { Fail $runLog "No se encontró archivo fuente por ID_UNICO=$src en $HumanDir" }

    $payload = Extract-WbsSection -FilePath $srcFile -Wbs $wbs -Log $runLog
    $r = Replace-DerivedInText -Raw $newRaw -DerivedId $did -Payload $payload -Mode $mode -Log $runLog
    $newRaw = [string]$r.text

    if ([bool]$r.changed) {
      $changedAny = $true
      $applied++
      Write-RunLog $runLog ("PLANNED_APPLY: target={0} id={1} source={2}::{3} bytes={4}" -f $tgtPath, $did, $src, $wbs, $payload.Length)
    }
    else {
      $skipped++
      Write-RunLog $runLog ("NOCHANGE: target={0} id={1}" -f $tgtPath, $did)
    }
  }

  if ($changedAny) {
    if (-not $WhatIfPreference) {
      Set-Content -Path $tgtPath -Value $newRaw -NoNewline
      Write-RunLog $runLog ("APPLY: target={0}" -f $tgtPath)
    }
    else {
      Write-RunLog $runLog ("WHATIF: target={0}" -f $tgtPath)
    }
  }
}

Write-RunLog $runLog ("SUMMARY: applied={0} skipped={1} entries={2}" -f $applied, $skipped, $entries.Count)
Write-RunLog $runLog "RUN_END: OK"
exit 0


