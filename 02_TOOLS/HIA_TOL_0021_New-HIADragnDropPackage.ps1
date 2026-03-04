<#
========================================================================================
SCRIPT:   HIA_TOL_0021_New-HIADragnDropPackage.ps1
ID_UNICO: HIA.TOL.DRAGNDROP.0001
DATE......: 2026-03-03
TIME......: HH:MM
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.0-DRAFT

OBJETIVO:
  Generar DragnDrop\<Phase>\ como build output (generated-only) a partir de HUMAN.README,
  sin zip (adjuntos sueltos para IA cloud).

FUENTE DE VERDAD:
  HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt :: sección 02.50 (DD_COPY_ENTRY_ID...)

SEGURIDAD:
  - NO usa Validate-* (verbos no aprobados).
  - Limpia destino antes de copiar (para evitar drift).
  - WARN (no FAIL) si entry opcional no existe (BATON).

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
  [string]$Phase
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

if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -ItemType Directory -Force -LiteralPath $logsDir | Out-Null }
$stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runLog = Join-Path $logsDir ("DRAGNDROP.{0}.{1}.txt" -f $Phase, $stamp)
New-Item -ItemType File -Force -LiteralPath $runLog | Out-Null

Write-Log -File $runLog -Message ("RUN_START ProjectRoot={0} Phase={1}" -f $ProjectRoot,$Phase)

if (-not (Test-Path -LiteralPath $manifest)) {
  Write-Log -File $runLog -Message ("Falta manifest: {0}" -f $manifest) -Level "ERROR"
  throw "Falta manifest: $manifest"
}

# Read manifest raw
$raw = Get-Content -LiteralPath $manifest -Raw -Encoding UTF8

# Parse DD entries (simple/stateful)
# We intentionally do NOT parse SYNC_ENTRY_ID. Only DD_COPY_ENTRY_ID blocks.
$lines = $raw -split "`r?`n"
$entries = @()
$current = @{}

function Flush-Entry {
  param([hashtable]$h)
  if ($h.Count -eq 0) { return }
  if (($h["PHASE"] -as [string]) -ne $Phase) { return }
  if (-not $h["SOURCE_FILE"] -or -not $h["TARGET_FILE"]) { return }
  $entries += [pscustomobject]@{
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
  if ($t -like "DD_COPY_ENTRY_ID*:*") {
    Flush-Entry -h $current
    $current = @{}
  }
  if ($t -match "^(DD_COPY_ENTRY_ID|PHASE|SOURCE_FILE|TARGET_FILE|MODE|NOTES)\s*:\s*(.*)$") {
    $key = $Matches[1].Trim()
    $val = $Matches[2].Trim()
    $current[$key] = $val
  }
}
Flush-Entry -h $current

Write-Log -File $runLog -Message ("DD_ENTRIES_FOUND count={0}" -f @($entries).Count)

# Prepare dest (clean)
if (Test-Path -LiteralPath $ddDir) {
  Write-Log -File $runLog -Message ("CLEAN_DEST {0}" -f $ddDir)
  Get-ChildItem -LiteralPath $ddDir -Force -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
} else {
  New-Item -ItemType Directory -Force -LiteralPath $ddDir | Out-Null
  Write-Log -File $runLog -Message ("CREATE_DEST {0}" -f $ddDir)
}

# Copy files
$copied = @()
foreach ($e in $entries) {
  $srcAbs = Join-Path $ProjectRoot $e.Source
  $tgtAbs = Join-Path $ProjectRoot $e.Target
  $tgtParent = Split-Path -Parent $tgtAbs
  if (-not (Test-Path -LiteralPath $tgtParent)) { New-Item -ItemType Directory -Force -LiteralPath $tgtParent | Out-Null }

  if (-not (Test-Path -LiteralPath $srcAbs)) {
    Write-Log -File $runLog -Message ("WARN_SOURCE_MISSING id={0} src={1} (skip)" -f $e.Id,$e.Source) -Level "WARN"
    continue
  }

  Copy-Item -LiteralPath $srcAbs -Destination $tgtAbs -Force
  $copied += (Split-Path -Leaf $tgtAbs)
  Write-Log -File $runLog -Message ("COPIED id={0} {1} -> {2}" -f $e.Id,$e.Source,$e.Target)
}

# Generate README
$readme = Join-Path $ddDir "README.txt"
$readmeLines = New-Object System.Collections.Generic.List[string]
$readmeLines.Add("HIA_DRAGNDROP_README") | Out-Null
$readmeLines.Add(("DATE......: {0}" -f (Get-Date).ToString("yyyy-MM-dd"))) | Out-Null
$readmeLines.Add(("TIME......: {0}" -f (Get-Date).ToString("HH:mm"))) | Out-Null
$readmeLines.Add("TZ........: America/Santiago") | Out-Null
$readmeLines.Add("CITY......: Santiago, Chile") | Out-Null
$readmeLines.Add("VERSION...: v1.0-DRAFT") | Out-Null
$readmeLines.Add(("PHASE.....: {0}" -f $Phase)) | Out-Null
$readmeLines.Add(("GENERATED.: {0}" -f $stamp)) | Out-Null
$readmeLines.Add("RULES.....: GENERATED-ONLY. NO EDITAR MANUALMENTE.") | Out-Null
$readmeLines.Add("") | Out-Null
$readmeLines.Add("FILES_INCLUDED (copiados desde HUMAN.README):") | Out-Null
foreach ($c in $copied | Sort-Object) { $readmeLines.Add((" - {0}" -f $c)) | Out-Null }
$readmeLines.Add("") | Out-Null
$readmeLines.Add("IF_MISSING: si falta un archivo esperado, re-ejecuta el tool (no copies a mano).") | Out-Null

$readmeLines | Set-Content -LiteralPath $readme -Encoding UTF8
Write-Log -File $runLog -Message ("README_WRITTEN {0}" -f $readme)

Write-Log -File $runLog -Message ("RUN_END OK copied={0} dest={1}" -f @($copied).Count,$ddDir)
exit 0