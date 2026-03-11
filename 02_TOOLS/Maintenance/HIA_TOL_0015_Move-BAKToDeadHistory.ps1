<#
[HIA_TOL_0015] Move-BAKToDeadHistory.ps1
DATE......: 2026-03-01
TIME......: 20:55
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

PURPOSE...
  Mueve archivos *.bak* generados por tooling hacia 03_ARTIFACTS\DeadHistory\BAK\YYYYMMDD_HHMM\
  Mantiene estructura relativa para auditoría.
  Default: Dry-run. Usa -Force para ejecutar.

SCOPE...
  Incluye repo completo (incluye HUMAN) excepto:
    - .git\
    - 03_ARTIFACTS\ (para no re-mover historial)
    - Raw\

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0015_Move-BAKToDeadHistory.ps1 -ProjectRoot "C:\...\HIA"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0015_Move-BAKToDeadHistory.ps1 -ProjectRoot "C:\...\HIA" -Force
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log([string]$Msg, [string]$Level="INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Msg"
}

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$deadRoot = Join-Path $ProjectRoot "03_ARTIFACTS\DeadHistory\BAK"
$stamp = (Get-Date).ToString("yyyyMMdd_HHmm")
$destRoot = Join-Path $deadRoot $stamp
New-Item -ItemType Directory -Path $destRoot -Force | Out-Null

$bakFiles = Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Force -File |
  Where-Object {
    ($_.Name -match '\.bak(\.|$)') -or ($_.Name -match '\.bak\.') -or ($_.Name -match '\.bak')
  } |
  Where-Object {
    ($_.FullName -notmatch "\\\.git\\") -and
    ($_.FullName -notmatch "\\03_ARTIFACTS\\") -and
    ($_.FullName -notmatch "\\Raw\\")
  }

Write-Log "BAK files encontrados: $($bakFiles.Count). Force=$Force"

foreach ($f in $bakFiles) {
  $rel = $f.FullName.Substring($ProjectRoot.Length).TrimStart('\')
  $dst = Join-Path $destRoot $rel
  $dstDir = Split-Path $dst -Parent
  if (-not (Test-Path -LiteralPath $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

  if ($Force) {
    Write-Log "MOVE: $rel -> 03_ARTIFACTS\DeadHistory\BAK\$stamp\$rel"
    Move-Item -LiteralPath $f.FullName -Destination $dst -Force
  } else {
    Write-Log "DRYRUN_MOVE: $rel -> 03_ARTIFACTS\DeadHistory\BAK\$stamp\$rel" "WARN"
  }
}

Write-Log "DONE"