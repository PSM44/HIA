<#
[HIA_TOL_0010] Move-HIABakFiles.ps1
DATE......: 2026-03-01
TIME......: 19:20
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

PURPOSE...
  Mueve todos los *.bak (fuera de 03_ARTIFACTS) a:
    03_ARTIFACTS\DeadHistory\BAK\YYYYMMDD_HHMM\
  Mantiene estructura relativa para trazabilidad.

SAFETY...
  - No borra. Solo mueve.
  - No toca archivos dentro de 03_ARTIFACTS.
  - Crea carpetas si faltan.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0010_Move-HIABakFiles.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level, [string]$Message)
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Message"
}

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$stamp = (Get-Date).ToString("yyyyMMdd_HHmm")
$destRoot = Join-Path $ProjectRoot ("03_ARTIFACTS\DeadHistory\BAK\" + $stamp)
New-Item -ItemType Directory -Path $destRoot -Force | Out-Null

$bakFiles = Get-ChildItem -Path $ProjectRoot -Recurse -File -Force |
  Where-Object {
    $_.Name -like "*.bak" -and
    ($_.FullName -notmatch "\\03_ARTIFACTS\\")
  }

if (-not $bakFiles) {
  Write-Log "INFO" "No se encontraron *.bak para mover."
  exit 0
}

foreach ($f in $bakFiles) {
  $rel = $f.FullName.Substring($ProjectRoot.Length).TrimStart('\')
  $target = Join-Path $destRoot $rel
  $targetDir = Split-Path $target -Parent
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

  Move-Item -LiteralPath $f.FullName -Destination $target
  Write-Log "INFO" ("Movido: " + $rel + " -> " + $target.Substring($ProjectRoot.Length).TrimStart('\'))
}

Write-Log "INFO" "DONE: Move-HIABakFiles"