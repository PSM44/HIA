<#
[HIA_TOL_0016] Move-ToolsNonCanonToDeadHistory.ps1
DATE......: 2026-03-02
TIME......: 01:20
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

PURPOSE...
  Mueve artefactos no-canónicos desde 02_TOOLS a 03_ARTIFACTS\DeadHistory\02_TOOLS\
  (ej: "RADAR copy.ps1", "RADAR.txt", duplicados, etc.)
  Sin borrar, solo Move.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0016_Move-ToolsNonCanonToDeadHistory.ps1 -ProjectRoot "C:\...\HIA" -Force
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log($m){ Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))][INFO] $m" }

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
$tools = Join-Path $ProjectRoot "02_TOOLS"
$dead  = Join-Path $ProjectRoot "03_ARTIFACTS\DeadHistory\02_TOOLS"
New-Item -ItemType Directory -Path $dead -Force | Out-Null

$moveList = @("RADAR copy.ps1","RADAR.txt","HIA_TOL_0010_Move-HIABakFiles.ps1") # ajustable

foreach($n in $moveList){
  $src = Join-Path $tools $n
  if(Test-Path -LiteralPath $src){
    $dst = Join-Path $dead $n
    if(-not $Force){
      Log "DRYRUN_MOVE: $src -> $dst"
    } else {
      Move-Item -LiteralPath $src -Destination $dst -Force
      Log "MOVE: $src -> $dst"
    }
  }
}
Log "DONE"