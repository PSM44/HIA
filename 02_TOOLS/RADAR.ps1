<#
==========
00.00_METADATOS_DEL_DOCUMENTO
==========

ID_UNICO..........: HIA.TOOL.PS1.0004
NOMBRE_SUGERIDO...: RADAR.ps1
VERSION...........: v2.0-DRAFT
FECHA.............: 2026-02-28
HORA..............: HH:MM (America/Santiago)
CIUDAD............: <CIUDAD>, <PAIS>
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.2 Thinking

ALCANCE...........:
RADAR para HIA:
- HIA_RAD_0002_INDEX.ACTIVE.txt  (inventario)
- HIA_RAD_0003_CORE.ACTIVE.txt   (consolidado texto legible relevante)
- HIA_RAD_0001_LITE.ACTIVE.txt   (delta determinista vs baseline inmediato anterior)
- HIA_RAD_0004_FULL.ACTIVE.txt   (full = index + core + summary)

REGLAS_CRITICAS (P0):
- EXCLUSIONES ABSOLUTAS (no se indexa ni se lee):
  - \Raw\
  - \03_ARTIFACTS\  (incluye LOGS, RADAR, old, DeadHistory)
- LITE debe comparar: baseline INDEX anterior vs INDEX nuevo del mismo run (determinista).
- CORE solo incluye extensiones legibles (texto/código/config) y trunca por tamaño.

NO_CUBRE..........:
- OCR, lectura de PDFs o binarios.
- Interpretación de negocio.

COMO_EJECUTAR......:
Desde la raíz HIA:
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1

Opcional (otro root):
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1 -RootPath "C:\...\HIA"

Exit:
0 OK / 1 FAIL
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string] $RootPath = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA",

  [Parameter(Mandatory = $false)]
  [ValidateSet("None","Text","All")]
  [string] $HashMode = "Text",

  [Parameter(Mandatory = $false)]
  [int] $MaxCoreFileBytes = 2097152,   # 2MB por archivo en CORE

  [Parameter(Mandatory = $false)]
  [int] $MaxActiveBytes = (8 * 1024 * 1024)  # 8MB por ACTIVE (segmenta si supera)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =============================================================================
# 01.00_UTILS
# =============================================================================

function Test-EnsureDirectory {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Get-NowStamp {
  (Get-Date -Format "yyyyMMdd_HHmmss")
}

function Convert-ToRelativePath {
  param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$Full
  )
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $fullNorm = [System.IO.Path]::GetFullPath($Full)
  if ($fullNorm.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $rel = $fullNorm.Substring($rootFull.Length)
    return $rel.TrimStart('\')
  }
  return $Full
}

function Get-Sha256Hex {
  param([Parameter(Mandatory=$true)][string]$Path)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
      $hash = $sha.ComputeHash($fs)
      return ([BitConverter]::ToString($hash)).Replace("-","").ToLowerInvariant()
    } finally {
      $fs.Dispose()
    }
  } finally {
    $sha.Dispose()
  }
}

function Test-IsCoreEligibleExt {
  param([Parameter(Mandatory=$true)][string]$ExtLower)
  # Texto/código/config (ajusta si quieres)
  $eligible = @(
    ".txt",".md",".json",".yaml",".yml",".xml",".ini",".cfg",".conf",".toml",".env",
    ".ps1",".psm1",".py",".js",".ts",".tsx",".jsx",".java",".cs",".go",".rs",".cpp",".c",".h",".hpp",
    ".sql",".sh",".bat",".cmd",".rb",".php",".kt",".swift"
  )
  return ($eligible -contains $ExtLower)
}

function Get-LogicalType {
  param([Parameter(Mandatory=$true)][string]$ExtLower)
  if ($ExtLower -eq "") { return "no_ext" }
  if (Test-IsCoreEligibleExt -ExtLower $ExtLower) { return "text" }
  # binarios comunes (no leídos por CORE)
  $bin = @(".exe",".dll",".png",".jpg",".jpeg",".webp",".gif",".pdf",".xlsx",".xls",".pptx",".docx",".zip",".7z",".rar",".bin")
  if ($bin -contains $ExtLower) { return "binary" }
  return "other"
}

function Test-ShouldExcludePath {
  param(
    [Parameter(Mandatory=$true)][string]$FullPath,
    [Parameter(Mandatory=$true)][string[]]$ExcludedContains
  )
  foreach ($p in $ExcludedContains) {
    if ($FullPath -like ("*" + $p + "*")) { return $true }
  }
  return $false
}

function Move-IfExistsToOld {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$OldDir,
    [Parameter(Mandatory=$true)][string]$Stamp
  )
  if (Test-Path -Path $Path) {
    Test-EnsureDirectory -Path $OldDir
    $name = [System.IO.Path]::GetFileName($Path)
    $dst = Join-Path $OldDir ($name.Replace(".ACTIVE", ".$Stamp"))
    Move-Item -Path $Path -Destination $dst -Force
  }
}

function Write-SegmentedFile {
  param(
    [Parameter(Mandatory=$true)][string]$PathActive,
    [Parameter(Mandatory=$true)][string]$Content,
    [Parameter(Mandatory=$true)][int]$MaxBytes
  )

  $bytes = [System.Text.Encoding]::UTF8.GetByteCount($Content)
  if ($bytes -le $MaxBytes) {
    Set-Content -Path $PathActive -Value $Content -NoNewline -Encoding UTF8
    return @($PathActive)
  }

  # segmentar
  $dir = Split-Path -Parent $PathActive
  $base = [System.IO.Path]::GetFileNameWithoutExtension($PathActive)
  $ext  = [System.IO.Path]::GetExtension($PathActive)

  $out = New-Object System.Collections.Generic.List[string]
  $chunkSize = [Math]::Max(1024*256, [int]($MaxBytes * 0.9)) # 90% margen

  $utf8 = [System.Text.Encoding]::UTF8
  $allBytes = $utf8.GetBytes($Content)

  $i = 0
  $seg = 1
  while ($i -lt $allBytes.Length) {
    $len = [Math]::Min($chunkSize, $allBytes.Length - $i)
    $partBytes = $allBytes[$i..($i+$len-1)]
    $partText = $utf8.GetString($partBytes)

    $segName = "$base.seg.$('{0:000}' -f $seg)$ext"
    $segPath = Join-Path $dir $segName
    Set-Content -Path $segPath -Value $partText -NoNewline -Encoding UTF8
    $out.Add($segPath) | Out-Null

    $i += $len
    $seg += 1
  }

  # ACTIVE queda como puntero mínimo
  $pointer = @()
  $pointer += "RADAR_SEGMENTED_OUTPUT"
  $pointer += "ACTIVE_FILE: $PathActive"
  $pointer += "SEGMENTS:"
  foreach ($p in $out) { $pointer += " - $p" }
  Set-Content -Path $PathActive -Value ($pointer -join "`r`n") -NoNewline -Encoding UTF8

  return @($PathActive) + $out.ToArray()
}

# =============================================================================
# 02.00_PATHS_Y_EXCLUSIONES
# =============================================================================

$RootPath = [System.IO.Path]::GetFullPath($RootPath)

$RadarDir = Join-Path $RootPath "03_ARTIFACTS\RADAR"
$OldDir   = Join-Path $RadarDir "old"
Test-EnsureDirectory -Path $RadarDir
Test-EnsureDirectory -Path $OldDir

$LiteActive  = Join-Path $RadarDir "HIA_RAD_0001_LITE.ACTIVE.txt"
$IndexActive = Join-Path $RadarDir "HIA_RAD_0002_INDEX.ACTIVE.txt"
$CoreActive  = Join-Path $RadarDir "HIA_RAD_0003_CORE.ACTIVE.txt"
$FullActive  = Join-Path $RadarDir "HIA_RAD_0004_FULL.ACTIVE.txt"

$stamp = Get-NowStamp

# EXCLUSIONES ABSOLUTAS:
# - Excluir TODO 03_ARTIFACTS (evita ruido + auto-referencia)
# - Excluir Raw (PDFs, setup docs, etc. irrelevante para CORE/LITE y también para INDEX)
# - Excluir .git y carpetas típicas de builds/deps/cache
$excludedContains = @(
  "\.git\",
  "\node_modules\",
  "\dist\",
  "\build\",
  "\__pycache__\",
  "\.venv\",
  "\.pytest_cache\",
  "\03_ARTIFACTS\",
  "\Raw\"
)

# =============================================================================
# 03.00_BASELINE_DETERMINISTA (para LITE)
# =============================================================================

# Copia el INDEX ACTIVE previo (si existe) para usarlo como baseline del delta.
# Nota: copiamos (no movemos) para mantener ACTIVE hasta que se sobreescriba.
$BaselineIndexPath = $null
if (Test-Path -Path $IndexActive) {
  $BaselineIndexPath = Join-Path $OldDir ("HIA_RAD_0002_INDEX.BASELINE.$stamp.txt")
  Copy-Item -Path $IndexActive -Destination $BaselineIndexPath -Force
}

# Mover outputs previos a old\<timestamp>\ (para auditoría)
$oldRunDir = Join-Path $OldDir $stamp
Test-EnsureDirectory -Path $oldRunDir

Move-IfExistsToOld -Path $LiteActive  -OldDir $oldRunDir -Stamp $stamp
Move-IfExistsToOld -Path $IndexActive -OldDir $oldRunDir -Stamp $stamp
Move-IfExistsToOld -Path $CoreActive  -OldDir $oldRunDir -Stamp $stamp
Move-IfExistsToOld -Path $FullActive  -OldDir $oldRunDir -Stamp $stamp

# =============================================================================
# 04.00_RECOLECTAR_FILES (1 sola vez)
# =============================================================================

$files = Get-ChildItem -Path $RootPath -Recurse -Force -File -ErrorAction Stop

$records = New-Object System.Collections.Generic.List[object]
foreach ($f in $files) {
  $full = $f.FullName
  if (Test-ShouldExcludePath -FullPath $full -ExcludedContains $excludedContains) { continue }

  $extLower = $f.Extension.ToLowerInvariant()
  $rel = Convert-ToRelativePath -Root $RootPath -Full $full
  $typ = Get-LogicalType -ExtLower $extLower

  $sha = ""
  if ($HashMode -eq "All") {
    $sha = Get-Sha256Hex -Path $full
  } elseif ($HashMode -eq "Text") {
    if (Test-IsCoreEligibleExt -ExtLower $extLower) {
      $sha = Get-Sha256Hex -Path $full
    }
  }

  $records.Add([pscustomobject]@{
    relpath  = $rel
    fullpath = $full
    ext      = $extLower
    type     = $typ
    size     = [int64]$f.Length
    created  = $f.CreationTimeUtc.ToString("o")
    modified = $f.LastWriteTimeUtc.ToString("o")
    sha256   = $sha
  }) | Out-Null
}

# Orden determinista
$records = $records | Sort-Object -Property relpath

# =============================================================================
# 05.00_GENERAR_INDEX
# =============================================================================

$idxLines = New-Object System.Collections.Generic.List[string]
$idxLines.Add("RADAR_INDEX — HIA") | Out-Null
$idxLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$idxLines.Add("ROOT: " + $RootPath) | Out-Null
$idxLines.Add("HASH_MODE: " + $HashMode) | Out-Null
$idxLines.Add("EXCLUDED_CONTAINS: " + ($excludedContains -join " | ")) | Out-Null
$idxLines.Add("FILES_COUNT: " + $records.Count) | Out-Null
$idxLines.Add("") | Out-Null
$idxLines.Add("FIELDS: relpath | type | ext | size | modified_utc | sha256") | Out-Null
$idxLines.Add("") | Out-Null

foreach ($r in $records) {
  $idxLines.Add("$($r.relpath) | $($r.type) | $($r.ext) | $($r.size) | $($r.modified) | $($r.sha256)") | Out-Null
}

$indexContent = ($idxLines -join "`r`n")
Write-SegmentedFile -PathActive $IndexActive -Content $indexContent -MaxBytes $MaxActiveBytes | Out-Null

# =============================================================================
# 06.00_GENERAR_CORE
# =============================================================================

$coreLines = New-Object System.Collections.Generic.List[string]
$coreLines.Add("RADAR_CORE — HIA (solo texto legible relevante)") | Out-Null
$coreLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$coreLines.Add("ROOT: " + $RootPath) | Out-Null
$coreLines.Add("MAX_CORE_FILE_BYTES: " + $MaxCoreFileBytes) | Out-Null
$coreLines.Add("EXCLUDED_CONTAINS: " + ($excludedContains -join " | ")) | Out-Null
$coreLines.Add("") | Out-Null

foreach ($r in $records) {
  if (-not (Test-IsCoreEligibleExt -ExtLower $r.ext)) { continue }

  $coreLines.Add("==========") | Out-Null
  $coreLines.Add("FILE: " + $r.relpath) | Out-Null
  $coreLines.Add("SIZE: " + $r.size) | Out-Null
  $coreLines.Add("MODIFIED_UTC: " + $r.modified) | Out-Null
  $coreLines.Add("SHA256: " + $r.sha256) | Out-Null
  $coreLines.Add("==========") | Out-Null

  try {
    $bytes = [System.IO.File]::ReadAllBytes($r.fullpath)
    if ($bytes.Length -gt $MaxCoreFileBytes) {
      $part = $bytes[0..($MaxCoreFileBytes-1)]
      $txt = [System.Text.Encoding]::UTF8.GetString($part)
      $coreLines.Add($txt) | Out-Null
      $coreLines.Add("") | Out-Null
      $coreLines.Add("[TRUNCATED: file_bytes=" + $bytes.Length + " max=" + $MaxCoreFileBytes + "]") | Out-Null
    } else {
      $txt = [System.Text.Encoding]::UTF8.GetString($bytes)
      $coreLines.Add($txt) | Out-Null
    }
  } catch {
    $coreLines.Add("[READ_FAIL: " + $_.Exception.Message + "]") | Out-Null
  }

  $coreLines.Add("") | Out-Null
}

$coreContent = ($coreLines -join "`r`n")
Write-SegmentedFile -PathActive $CoreActive -Content $coreContent -MaxBytes $MaxActiveBytes | Out-Null

# =============================================================================
# 07.00_GENERAR_LITE (delta determinista)
# =============================================================================

$liteLines = New-Object System.Collections.Generic.List[string]
$liteLines.Add("RADAR_LITE (Delta) — HIA") | Out-Null
$liteLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$liteLines.Add("ROOT: " + $RootPath) | Out-Null
$liteLines.Add("BASELINE_INDEX: " + ($BaselineIndexPath ?? "[NONE]")) | Out-Null
$liteLines.Add("NEW_INDEX: " + $IndexActive) | Out-Null
$liteLines.Add("") | Out-Null

# Parse index into dictionaries: relpath -> record fields
function Parse-IndexFileToMap {
  param([Parameter(Mandatory=$true)][string]$Path)

  $map = @{}
  if (-not (Test-Path -Path $Path)) { return $map }

  $lines = Get-Content -Path $Path
  foreach ($ln in $lines) {
    $line = $ln.TrimEnd()

    # Skip obvious headers/metadata (varios contienen '|', ej. EXCLUDED_CONTAINS)
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^(RADAR_INDEX|STAMP_UTC|ROOT|HASH_MODE|EXCLUDED_CONTAINS|FILES_COUNT|FIELDS):') { continue }
    if ($line -match '^SECTION:\s') { continue }
    if ($line -match '^={3,}$') { continue }

    # Only parse data rows that look like: "<path> | <type> | <ext> | <size> | <modified> | <sha>"
    if ($line -notmatch '\|') { continue }

    $parts = $line.Split('|').ForEach({ $_.Trim() })
    if ($parts.Count -lt 6) { continue }

    $rel = $parts[0]

    # Guardrails: ignore “fake paths” that are clearly not file rows
    if ($rel -match '^(EXCLUDED_CONTAINS|ROOT|STAMP_UTC|HASH_MODE|FILES_COUNT|FIELDS)$') { continue }
    if ($rel -match '^\w+:\s') { continue } # "KEY: value"

    $map[$rel] = [pscustomobject]@{
      relpath  = $rel
      type     = $parts[1]
      ext      = $parts[2]
      size     = $parts[3]
      modified = $parts[4]
      sha256   = $parts[5]
    }
  }

  return $map
}

$newMap  = Parse-IndexFileToMap -Path $IndexActive
$baseMap = @{}
if ($BaselineIndexPath) { $baseMap = Parse-IndexFileToMap -Path $BaselineIndexPath }

if (-not $BaselineIndexPath) {
  $liteLines.Add("NO_BASELINE: primera ejecución o baseline no disponible.") | Out-Null
  $liteLines.Add("NEW_FILES_COUNT: " + $newMap.Count) | Out-Null
  $liteLines.Add("") | Out-Null
  $liteLines.Add("NEW_FILES:") | Out-Null
  foreach ($k in ($newMap.Keys | Sort-Object)) {
    $liteLines.Add(" + " + $k) | Out-Null
  }
  $liteContent = ($liteLines -join "`r`n")
  Write-SegmentedFile -PathActive $LiteActive -Content $liteContent -MaxBytes $MaxActiveBytes | Out-Null
} else {
  $created = New-Object System.Collections.Generic.List[string]
  $deleted = New-Object System.Collections.Generic.List[string]
  $edited  = New-Object System.Collections.Generic.List[string]
  $moved   = New-Object System.Collections.Generic.List[string]

  # Build reverse hash maps (for moved detection) only where sha exists
  $baseHash = @{}
  foreach ($k in $baseMap.Keys) {
    $h = $baseMap[$k].sha256
    if ([string]::IsNullOrWhiteSpace($h)) { continue }
    if (-not $baseHash.ContainsKey($h)) { $baseHash[$h] = New-Object System.Collections.Generic.List[string] }
    $baseHash[$h].Add($k) | Out-Null
  }

  $newHash = @{}
  foreach ($k in $newMap.Keys) {
    $h = $newMap[$k].sha256
    if ([string]::IsNullOrWhiteSpace($h)) { continue }
    if (-not $newHash.ContainsKey($h)) { $newHash[$h] = New-Object System.Collections.Generic.List[string] }
    $newHash[$h].Add($k) | Out-Null
  }

  # Created / Edited
  foreach ($k in $newMap.Keys) {
    if (-not $baseMap.ContainsKey($k)) {
      $created.Add($k) | Out-Null
      continue
    }
    $b = $baseMap[$k]
    $n = $newMap[$k]
    # Prefer hash if present, else fallback to size+modified
    if (-not [string]::IsNullOrWhiteSpace($n.sha256) -and -not [string]::IsNullOrWhiteSpace($b.sha256)) {
      if ($n.sha256 -ne $b.sha256) { $edited.Add($k) | Out-Null }
    } else {
      if (($n.size -ne $b.size) -or ($n.modified -ne $b.modified)) { $edited.Add($k) | Out-Null }
    }
  }

  # Deleted
  foreach ($k in $baseMap.Keys) {
    if (-not $newMap.ContainsKey($k)) {
      $deleted.Add($k) | Out-Null
    }
  }

  # Moved (best effort): same sha in both, path differs, and appears as created+deleted
  foreach ($h in $baseHash.Keys) {
    if (-not $newHash.ContainsKey($h)) { continue }
    $fromList = $baseHash[$h]
    $toList   = $newHash[$h]
    foreach ($from in $fromList) {
      foreach ($to in $toList) {
        if ($from -ne $to) {
          # only consider if in created/deleted sets
          if (($deleted -contains $from) -and ($created -contains $to)) {
            $moved.Add("$($from) -> $($to)") | Out-Null
          }
        }
      }
    }
  }

  # Remove moved pairs from created/deleted (cleaner delta)
  foreach ($mv in $moved) {
    $pair = $mv.Split('->').ForEach({ $_.Trim() })
    if ($pair.Count -eq 2) {
      $deleted.Remove($pair[0]) | Out-Null
      $created.Remove($pair[1]) | Out-Null
    }
  }

  $liteLines.Add("CREATED_FILES_COUNT: " + $created.Count) | Out-Null
  $liteLines.Add("EDITED_FILES_COUNT: " + $edited.Count) | Out-Null
  $liteLines.Add("DELETED_FILES_COUNT: " + $deleted.Count) | Out-Null
  $liteLines.Add("MOVED_FILES_COUNT: " + $moved.Count) | Out-Null
  $liteLines.Add("") | Out-Null

  $liteLines.Add("CREATED_FILES:") | Out-Null
  foreach ($x in ($created | Sort-Object)) { $liteLines.Add(" + " + $x) | Out-Null }
  $liteLines.Add("") | Out-Null

  $liteLines.Add("EDITED_FILES:") | Out-Null
  foreach ($x in ($edited | Sort-Object)) { $liteLines.Add(" ~ " + $x) | Out-Null }
  $liteLines.Add("") | Out-Null

  $liteLines.Add("DELETED_FILES:") | Out-Null
  foreach ($x in ($deleted | Sort-Object)) { $liteLines.Add(" - " + $x) | Out-Null }
  $liteLines.Add("") | Out-Null

  $liteLines.Add("MOVED_FILES:") | Out-Null
  foreach ($x in ($moved | Sort-Object)) { $liteLines.Add(" > " + $x) | Out-Null }

  $liteContent = ($liteLines -join "`r`n")
  Write-SegmentedFile -PathActive $LiteActive -Content $liteContent -MaxBytes $MaxActiveBytes | Out-Null
}

# =============================================================================
# 08.00_GENERAR_FULL
# =============================================================================

$fullLines = New-Object System.Collections.Generic.List[string]
$fullLines.Add("RADAR_FULL — HIA (INDEX + CORE + SUMMARY)") | Out-Null
$fullLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$fullLines.Add("ROOT: " + $RootPath) | Out-Null
$fullLines.Add("HASH_MODE: " + $HashMode) | Out-Null
$fullLines.Add("EXCLUDED_CONTAINS: " + ($excludedContains -join " | ")) | Out-Null
$fullLines.Add("FILES_COUNT: " + $records.Count) | Out-Null
$fullLines.Add("") | Out-Null

# Summary stats
$totalBytes = 0
foreach ($r in $records) { $totalBytes += [int64]$r.size }
$fullLines.Add("TOTAL_BYTES: " + $totalBytes) | Out-Null
$fullLines.Add("") | Out-Null

$fullLines.Add("==========") | Out-Null
$fullLines.Add("SECTION: INDEX") | Out-Null
$fullLines.Add("==========") | Out-Null
$fullLines.Add($indexContent) | Out-Null
$fullLines.Add("") | Out-Null

$fullLines.Add("==========") | Out-Null
$fullLines.Add("SECTION: CORE") | Out-Null
$fullLines.Add("==========") | Out-Null
$fullLines.Add($coreContent) | Out-Null
$fullLines.Add("") | Out-Null

$fullLines.Add("==========") | Out-Null
$fullLines.Add("SECTION: LITE") | Out-Null
$fullLines.Add("==========") | Out-Null
$fullLines.Add((Get-Content -Path $LiteActive -Raw)) | Out-Null

$fullContent = ($fullLines -join "`r`n")
Write-SegmentedFile -PathActive $FullActive -Content $fullContent -MaxBytes $MaxActiveBytes | Out-Null

Write-Host "OK: RADAR HIA generado correctamente."
Write-Host "OUTPUTS: $LiteActive; $IndexActive; $CoreActive; $FullActive"
exit 0