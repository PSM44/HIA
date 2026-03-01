<# 
========================================================================================
SCRIPT:      Invoke-HIASync.ps1
ID_UNICO:    HIA.TOOL.SYNC.0001
VERSION:     v1.0-DRAFT
FECHA:       2026-02-27
CIUDAD:      <CIUDAD>, <PAIS>

OBJETIVO:
  Ejecutar sincronización FULL-copy de bloques DERIVED en archivos HUMAN, consumiendo
  HUMAN.README\HIA_SYN_0001_SYNC_MANIFEST.txt.

COMPORTAMIENTO:
  - Por cada SYNC_ENTRY:
    1) Carga el SOURCE_DOC_ID + SOURCE_SECTION_WBS desde el manifiesto
    2) Resuelve archivo fuente buscando en HUMAN.README por "ID_UNICO..........: <SOURCE_DOC_ID>"
    3) Extrae el bloque fuente por WBS (ej. 04.00) usando delimitadores "=========="
    4) Reemplaza el bloque destino entre:
         <<<DERIVED_BEGIN ID=<DERIVED_BLOCK_ID> ...>>>
         <<<DERIVED_END   ID=<DERIVED_BLOCK_ID>>>
       con el contenido fuente (FULL-copy)
  - Registra log detallado en 03_ARTIFACTS\LOGS\SYNC.RUNNER.<timestamp>.txt
  - Soporta -WhatIf

REQUISITOS:
  - Archivos canónicos deben tener secciones WBS delimitadas por:
      ==========
      04.00_TITULO
      ==========
  - Bloques DERIVED en targets deben tener BEGIN/END con el mismo DERIVED_BLOCK_ID.

COMO EJECUTAR:
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIASync.ps1 -ProjectRoot "C:\...\HIA"
  (simular) agregar: -WhatIf

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

# ---------- 00.10 Normalize root ----------
$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)

# ---------- 00.20 Paths ----------
$HumanDir   = Join-Path $ProjectRoot "HUMAN.README"
$Artifacts  = Join-Path $ProjectRoot "03_ARTIFACTS"
$LogsDir    = Join-Path $Artifacts "LOGS"
$Manifest   = Join-Path $ProjectRoot $ManifestRelativePath

# ---------- 00.30 Logging ----------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$RunLog = Join-Path $LogsDir "SYNC.RUNNER.$ts.txt"

function Write-Log {
  param([Parameter(Mandatory=$true)][string]$Message)
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Write-Host $line
  Add-Content -Path $RunLog -Value $line
}

function Fail([string]$msg) {
  Write-Log "FAIL: $msg"
  throw $msg
}

function Ensure-Dir([string]$path) {
  if (-not (Test-Path -Path $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

# ---------- 01.00 Preflight ----------
if (-not (Test-Path -Path $ProjectRoot)) { throw "ProjectRoot no existe: $ProjectRoot" }
Ensure-Dir $Artifacts
Ensure-Dir $LogsDir

New-Item -ItemType File -Path $RunLog -Force | Out-Null
Write-Log "RUN_START: ProjectRoot=$ProjectRoot"
Write-Log "MANIFEST: $Manifest"

if (-not (Test-Path -Path $Manifest)) {
  Fail "Manifest no existe: $Manifest"
}

# ---------- 02.00 Parse manifest ----------
# Manifest format: repeated blocks with lines like:
# SOURCE_DOC_ID........: HUMAN.PF0.0001
# SOURCE_SECTION_WBS...: 04.00
# TARGET_FILE..........: HUMAN.README\HUMAN.USER.0001.txt
# DERIVED_BLOCK_ID.....: DERIVED.PF0.RITUALS.USER.0001
# MODE.................: FULL

function Parse-Manifest([string]$manifestPath) {
  $lines = Get-Content -Path $manifestPath
  $entries = New-Object System.Collections.Generic.List[hashtable]

  $current = @{}
  foreach ($ln in $lines) {
    $line = $ln.TrimEnd()

    if ($line -match '^SYNC_ENTRY_ID') {
      if ($current.ContainsKey('SYNC_ENTRY_ID')) {
        # commit previous
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

# ---------- 03.00 Resolve source doc id -> file path ----------
function Find-FileByDocId([string]$docId, [string]$searchDir) {
  $files = Get-ChildItem -Path $searchDir -File -Filter "*.txt" -Recurse -ErrorAction Stop
  foreach ($f in $files) {
    try {
      $raw = Get-Content -Path $f.FullName -Raw -ErrorAction Stop
if ($raw -match ("(?ms)^ID_UNICO\.+:\s*(?:\r?\n\s*)?" + [regex]::Escape($docId) + "\s*$")) {
  return $f.FullName
}
    } catch {
      # ignore unreadable
    }
  }
  return $null
}

# ---------- 04.00 Extract WBS section from a canonical file ----------
function Extract-WbsSection([string]$filePath, [string]$wbs) {
  $raw = Get-Content -Path $filePath -Raw

  # Find the header: ==========\n<wbs>_<anything>\n========== 
  $patternStart = "(?ms)^={10,}\s*\r?\n" + [regex]::Escape($wbs) + "_.*?\r?\n={10,}\s*\r?\n"
  $m = [regex]::Match($raw, $patternStart)
  if (-not $m.Success) {
    Fail "No se encontró sección WBS '$wbs' en source: $filePath (esperado: '==========', '$wbs_...', '==========')."
  }

  $startIndex = $m.Index + $m.Length

  # Find next section header (==========\nNN.NN_...)
  $patternNext = "(?ms)^={10,}\s*\r?\n\d{2}\.\d{2}_.*?\r?\n={10,}\s*\r?\n"
  $m2 = [regex]::Match($raw, $patternNext, [System.Text.RegularExpressions.RegexOptions]::Multiline, $startIndex)
  if ($m2.Success) {
    $len = $m2.Index - $startIndex
    return $raw.Substring($startIndex, $len).TrimEnd()
  }

  # If none, take to end
  return $raw.Substring($startIndex).TrimEnd()
}


# ---------- 04.00 Extract WBS section from a canonical file (NO Add-Type) ----------
function Extract-WbsSectionSafe {
  param(
    [Parameter(Mandatory=$true)][string]$FilePath,
    [Parameter(Mandatory=$true)][string]$Wbs
  )

  $raw = Get-Content -Path $FilePath -Raw

  # Start header: ==========\n<WBS>_<anything>\n==========
  $patternStart = "(?ms)^={10,}\s*\r?\n" + [regex]::Escape($Wbs) + "_.*?\r?\n={10,}\s*\r?\n"
  $m = [regex]::Match($raw, $patternStart)
  if (-not $m.Success) {
    Fail "No se encontró sección WBS '$Wbs' en source: $FilePath (esperado: '==========', '$Wbs_...', '==========')."
  }

  $startIndex = $m.Index + $m.Length

  # Next header (from startIndex) by substring match
  $patternNext = "(?ms)^={10,}\s*\r?\n\d{2}\.\d{2}_.*?\r?\n={10,}\s*\r?\n"
  $sub = $raw.Substring($startIndex)
  $m2 = [regex]::Match($sub, $patternNext)

  if ($m2.Success) {
    $endIndex = $startIndex + $m2.Index
    return $raw.Substring($startIndex, $endIndex - $startIndex).TrimEnd()
  }

  # No next header => to end
  return $raw.Substring($startIndex).TrimEnd()
}

# ---------- 05.00 Replace derived block in target ----------
function Replace-DerivedBlock {
  param(
    [Parameter(Mandatory=$true)][string]$targetPath,
    [Parameter(Mandatory=$true)][string]$derivedId,
    [Parameter(Mandatory=$true)][string]$sourceDocId,
    [Parameter(Mandatory=$true)][string]$sourceWbs,
    [Parameter(Mandatory=$true)][string]$mode,
    [Parameter(Mandatory=$true)][string]$payload
  )

  if (-not (Test-Path -Path $targetPath)) {
    Fail "Target no existe: $targetPath"
  }

  $raw = Get-Content -Path $targetPath -Raw

  $beginPattern = "<<<DERIVED_BEGIN\s+ID=" + [regex]::Escape($derivedId) + "\s+SOURCE=.*?MODE=.*?>>>\s*\r?\n"
  $endPattern   = "\r?\n<<<DERIVED_END\s+ID=" + [regex]::Escape($derivedId) + ">>>"

  $begin = [regex]::Match($raw, $beginPattern)
  if (-not $begin.Success) { Fail "No se encontró DERIVED_BEGIN para ID=$derivedId en $targetPath" }

  $end = [regex]::Match($raw, $endPattern)
  if (-not $end.Success) { Fail "No se encontró DERIVED_END para ID=$derivedId en $targetPath" }

  if ($mode -ne "FULL") {
    Write-Log "SKIP_MODE_NOT_FULL: target=$targetPath id=$derivedId mode=$mode"
    return $false
  }

  $start = $begin.Index + $begin.Length
  $stop  = $end.Index

  if ($stop -lt $start) { Fail "DERIVED_END antes de DERIVED_BEGIN para ID=$derivedId en $targetPath" }

  $before = $raw.Substring(0, $start)
  $after  = $raw.Substring($stop)

  $newPayload = $payload.TrimEnd() + "`r`n"
  $newRaw = $before + $newPayload + $after

  if ($newRaw -eq $raw) {
    Write-Log "NOCHANGE: target=$targetPath id=$derivedId"
    return $false
  }

  if ($PSCmdlet.ShouldProcess($targetPath, "Replace DERIVED block ID=$derivedId from $sourceDocId::$sourceWbs")) {
    Set-Content -Path $targetPath -Value $newRaw -NoNewline
    Write-Log "APPLY: target=$targetPath id=$derivedId source=$sourceDocId::$sourceWbs bytes=$($newPayload.Length)"
    return $true
  }

  Write-Log "WHATIF: target=$targetPath id=$derivedId source=$sourceDocId::$sourceWbs"
  return $false
}

# ---------- 06.00 Run entries ----------
$applied = 0
$skipped = 0

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

  $tgtPath = Join-Path $ProjectRoot $tgt

  Write-Log "ENTRY: $id source=$srcId::$wbs target=$tgt did=$did mode=$mode"

  $srcFile = Find-FileByDocId -docId $srcId -searchDir $HumanDir
  if (-not $srcFile) { Fail "No se encontró archivo fuente por ID_UNICO=$srcId en $HumanDir" }

  $payload = Extract-WbsSectionSafe -filePath $srcFile -wbs $wbs

  $changed = Replace-DerivedBlock -targetPath $tgtPath -derivedId $did -sourceDocId $srcId -sourceWbs $wbs -mode $mode -payload $payload

  if ($changed) { $applied++ } else { $skipped++ }
}

Write-Log "SUMMARY: applied=$applied skipped=$skipped entries=$($entries.Count)"
Write-Log "RUN_END: OK"
exit 0