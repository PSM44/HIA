<#
[HIA_TOL_0006] New-HIAPathIdRegistry.ps1
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.4
PURPOSE...:
  Genera/actualiza 00_FRAMEWORK\HIA_IDR_0001_PATH.ID.REGISTRY.txt
  sin renombrar carpetas/archivos (cero-breaking-change).

ID POLICY (BD-friendly):
  HIA_<CAT>_<NNNN>
  CAT:
    DIR  = folder
    FIL  = file
    TOL  = tool (ps1)
    TXT  = txt
    PDF  = pdf
    OTH  = other

RULES:
  - ID determinista por path (estable mientras path no cambie).
  - Para estabilidad: usa SHA1(path) recortado -> NNNN (numérico) por mapeo base10.
  - No usa Validate-*.

USAGE:
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0006_New-HIAPathIdRegistry.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [switch]$IncludeSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CatFromPath {
  param([string]$RelPath)
  $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
  if ($RelPath -like "02_TOOLS\*.ps1") { return "TOL" }
  switch ($ext) {
    ".txt" { return "TXT" }
    ".ps1" { return "TOL" }
    ".pdf" { return "PDF" }
    default { return "OTH" }
  }
}

function Get-StableNumericId {
  param([string]$RelPath)

  # SHA1(relPath) -> bytes -> big integer -> base10 -> last 4 digits
  $sha1 = [System.Security.Cryptography.SHA1]::Create()
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($RelPath.ToLowerInvariant())
  $hash = $sha1.ComputeHash($bytes)

  # Convert first 8 bytes to UInt64 for determinism
  $u64 = [BitConverter]::ToUInt64($hash, 0)
  $num = [int]($u64 % 10000)  # 0000-9999
  return $num.ToString("D4")
}

function Get-Sha256 {
  param([string]$FullPath)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $fs = [IO.File]::OpenRead($FullPath)
  try {
    $hash = $sha.ComputeHash($fs)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
  } finally {
    $fs.Dispose()
  }
}

$fwDir = Join-Path $ProjectRoot "00_FRAMEWORK"
$regPath = Join-Path $fwDir "HIA_IDR_0001_PATH.ID.REGISTRY.txt"
if (-not (Test-Path $fwDir)) { New-Item -ItemType Directory -Path $fwDir | Out-Null }

$nowDate = (Get-Date).ToString("yyyy-MM-dd")
$nowTime = (Get-Date).ToString("HH:mm")
$nowIso  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")

# Enumerar folders/files (excluye artifacts heavy por defecto; puedes ajustar)
$excludeDirs = @("03_ARTIFACTS\DeadHistory", "03_ARTIFACTS\Logs")
$allItems = Get-ChildItem -Path $ProjectRoot -Recurse -Force -ErrorAction Stop |
  Where-Object {
    $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart('\')
    foreach ($ex in $excludeDirs) {
      if ($rel -like "$ex*") { return $false }
    }
    return $true
  }

# Asegurar header mínimo si no existe
if (-not (Test-Path $regPath)) {
@"
HIA_IDR_0001_PATH.ID.REGISTRY.txt
DATE......: $nowDate
TIME......: $nowTime
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.1

01.00_PURPOSE
Registro canónico BD-friendly: Path -> ID -> Type -> Size -> LastWrite -> Hash(optional)

02.00_SCHEMA
- ID...........: HIA_<CAT>_<NNNN>
- TYPE.........: Folder | File
- REL_PATH.....: relative path desde ProjectRoot
- SIZE_BYTES...: para File
- LASTWRITE...: ISO 8601
- SHA256......: opcional (si activas hashing)

03.00_DATA
# Re-generado por HIA_TOL_0006_New-HIAPathIdRegistry.ps1

"@ | Out-File -FilePath $regPath -Encoding utf8
}

# Reescribir SOLO sección 03.00_DATA (mantener header)
$content = Get-Content $regPath -Raw -Encoding utf8
$marker = "03.00_DATA"
$idx = $content.IndexOf($marker)
if ($idx -lt 0) { throw "No se encontró marcador 03.00_DATA en $regPath" }

$prefix = $content.Substring(0, $idx + $marker.Length)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# GENERATED_TS: $nowIso")
$lines.Add("# FORMAT: ID | TYPE | CAT | REL_PATH | SIZE_BYTES | LASTWRITE | SHA256(optional)")

foreach ($it in $allItems) {
  $rel = $it.FullName.Substring($ProjectRoot.Length).TrimStart('\')
  $type = $(if ($it.PSIsContainer) { "Folder" } else { "File" })
  $cat = $(if ($it.PSIsContainer) { "DIR" } else { Get-CatFromPath -RelPath $rel })
  $nnnn = Get-StableNumericId -RelPath $rel
  $id = "HIA_{0}_{1}" -f $cat, $nnnn

  $size = ""
  $sha256 = ""
  if (-not $it.PSIsContainer) {
    $size = $it.Length.ToString()
    if ($IncludeSha256) { $sha256 = Get-Sha256 -FullPath $it.FullName }
  }

  $lw = $it.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss")
  $lines.Add(("{0} | {1} | {2} | {3} | {4} | {5} | {6}" -f $id, $type, $cat, $rel, $size, $lw, $sha256).TrimEnd())
}

$new = $prefix + "`r`n" + ($lines -join "`r`n") + "`r`n"
$new | Out-File -FilePath $regPath -Encoding utf8
Write-Host "OK: Registry actualizado -> $regPath"