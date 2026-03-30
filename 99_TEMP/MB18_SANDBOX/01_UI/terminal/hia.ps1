<#
HIA PROJECT ENTRYPOINT (BOOTSTRAP MVP)
This project does not include the full HIA toolchain yet.
It provides a minimal local shell to view state and basic info.
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [string]$Command
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ProjectRoot {
  $current = $PSScriptRoot
  while ($true) {
    if (Test-Path -LiteralPath (Join-Path $current '02_TOOLS')) { return $current }
    $parent = Split-Path $current -Parent
    if ($parent -eq $current) { throw 'PROJECT_ROOT not found.' }
    $current = $parent
  }
}

function Show-Header {
  param([string]$Root)
  try { Clear-Host } catch { }
  Write-Host ''
  Write-Host '===================================' -ForegroundColor Cyan
  Write-Host ' HIA — Project Shell (Bootstrap MVP)'
  Write-Host '===================================' -ForegroundColor Cyan
  Write-Host (' ROOT: {0}' -f $Root)
  Write-Host (' NOW:  {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
  Write-Host ''
}

function Show-State {
  param([string]$Root)
  $p = Join-Path $Root '01_UI\terminal\PROJECT.STATE.LIVE.txt'
  if (-not (Test-Path -LiteralPath $p)) {
    Write-Host 'STATE LIVE not found.' -ForegroundColor Yellow
    Write-Host ('PATH: {0}' -f $p) -ForegroundColor DarkGray
    return
  }
  Get-Content -LiteralPath $p
}

$root = Get-ProjectRoot

if (-not $Command) {
  Show-Header -Root \$root
  Write-Host '1.- Ver PROJECT.STATE.LIVE'
  Write-Host 'F1.- Ayuda'
  Write-Host '0.- Salir'
  Write-Host ''
  $sel = Read-Host -Prompt ' Seleccion'
  switch ($sel.ToUpperInvariant()) {
    '1' { Show-Header -Root $root; Show-State -Root $root; Read-Host -Prompt ' Enter para salir' | Out-Null }
    'F1' { Show-Header -Root $root; Write-Host 'Bootstrap MVP: solo lectura de estado.' -ForegroundColor Yellow; Read-Host -Prompt ' Enter para salir' | Out-Null }
    default { }
  }
  exit 0
}

switch ($Command.ToLowerInvariant()) {
  'state' { Show-State -Root $root; exit 0 }
  'help' { Write-Host 'Commands: state, help'; exit 0 }
  default { Write-Host 'Unknown command. Use: help' -ForegroundColor Yellow; exit 1 }
}
