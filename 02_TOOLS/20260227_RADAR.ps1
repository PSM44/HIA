<#
==========
00.00_METADATOS_DEL_DOCUMENTO
==========

ID_UNICO..........: HIA.TOOL.PS1.0004
NOMBRE_SUGERIDO...: RADAR.ps1
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-26
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Maria Luisa, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.2 Thinking

ALCANCE...........:
RADAR para HIA (INDEX/CORE/FULL/LITE) cumpliendo:
- orden determinista por ruta relativa,
- CORE solo para extensiones legibles,
- segmentación si ACTIVE > 8MB,
- OK/FAIL binario real,
- mueve versiones antiguas a old,
- no modifica el proyecto (solo lectura) salvo outputs RADAR.

NO_CUBRE..........:
- OCR de PDFs, lectura de binarios (xlsx/pdf).
- Interpretación de negocio.

DEPENDENCIAS......:
09.STANDAR.RADAR_INDEX_CORE_FULL.txt
08.STANDAR.PROBLEM_TROUBLE_INCIDENTS.txt

==========
00.10_COMO_EJECUTAR
==========

Desde la raíz HIA:
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1

Opcional (otro root):
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1 -RootPath "C:\...\HIA"

Salidas:
.\03_ARTIFACTS\RADAR\
- HIA_RAD_0001_LITE.ACTIVE.txt
- HIA_RAD_0002_INDEX.ACTIVE.txt
- HIA_RAD_0003_CORE.ACTIVE.txt
- HIA_RAD_0004_FULL.ACTIVE.txt
+ .seg.001 si > 8MB

Históricos:
.\03_ARTIFACTS\RADAR\old\<timestamp>\

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
  [int] $MaxCoreFileBytes = 2097152,

  [Parameter(Mandatory = $false)]
  [int] $MaxActiveBytes = (8 * 1024 * 1024)
)

Set-StrictMode -Version Latest

function Save-RadarIndexBaseline {
  param(
    [Parameter(Mandatory=$true)][string]$ActiveIndexPath,
    [Parameter(Mandatory=$true)][string]$OldDir
  )

  if (-not (Test-Path -Path $ActiveIndexPath)) {
    return $null
  }

  if (-not (Test-Path -Path $OldDir)) {
    New-Item -ItemType Directory -Path $OldDir -Force | Out-Null
  }

  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $baseName = "HIA_RAD_0002_INDEX.$ts.txt"
  $basePath = Join-Path $OldDir $baseName

  Copy-Item -Path $ActiveIndexPath -Destination $basePath -Force
  return $basePath
}

$ErrorActionPreference = "Stop"

function Test-EnsureDirectory {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Get-NowStamp { (Get-Date).ToString("yyyyMMdd_HHmmss") }

function Convert-ToRelativePath {
  param([Parameter(Mandatory=$true)][string]$Root,[Parameter(Mandatory=$true)][string]$Full)
  $rootNorm = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  $fullNorm = [System.IO.Path]::GetFullPath($Full)
  if ($fullNorm.StartsWith($rootNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $fullNorm.Substring($rootNorm.Length).TrimStart('\')
  }
  return $Full
}

function Test-IsCoreEligibleExt {
  param([string]$ExtLower)
  $allowed = @(".txt",".md",".ps1",".py",".json",".yml",".yaml",".xml",".csv",".js",".ts",".ini",".log",".sql")
  return ($allowed -contains $ExtLower)
}

function Get-LogicalType {
  param([string]$ExtLower)
  switch ($ExtLower) {
    ".txt" { "text" }
    ".md"  { "text" }
    ".ps1" { "code" }
    ".py"  { "code" }
    ".js"  { "code" }
    ".ts"  { "code" }
    ".json"{ "config" }
    ".yml" { "config" }
    ".yaml"{ "config" }
    ".xml" { "config" }
    ".csv" { "data" }
    ".ini" { "config" }
    ".log" { "text" }
    ".sql" { "code" }
    default { "binary" }
  }
}

function Get-Sha256Hex {
  param([Parameter(Mandatory=$true)][string]$Path)
  try { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash } catch { "HASH_ERROR" }
}

function Remove-ExistingSegments {
  param([Parameter(Mandatory=$true)][string]$ActivePath)
  $dir = Split-Path $ActivePath -Parent
  $leaf = Split-Path $ActivePath -Leaf
  $prefix = Join-Path $dir ($leaf + ".seg.")
  Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like ($prefix + "*") } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
}

function Split-IfOverSize {
  param([Parameter(Mandatory=$true)][string]$ActivePath,[int]$MaxBytes)
  if (-not (Test-Path -LiteralPath $ActivePath)) { return }
  $len = (Get-Item -LiteralPath $ActivePath).Length
  if ($len -le $MaxBytes) { return }

  $dir = Split-Path $ActivePath -Parent
  $leaf = Split-Path $ActivePath -Leaf
  $prefix = Join-Path $dir ($leaf + ".seg.")

  $lines = Get-Content -LiteralPath $ActivePath -Encoding UTF8
  $segIndex = 1
  $buffer = New-Object System.Collections.Generic.List[string]
  $bufferBytes = 0

  foreach ($line in $lines) {
    $lineBytes = [System.Text.Encoding]::UTF8.GetByteCount($line + "`n")
    if (($bufferBytes + $lineBytes) -gt $MaxBytes -and $buffer.Count -gt 0) {
      $segName = "{0}{1:000}" -f $prefix, $segIndex
      [System.IO.File]::WriteAllLines($segName, $buffer, [System.Text.Encoding]::UTF8)
      $segIndex++
      $buffer.Clear()
      $bufferBytes = 0
    }
    $buffer.Add($line) | Out-Null
    $bufferBytes += $lineBytes
  }

  if ($buffer.Count -gt 0) {
    $segName = "{0}{1:000}" -f $prefix, $segIndex
    [System.IO.File]::WriteAllLines($segName, $buffer, [System.Text.Encoding]::UTF8)
  }
}

function Test-ValidateOutputsExist {
  param([hashtable]$Paths)
  foreach ($k in $Paths.Keys) {
    if (-not (Test-Path -LiteralPath $Paths[$k])) { return $false }
    if ((Get-Item -LiteralPath $Paths[$k]).Length -le 0) { return $false }
  }
  return $true
}

try {
  if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Error "FAIL: RootPath no existe: $RootPath"
    exit 1
  }

  $radarDir = Join-Path $RootPath "03_ARTIFACTS\RADAR"
  $oldDir   = Join-Path $radarDir "old"
  Test-EnsureDirectory -Path $radarDir
  Test-EnsureDirectory -Path $oldDir

  $active = @{
    Lite  = Join-Path $radarDir "HIA_RAD_0001_LITE.ACTIVE.txt"
    Index = Join-Path $radarDir "HIA_RAD_0002_INDEX.ACTIVE.txt"
    Core  = Join-Path $radarDir "HIA_RAD_0003_CORE.ACTIVE.txt"
    Full  = Join-Path $radarDir "HIA_RAD_0004_FULL.ACTIVE.txt"
  }

  # mover activos previos a old\<timestamp>\
  $stamp = Get-NowStamp
  $dest = Join-Path $oldDir $stamp
  Test-EnsureDirectory -Path $dest

  foreach ($k in $active.Keys) {
    $p = $active[$k]
    if (Test-Path -LiteralPath $p) {
      Move-Item -LiteralPath $p -Destination (Join-Path $dest (Split-Path $p -Leaf)) -Force
    }
    Remove-ExistingSegments -ActivePath $p
  }

  # Exclusiones típicas
  $excludedContains = @("\.git\","\node_modules\","\dist\","\build\","\__pycache__\","\.venv\","\03_ARTIFACTS\RADAR\old\")
  $files = Get-ChildItem -LiteralPath $RootPath -Recurse -Force -File -ErrorAction Stop

  $records = New-Object System.Collections.Generic.List[object]
  foreach ($f in $files) {
    $full = $f.FullName
    $skip = $false
    foreach ($p in $excludedContains) { if ($full -like "*$p*") { $skip = $true; break } }
    if ($skip) { continue }

    $extLower = $f.Extension.ToLowerInvariant()
    $rel = Convert-ToRelativePath -Root $RootPath -Full $full
    $typ = Get-LogicalType -ExtLower $extLower

    $sha = ""
    if ($HashMode -eq "All") { $sha = Get-Sha256Hex -Path $full }
    elseif ($HashMode -eq "Text") { if (Test-IsCoreEligibleExt -ExtLower $extLower) { $sha = Get-Sha256Hex -Path $full } }

    $records.Add([pscustomobject]@{
      Path      = $rel
      FullPath  = $full
      SizeBytes = [int64]$f.Length
      Modified  = $f.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm:ss 'UTC'")
      Ext       = $extLower
      Type      = $typ
      Sha256    = $sha
    }) | Out-Null
  }

  $recordsSorted = $records | Sort-Object -Property Path
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

  # INDEX
  $idx = New-Object System.Collections.Generic.List[string]
  $idx.Add("==========") | Out-Null
  $idx.Add("RADAR_INDEX.ACTIVE") | Out-Null
  $idx.Add("==========") | Out-Null
  $idx.Add("") | Out-Null
  $idx.Add("TIMESTAMP.........: $ts (America/Santiago)") | Out-Null
  $idx.Add("ROOT..............: $RootPath") | Out-Null
  $idx.Add("HASH_MODE.........: $HashMode") | Out-Null
  $idx.Add("TOTAL_FILES.......: $($recordsSorted.Count)") | Out-Null
  $idx.Add("") | Out-Null
  $idx.Add("----------") | Out-Null
  $idx.Add("FILES") | Out-Null
  $idx.Add("----------") | Out-Null
  foreach ($r in $recordsSorted) {
    $idx.Add("PATH..............: $($r.Path)") | Out-Null
    $idx.Add("SIZE_BYTES........: $($r.SizeBytes)") | Out-Null
    $idx.Add("MODIFIED..........: $($r.Modified)") | Out-Null
    $idx.Add("EXT...............: $($r.Ext)") | Out-Null
    $idx.Add("TIPO_LOGICO.......: $($r.Type)") | Out-Null
    $idx.Add("SHA256............: $($r.Sha256)") | Out-Null
    $idx.Add("") | Out-Null
  }
  [System.IO.File]::WriteAllLines($active.Index, $idx, [System.Text.Encoding]::UTF8)

  # CORE
  $core = New-Object System.Collections.Generic.List[string]
  $core.Add("==========") | Out-Null
  $core.Add("RADAR_CORE.ACTIVE") | Out-Null
  $core.Add("==========") | Out-Null
  $core.Add("") | Out-Null
  $core.Add("TIMESTAMP.........: $ts (America/Santiago)") | Out-Null
  $core.Add("ROOT..............: $RootPath") | Out-Null
  $core.Add("MAX_CORE_BYTES.....: $MaxCoreFileBytes") | Out-Null
  $core.Add("") | Out-Null

  foreach ($r in $recordsSorted) {
    $core.Add("----------") | Out-Null
    $core.Add("FILE_BEGIN") | Out-Null
    $core.Add("----------") | Out-Null
    $core.Add("PATH..............: $($r.Path)") | Out-Null
    $core.Add("SIZE_BYTES........: $($r.SizeBytes)") | Out-Null
    $core.Add("MODIFIED..........: $($r.Modified)") | Out-Null
    $core.Add("EXT...............: $($r.Ext)") | Out-Null
    $core.Add("TIPO_LOGICO.......: $($r.Type)") | Out-Null

    if (-not (Test-IsCoreEligibleExt -ExtLower $r.Ext)) {
      $core.Add("CORE_STATUS.......: SKIPPED_NOT_TEXT") | Out-Null
      $core.Add("") | Out-Null
      continue
    }
    if ($r.SizeBytes -gt $MaxCoreFileBytes) {
      $core.Add("CORE_STATUS.......: SKIPPED_TOO_LARGE") | Out-Null
      $core.Add("") | Out-Null
      continue
    }

    try {
      $core.Add("CORE_STATUS.......: INCLUDED") | Out-Null
      $core.Add("++++++++++") | Out-Null
      $core.Add("CONTENT") | Out-Null
      $core.Add("++++++++++") | Out-Null
      $content = Get-Content -LiteralPath $r.FullPath -Raw -ErrorAction Stop
      $core.Add($content) | Out-Null
      $core.Add("") | Out-Null
    } catch {
      $core.Add("CORE_STATUS.......: READ_ERROR") | Out-Null
      $core.Add("ERROR.............: $($_.Exception.Message)") | Out-Null
      $core.Add("") | Out-Null
    }
  }
  [System.IO.File]::WriteAllText($active.Core, ($core -join "`n"), [System.Text.Encoding]::UTF8)

  # FULL = INDEX + CORE + TREE_SIZE (por carpeta)
  $dirSizes = @{}
  foreach ($r in $recordsSorted) {
    $dir = Split-Path $r.Path -Parent
    if ([string]::IsNullOrWhiteSpace($dir)) { $dir = "." }
    if (-not $dirSizes.ContainsKey($dir)) { $dirSizes[$dir] = 0L }
    $dirSizes[$dir] = $dirSizes[$dir] + [int64]$r.SizeBytes
  }

  $full = New-Object System.Collections.Generic.List[string]
  $full.Add("==========") | Out-Null
  $full.Add("RADAR_FULL.ACTIVE") | Out-Null
  $full.Add("==========") | Out-Null
  $full.Add("") | Out-Null
  $full.Add("TIMESTAMP.........: $ts (America/Santiago)") | Out-Null
  $full.Add("ROOT..............: $RootPath") | Out-Null
  $full.Add("") | Out-Null

  $full.Add("==========") | Out-Null
  $full.Add("INCLUDE: RADAR_INDEX.ACTIVE") | Out-Null
  $full.Add("==========") | Out-Null
  $full.AddRange([System.IO.File]::ReadAllLines($active.Index, [System.Text.Encoding]::UTF8)) | Out-Null
  $full.Add("") | Out-Null

  $full.Add("==========") | Out-Null
  $full.Add("INCLUDE: RADAR_CORE.ACTIVE") | Out-Null
  $full.Add("==========") | Out-Null
  $full.AddRange([System.IO.File]::ReadAllLines($active.Core, [System.Text.Encoding]::UTF8)) | Out-Null
  $full.Add("") | Out-Null

  $full.Add("==========") | Out-Null
  $full.Add("TREE_SIZE") | Out-Null
  $full.Add("==========") | Out-Null
  $full.Add("") | Out-Null
  foreach ($k in ($dirSizes.Keys | Sort-Object)) {
    $full.Add("DIR...............: $k") | Out-Null
    $full.Add("SIZE_BYTES........: $($dirSizes[$k])") | Out-Null
    $full.Add("") | Out-Null
  }

  [System.IO.File]::WriteAllText($active.Full, ($full -join "`n"), [System.Text.Encoding]::UTF8)

    # LITE = NEW/DELETED/EDITED (SHA-first) basado en INDEX previo
  $prevIndex = $null
  $oldIndexCandidates = @(
    Get-ChildItem -LiteralPath $oldDir -Recurse -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -eq (Split-Path $active.Index -Leaf) } |
      Sort-Object -Property LastWriteTimeUtc -Descending
  )
  if ($oldIndexCandidates.Length -gt 0) { $prevIndex = $oldIndexCandidates[0].FullName }

  # Current map: path -> (sha256, size, modified)
  $currMap = @{}
  foreach ($r in $recordsSorted) {
    $currMap[$r.Path] = @{
      Sha256    = [string]$r.Sha256
      SizeBytes = [int64]$r.SizeBytes
      Modified  = [string]$r.Modified
    }
  }

  # Previous map: path -> (sha256, size, modified) (parse INDEX previo)
  $prevMap = @{}
  if ($prevIndex) {
    $prevLines = Get-Content -LiteralPath $prevIndex -Encoding UTF8 -ErrorAction SilentlyContinue

    $p = $null
    $h = $null
    $s = $null
    $m = $null

    foreach ($line in $prevLines) {
      if ($line -like "PATH..............:*") {
        $p = ($line -split "PATH..............:\s*",2)[1].Trim()
        $h = $null
        $s = $null
        $m = $null
        continue
      }

      if ($line -like "SHA256............:*") {
        $h = ($line -split "SHA256............:\s*",2)[1].Trim()
        continue
      }

      if ($line -like "SIZE_BYTES........:*") {
        $sRaw = ($line -split "SIZE_BYTES........:\s*",2)[1].Trim()
        if (-not [string]::IsNullOrWhiteSpace($sRaw)) { $s = [int64]$sRaw }
        continue
      }

      if ($line -like "MODIFIED..........:*") {
        $m = ($line -split "MODIFIED..........:\s*",2)[1].Trim()
        continue
      }

      # commit al encontrar línea vacía (fin de bloque)
      if ([string]::IsNullOrWhiteSpace($line) -and -not [string]::IsNullOrWhiteSpace($p)) {
        $prevMap[$p] = @{
          Sha256    = [string]$h
          SizeBytes = ($s -as [int64])
          Modified  = [string]$m
        }
        $p = $null; $h = $null; $s = $null; $m = $null
      }
    }

    # commit final si no terminó en línea vacía
    if (-not [string]::IsNullOrWhiteSpace($p)) {
      $prevMap[$p] = @{
        Sha256    = [string]$h
        SizeBytes = ($s -as [int64])
        Modified  = [string]$m
      }
    }
  }

  $newFiles     = New-Object System.Collections.Generic.List[string]
  $deletedFiles = New-Object System.Collections.Generic.List[string]
  $editedFiles  = New-Object System.Collections.Generic.List[string]

  foreach ($k in $currMap.Keys) {
    if (-not $prevMap.ContainsKey($k)) {
      $newFiles.Add($k) | Out-Null
    } else {
      $ch = [string]$currMap[$k].Sha256
      $cs = [int64]$currMap[$k].SizeBytes
      $cm = [string]$currMap[$k].Modified

      $ph = [string]$prevMap[$k].Sha256
      $ps = [int64]$prevMap[$k].SizeBytes
      $pm = [string]$prevMap[$k].Modified

      $hasHash = (-not [string]::IsNullOrWhiteSpace($ch)) -and (-not [string]::IsNullOrWhiteSpace($ph)) -and ($ch -ne "HASH_ERROR") -and ($ph -ne "HASH_ERROR")

      if ($hasHash) {
        if ($ch -ne $ph) {
          $editedFiles.Add(("{0} | OLD_SHA256={1} | NEW_SHA256={2} | FALLBACK=NONE" -f $k, $ph, $ch)) | Out-Null
        }
      } else {
        if ($cs -ne $ps -or $cm -ne $pm) {
          $editedFiles.Add(("{0} | OLD_SHA256={1} | NEW_SHA256={2} | FALLBACK=SIZE_MODIFIED" -f $k, $ph, $ch)) | Out-Null
        }
      }
    }
  }

  foreach ($k in $prevMap.Keys) {
    if (-not $currMap.ContainsKey($k)) {
      $deletedFiles.Add($k) | Out-Null
    }
  }

  $lite = New-Object System.Collections.Generic.List[string]
  $lite.Add("==========") | Out-Null
  $lite.Add("RADAR_LITE.ACTIVE") | Out-Null
  $lite.Add("==========") | Out-Null
  $lite.Add("") | Out-Null
  $lite.Add("TIMESTAMP.........: $ts (America/Santiago)") | Out-Null
  $lite.Add("ROOT..............: $RootPath") | Out-Null
  $lite.Add("TOTAL_FILES.......: $($recordsSorted.Count)") | Out-Null
  $lite.Add("DIFF_BASE.........: $([string]::IsNullOrWhiteSpace($prevIndex) ? 'NONE' : $prevIndex)") | Out-Null
  $lite.Add("NOTE..............: EDITED = SHA256-first; fallback SIZE_BYTES/MODIFIED si no hay hash.") | Out-Null
  $lite.Add("") | Out-Null

  $lite.Add("----------") | Out-Null
  $lite.Add("NEW_FILES") | Out-Null
  $lite.Add("----------") | Out-Null
  foreach ($x in ($newFiles | Sort-Object)) { $lite.Add($x) | Out-Null }
  $lite.Add("") | Out-Null

  $lite.Add("----------") | Out-Null
  $lite.Add("EDITED_FILES") | Out-Null
  $lite.Add("----------") | Out-Null
  foreach ($x in ($editedFiles | Sort-Object { ($_ -split '\s+\|\s+',2)[0] })) { $lite.Add($x) | Out-Null }
  $lite.Add("") | Out-Null

  $lite.Add("----------") | Out-Null
  $lite.Add("DELETED_FILES") | Out-Null
  $lite.Add("----------") | Out-Null
  foreach ($x in ($deletedFiles | Sort-Object)) { $lite.Add($x) | Out-Null }
  $lite.Add("") | Out-Null

  [System.IO.File]::WriteAllLines($active.Lite, $lite, [System.Text.Encoding]::UTF8)
 
  # Segmentación 8MB
  foreach ($p in @($active.Lite,$active.Index,$active.Core,$active.Full)) {
    Split-IfOverSize -ActivePath $p -MaxBytes $MaxActiveBytes
  }

  if (-not (Test-ValidateOutputsExist -Paths $active)) {
    Write-Error "FAIL: Outputs activos faltantes o vacíos."
    exit 1
  }

  Write-Output "OK: RADAR HIA generado correctamente."
  Write-Output "OUTPUTS: $($active.Lite); $($active.Index); $($active.Core); $($active.Full)"
  exit 0

} catch {
  Write-Error ("FAIL: " + $_.Exception.Message)
  exit 1
}