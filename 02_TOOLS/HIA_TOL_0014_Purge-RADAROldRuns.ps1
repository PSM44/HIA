<#
[HIA_TOL_0014] Purge-RADAROldRuns.ps1
DATE......: 2026-03-01
TIME......: 20:55
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

PURPOSE...
  Mantener solo los últimos N runs en 03_ARTIFACTS\RADAR\old\ (por carpeta).
  Purga lo demás (delete) bajo gate -Force. Sin -Force, solo reporta (dry-run).

NOTES...
  - Asume que cada run vive en su carpeta dentro de old\ (como tu RADAR genera).
  - Ordena por LastWriteTime desc.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0014_Purge-RADAROldRuns.ps1 -ProjectRoot "C:\...\HIA" -Keep 10
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0014_Purge-RADAROldRuns.ps1 -ProjectRoot "C:\...\HIA" -Keep 10 -Force
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [int]$Keep = 10,

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

$oldDir = Join-Path $ProjectRoot "03_ARTIFACTS\RADAR\old"
if (-not (Test-Path -LiteralPath $oldDir)) {
  Write-Log "No existe old dir: $oldDir (nada que purgar)" "WARN"
  exit 0
}

$runDirs = @(Get-ChildItem -LiteralPath $oldDir -Directory -Force | Sort-Object -Property LastWriteTime -Descending)
$runCount = $runDirs.Count

Write-Log "old runs encontrados: $runCount. Keep=$Keep. Force=$Force"

if ($runCount -le $Keep) {
  Write-Log "Nada que purgar (<= Keep)."
  exit 0
}

$toDelete = $runDirs | Select-Object -Skip $Keep
foreach ($d in $toDelete) {
  if ($Force) {
    Write-Log "DELETE: $($d.FullName)"
    Remove-Item -LiteralPath $d.FullName -Recurse -Force
  } else {
    Write-Log "DRYRUN_DELETE: $($d.FullName)" "WARN"
  }
}

Write-Log "DONE"