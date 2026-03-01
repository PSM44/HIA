<#
[HIA_TOL_0009] Repair-HIAMetadata.ps1
DATE......: 2026-03-01
TIME......: 18:45
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.4

PURPOSE...
  Repara metadata mínima en archivos .txt existentes.
  - SYSTEM/FRAMEWORK: inserta metadata si falta (modo office).
  - HUMAN: por defecto NO toca, solo reporta (para respetar "HUMAN solo crece").
    Si se usa -IncludeHuman, inserta metadata como bloque "00.00_METADATA_ADDED"
    sin eliminar ni reordenar el resto del contenido.

SAFETY...
  - No Validate-*.
  - Backup soft: copia .bak al lado antes de modificar (solo para SYSTEM por defecto).
  - No pisa: si detecta DATE/TIME/VERSION ya presentes, no cambia.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0009_Repair-HIAMetadata.ps1 -ProjectRoot "C:\...\HIA"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0009_Repair-HIAMetadata.ps1 -ProjectRoot "..." -IncludeHuman
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [switch]$IncludeHuman
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level, [string]$RelPath, [string]$Message)
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $RelPath :: $Message"
}

# Normalize
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$nowDate = (Get-Date).ToString("yyyy-MM-dd")
$nowTime = (Get-Date).ToString("HH:mm")
$tz = "America/Santiago"
$city = "Santiago, Chile"

function Has-Key {
  param([string]$Raw, [string]$Key)

  # Solo considerar el "header" para evitar falsos positivos en el cuerpo del documento.
  # Esto habilita la inyección real de VERSION/TIME/DATE aunque aparezcan palabras similares más abajo.
  $maxLines = 120
  $lines = $Raw -split "(`r`n|`n|`r)"

  if ($lines.Count -gt $maxLines) {
    $lines = $lines[0..($maxLines - 1)]
  }

  $head = ($lines -join "`n")
  return ($head -match "(?im)^\s*$Key\.{3,}\s*:")
}

function Get-MetadataBlock {
  param([string]$RelPath, [switch]$ForHuman)

  $idHint = ""
  if ($RelPath -match "(?i)(HIA_[A-Z]{3}_[0-9]{4})") { $idHint = $Matches[1] }

  if ($ForHuman) {
@"
00.00_METADATA_ADDED
DATE......: $nowDate
TIME......: $nowTime
TZ........: $tz
CITY......: $city
VERSION......: 0.1
NOTE......: Metadata agregado en modo office. No altera el contenido conceptual HUMAN.
ID_HINT...: $idHint

"@
  } else {
@"
DATE......: $nowDate
TIME......: $nowTime
TZ........: $tz
CITY......: $city
VERSION......: 0.1
ID_HINT...: $idHint

"@
  }
}

# Enumerar .txt excluyendo artifacts
$files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Force |
  Where-Object {
    $_.Extension.ToLowerInvariant() -eq ".txt" -and
    ($_.FullName -notmatch "\\03_ARTIFACTS\\")
  }

foreach ($f in $files) {
  $rel = $f.FullName.Substring($ProjectRoot.Length).TrimStart('\')
  $isHuman = ($rel -like "HUMAN.README\*")

  if ($isHuman -and -not $IncludeHuman) {
    # Solo reporta
    $raw = Get-Content -Path $f.FullName -Raw -Encoding utf8
    $missing = @()
    foreach ($k in @("DATE","TIME","VERSION")) { if (-not (Has-Key -Raw $raw -Key $k)) { $missing += $k } }
    if ($missing.Count -gt 0) { Write-Log "WARN" $rel ("HUMAN sin metadata: " + ($missing -join ",")) }
    continue
  }

  # SYSTEM/FRAMEWORK o HUMAN permitido
  $raw = Get-Content -Path $f.FullName -Raw -Encoding utf8
  $need = @()
  foreach ($k in @("DATE","TIME","VERSION")) { if (-not (Has-Key -Raw $raw -Key $k)) { $need += $k } }
  if ($need.Count -eq 0) { continue }

  # Backup soft
  Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName + ".bak") -Force

  $block = Get-MetadataBlock -RelPath $rel -ForHuman:$isHuman
  $newRaw = $block + $raw
  $newRaw | Out-File -FilePath $f.FullName -Encoding utf8
  Write-Log "INFO" $rel ("Metadata insertada: " + ($need -join ","))
}

Write-Host "DONE: Repair-HIAMetadata"