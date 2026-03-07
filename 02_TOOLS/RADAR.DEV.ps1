<#
DATE......: 2026-03-03
TIME......: HH:MM
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: v1.0-DRAFT
ID_UNICO..: HIA.TOO.RADAR2.0001
NOMBRE....: radar.2.ps1
UBICACION.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\radar.2.ps1
AUTOR.....: SYSTEM (ChatGPT) + HUMANO (PABLO/ADMIN)
ALCANCE...:
- Consolidar contenido COMPLETO (sin truncation) de carpetas objetivo a archivos RADAR dedicados.
- Excluir carpetas irrelevantes (Raw, DeadHistory, 03_ARTIFACTS\DeadHistory) y archivos binarios por extensión.
- Outputs separados por dominio (HUMAN, TOOLS, FRAMEWORK, etc.).

NO_CUBRE..:
- No reemplaza RADAR.ps1 principal (no genera INDEX/LITE/CORE/FULL).
- No hace hashing, ni comparación de deltas, ni segmentación automática (salvo que el usuario la active).

DEPENDENCIAS:
- PowerShell 7 recomendado (funciona en Windows PowerShell 5.1 con caveats).
- Permisos de lectura sobre el proyecto.

COMO_SE_EJECUTA:
1) Abrir Terminal (PowerShell) en:
   C:\01. GitHub\Wings3.0\01_PROJECTS\HIA
2) Ejecutar:
   pwsh -NoProfile -File .\02_TOOLS\radar.2.ps1
   (o en Windows PowerShell 5.1):
   powershell -NoProfile -ExecutionPolicy Bypass -File .\02_TOOLS\radar.2.ps1

3) Ver outputs en:
   .\03_ARTIFACTS\RADAR\Radar.*.txt

INDICE_WBS:
00.00 Metadatos
01.00 Parámetros y defaults
02.00 Reglas de exclusión e inclusión
03.00 Lectura segura de texto (BOM/encodings)
04.00 Consolidación por carpeta objetivo
05.00 Escritura de outputs (header + file blocks)
06.00 Main
#>

# =========================
# 01.00_PARAMETROS_DEFAULT
# =========================
[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string] $ProjectRoot = $null,

  [Parameter(Mandatory = $false)]
  [string] $OutDirRel = "03_ARTIFACTS\RADAR",

  # 0 = no split (sin límites). Si pones un número > 0, parte el output en segmentos.
  [Parameter(Mandatory = $false)]
  [long] $MaxBytesPerOutput = 0,

  [Parameter(Mandatory = $false)]
  [switch] $IncludeHidden,

  [Parameter(Mandatory = $false)]
  [switch] $VerboseLog
)

# Default ProjectRoot: 1 nivel arriba de 02_TOOLS (PROJECT_ROOT)
if (-not $ProjectRoot) {
  try {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
  } catch {
    throw "No se pudo resolver ProjectRoot desde PSScriptRoot. Pasa -ProjectRoot explícito. Error=$($_.Exception.Message)"
  }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# 02.00_REGLAS_INCLUSION_EXCLUSION
# =========================

# 02.10 Carpetas irrelevantes (se excluyen siempre, aunque existan dentro del target)
# Nota: match por "path segment contains" simple. Mantener barato, predecible.
$ExcludedPathContains = @(
  "\Raw\",
  "\DeadHistory\",
  "\03_ARTIFACTS\DeadHistory\"
)

# 02.20 Extensiones binarias (excluir)
$BinaryExt = @(
  ".jpg",".jpeg",".png",".gif",".webp",".bmp",".tiff",".ico",
  ".mp4",".mov",".avi",".mkv",".mp3",".wav",".flac",
  ".zip",".7z",".rar",".gz",".tar",".iso",
  ".exe",".dll",".sys",".msi",
  ".pdf", # <- ojo: si quieres incluir PDFs como texto, hay que OCR/parsers: fuera de scope
  ".pdb",".obj",".class",
  ".woff",".woff2",".ttf",".otf"
)

# 02.30 Extensiones de texto (incluir)
# Nota: NO es truncation. Solo decide qué se considera "texto relevante" para consolidar.
$TextExt = @(
  ".txt",".md",".ps1",".psm1",".psd1",".json",".yaml",".yml",".xml",".csv",".ini",".cfg",".conf",".toml",".sql",
  ".py",".js",".ts",".tsx",".java",".cs",".go",".rs",".rb",".php",".sh",".bat",".cmd"
)

# 02.40 Dotfiles “texto relevante” (sin extensión)
$TextDotFilesByName = @(
  ".gitignore",".gitattributes",".editorconfig",".npmrc",".yarnrc",".prettierrc",".eslintrc"
)

function Test-IsExcludedPath {
  param([Parameter(Mandatory=$true)][string]$FullPath)

  $p = $FullPath.Replace("/", "\")
  foreach ($frag in $ExcludedPathContains) {
    if ($p -like "*$frag*") { return $true }
  }
  return $false
}

function Test-IsBinaryExt {
  param([Parameter(Mandatory=$true)][string]$Ext)
  if ([string]::IsNullOrWhiteSpace($Ext)) { return $false }
  $e = $Ext.ToLowerInvariant()
  return $BinaryExt -contains $e
}

function Test-IsTextEligible {
  param(
    [Parameter(Mandatory=$true)][string]$FullPath
  )

  $leaf = Split-Path $FullPath -Leaf
  $ext  = [System.IO.Path]::GetExtension($leaf)

  # Dotfiles allowlist (sin ext o con ext raro)
  $leafLower = $leaf.ToLowerInvariant()
  if ($TextDotFilesByName -contains $leafLower) { return $true }

  # Si es binario => fuera
  if (Test-IsBinaryExt $ext) { return $false }

  # Ext texto => dentro
  if (-not [string]::IsNullOrWhiteSpace($ext)) {
    return ($TextExt -contains $ext.ToLowerInvariant())
  }

  # Sin extensión y no está allowlisted => fuera (para no comerse blobs)
  return $false
}

# =========================
# 03.00_LECTURA_TEXTO_SEGURA
# =========================
function Get-TextFromBytes {
  param([Parameter(Mandatory=$true)][byte[]]$Bytes)

  # Detect BOMs comunes
  if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
    return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3)
  }
  if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
    return [System.Text.Encoding]::Unicode.GetString($Bytes, 2, $Bytes.Length - 2) # UTF-16 LE
  }
  if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
    return [System.Text.Encoding]::BigEndianUnicode.GetString($Bytes, 2, $Bytes.Length - 2) # UTF-16 BE
  }
  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE -and $Bytes[2] -eq 0x00 -and $Bytes[3] -eq 0x00) {
    return [System.Text.Encoding]::UTF32.GetString($Bytes, 4, $Bytes.Length - 4) # UTF-32 LE
  }
  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0x00 -and $Bytes[1] -eq 0x00 -and $Bytes[2] -eq 0xFE -and $Bytes[3] -eq 0xFF) {
    return [System.Text.Encoding]::GetEncoding("utf-32BE").GetString($Bytes, 4, $Bytes.Length - 4) # UTF-32 BE
  }

  # Fallback: UTF-8 sin BOM (y si revienta, Default)
  try {
    return [System.Text.Encoding]::UTF8.GetString($Bytes)
  } catch {
    return [System.Text.Encoding]::Default.GetString($Bytes)
  }
}

function Get-FileText {
  param([Parameter(Mandatory=$true)][string]$FullPath)
  try {
    $bytes = [System.IO.File]::ReadAllBytes($FullPath)
    return Get-TextFromBytes -Bytes $bytes
  } catch {
    return "[READ_FAIL: $($_.Exception.Message)]"
  }
}

# =========================
# 04.00_CONSOLIDACION
# =========================
function Get-FileInventory {
  param(
    [Parameter(Mandatory=$true)][string]$RootPath
  )

  if (-not (Test-Path -LiteralPath $RootPath)) {
    throw "RootPath no existe: $RootPath"
  }

  $gciParams = @{
    LiteralPath = $RootPath
    Recurse     = $true
    File        = $true
    Force       = [bool]$IncludeHidden
  }

  $files = Get-ChildItem @gciParams | Sort-Object FullName

  $out = New-Object System.Collections.Generic.List[object]

  foreach ($f in $files) {
    $full = $f.FullName

    if (Test-IsExcludedPath $full) { continue }

    $eligible = Test-IsTextEligible -FullPath $full
    if (-not $eligible) { continue }

    $rel = $full.Substring($RootPath.Length).TrimStart("\")
    $out.Add([pscustomobject]@{
      FullPath = $full
      RelPath  = $rel
      Length   = $f.Length
      LastWriteTime = $f.LastWriteTime
    }) | Out-Null
  }

  # Fuerza retorno como array, siempre.
  return @($out.ToArray())
}

# =========================
# 05.00_ESCRITURA_OUTPUT
# =========================
function Write-ConsolidatedOutput {
  param(
    [Parameter(Mandatory=$true)][string]$TargetRoot,
    [Parameter(Mandatory=$true)][string]$OutFilePath,
    [Parameter(Mandatory=$true)][string]$Label
  )

  $runTs = Get-Date
  $inv = Get-FileInventory -RootPath $TargetRoot

  # Header
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("==========") | Out-Null
  $lines.Add("HIA_RADAR2_OUTPUT") | Out-Null
  $lines.Add("==========") | Out-Null
  $lines.Add("LABEL........: $Label") | Out-Null
  $lines.Add("RUN_UTC......: " + ($runTs.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss"))) | Out-Null
  $lines.Add("RUN_LOCAL....: " + ($runTs.ToString("yyyy-MM-dd HH:mm:ss"))) | Out-Null
  $lines.Add("PROJECT_ROOT.: $ProjectRoot") | Out-Null
  $lines.Add("TARGET_ROOT..: $TargetRoot") | Out-Null
  $lines.Add("OUT_FILE.....: $OutFilePath") | Out-Null
  $lines.Add("FILE_COUNT...: " + (@($inv).Count)) | Out-Null
  $lines.Add("MAX_BYTES_OUT: " + $MaxBytesPerOutput) | Out-Null
  $lines.Add("EXCLUDED_PATH: " + ($ExcludedPathContains -join "; ")) | Out-Null
  $lines.Add("EXCLUDED_EXT.: " + ($BinaryExt -join "; ")) | Out-Null
  $lines.Add("TEXT_EXT.....: " + ($TextExt -join "; ")) | Out-Null
  $lines.Add("DOTFILES.....: " + ($TextDotFilesByName -join "; ")) | Out-Null
  $lines.Add("") | Out-Null

  # Index
  $lines.Add("==========") | Out-Null
  $lines.Add("SECTION: FILE_INDEX") | Out-Null
  $lines.Add("==========") | Out-Null
  foreach ($r in $inv) {
    $lines.Add(("FILE: {0} | bytes={1} | mtime={2}" -f $r.RelPath, $r.Length, $r.LastWriteTime)) | Out-Null
  }
  $lines.Add("") | Out-Null

  # Content blocks
  $lines.Add("==========") | Out-Null
  $lines.Add("SECTION: CONTENT") | Out-Null
  $lines.Add("==========") | Out-Null

  foreach ($r in $inv) {
    $lines.Add("-----BEGIN_FILE-----") | Out-Null
    $lines.Add("REL_PATH...: " + $r.RelPath) | Out-Null
    $lines.Add("FULL_PATH..: " + $r.FullPath) | Out-Null
    $lines.Add("BYTES......: " + $r.Length) | Out-Null
    $lines.Add("MTIME......: " + $r.LastWriteTime) | Out-Null
    $lines.Add("-----CONTENT-----") | Out-Null

    $txt = Get-FileText -FullPath $r.FullPath
    $lines.Add($txt) | Out-Null

    $lines.Add("") | Out-Null
    $lines.Add("-----END_FILE-----") | Out-Null
    $lines.Add("") | Out-Null
  }

  # Ensure out dir
  $outDir = Split-Path -Parent $OutFilePath
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null

  # Sin límites: escribir completo.
  # Si MaxBytesPerOutput > 0, segmenta por chunks de bytes del output final (no trunca contenido; solo parte el archivo).
  $content = ($lines -join "`r`n") + "`r`n"

  if ($MaxBytesPerOutput -le 0) {
    [System.IO.File]::WriteAllText($OutFilePath, $content, [System.Text.Encoding]::UTF8)
    if ($VerboseLog) { Write-Host ("WROTE: {0} bytes={1}" -f $OutFilePath, ([System.Text.Encoding]::UTF8.GetByteCount($content))) }
    return
  }

  # Segmentación opcional (si el usuario decide activarla)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
  $total = $bytes.Length
  $seg = 1
  $offset = 0

  while ($offset -lt $total) {
    $take = [Math]::Min($MaxBytesPerOutput, $total - $offset)
    $slice = New-Object byte[] $take
    [Array]::Copy($bytes, $offset, $slice, 0, $take)

    $segPath = "{0}.seg.{1:000}" -f $OutFilePath, $seg
    [System.IO.File]::WriteAllBytes($segPath, $slice)

    if ($VerboseLog) { Write-Host ("WROTE: {0} bytes={1}" -f $segPath, $take) }
    $seg++
    $offset += $take
  }
}

# =========================
# 06.00_MAIN
# =========================
$OutDir = Join-Path $ProjectRoot $OutDirRel

$Targets = @(
  @{ Label = "HUMAN.README";  Root = (Join-Path $ProjectRoot "HUMAN.README");  Out = (Join-Path $OutDir "Radar.Human.txt") },
  @{ Label = "02_TOOLS";      Root = (Join-Path $ProjectRoot "02_TOOLS");      Out = (Join-Path $OutDir "Radar.Tools.txt") },
  @{ Label = "05_Triggers";   Root = (Join-Path $ProjectRoot "05_Triggers");   Out = (Join-Path $OutDir "Radar.05_Triggers.txt") },
  @{ Label = "00_FRAMEWORK";  Root = (Join-Path $ProjectRoot "00_FRAMEWORK");  Out = (Join-Path $OutDir "Radar.00_FRAMEWORK.txt") },
  @{ Label = "04_PROJECTS";   Root = (Join-Path $ProjectRoot "04_PROJECTS");   Out = (Join-Path $OutDir "Radar.04_PROJECTS.txt") },
  @{ Label = "DragnDrop";     Root = (Join-Path $ProjectRoot "DragnDrop");     Out = (Join-Path $OutDir "Radar.DragnDrop.txt") }
)

Write-Host ("[RADAR2] RUN_START ProjectRoot={0}" -f $ProjectRoot)

foreach ($t in $Targets) {
  $root = $t.Root
  $out  = $t.Out
  $lab  = $t.Label

  Write-Host ("[RADAR2] TARGET {0} -> {1}" -f $lab, $out)
  try {
    Write-ConsolidatedOutput -TargetRoot $root -OutFilePath $out -Label $lab
  } catch {
    Write-Host ("[RADAR2] WARN target_failed label={0} root={1} err={2}" -f $lab, $root, $_.Exception.Message)
    continue
  }
}

Write-Host "[RADAR2] RUN_END OK"
exit 0