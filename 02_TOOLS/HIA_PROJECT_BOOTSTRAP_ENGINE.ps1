<#
===============================================================================
MODULE: HIA_PROJECT_BOOTSTRAP_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: PROJECT BOOTSTRAP MVP (MB-1.8)
===============================================================================

OBJETIVO
Crear un proyecto mínimo, usable y detectable por la portfolio shell.

ESTRUCTURA MÍNIMA
<ProjectRoot>\
  01_UI\terminal\hia.ps1
  01_UI\terminal\PROJECT.STATE.LIVE.txt
  02_TOOLS\
  03_ARTIFACTS\LOGS\
  03_ARTIFACTS\sessions\
  04_PROJECTS\
  HUMAN.README\README.txt

REGLAS
- No borrar nada.
- Si el directorio ya existe, abortar con mensaje claro.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("wizard", "create")]
    [string]$Command = "wizard",

    [Parameter(Mandatory = $false)]
    [string]$ProjectId,

    [Parameter(Mandatory = $false)]
    [string]$ProjectName,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [ValidateSet("app", "analysis", "automation", "framework", "other")]
    [string]$ProjectType = "other",

    [Parameter(Mandatory = $false)]
    [string]$BaseRoot,

    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:IsDotSourced = ($MyInvocation.InvocationName -eq '.')

function Get-HIAProjectRoot {
    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) { return $current }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { throw "PROJECT_ROOT not found." }
        $current = $parent
    }
}

function Get-DefaultBaseRoot {
    param([string]$CurrentProjectRoot)
    return (Split-Path $CurrentProjectRoot -Parent)
}

function Normalize-ProjectId {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $id = $Value.Trim()
    $id = $id -replace '[^A-Za-z0-9._-]', ''
    return $id
}

function Write-TemplateStateLive {
    param(
        [string]$Path,
        [string]$ProjectId,
        [string]$ProjectName,
        [string]$ProjectType,
        [string]$Description
    )
    $createdUtc = (Get-Date).ToUniversalTime().ToString("o")
    $createdLocal = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $status = "BOOTSTRAPPED"

    $content = @"
================================================================================
FILE: PROJECT.STATE.LIVE.txt
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: Project Bootstrap State (LIVE)
GENERATED: $createdLocal
CREATED_UTC: $createdUtc
================================================================================

PROJECT_ID
------------------------------------------------------------------------------
$ProjectId

PROJECT_NAME
------------------------------------------------------------------------------
$ProjectName

PROJECT_TYPE
------------------------------------------------------------------------------
$ProjectType

STATUS
------------------------------------------------------------------------------
$status

MVP_ACTIVO
------------------------------------------------------------------------------
MB-1.8 — Project Bootstrap Shell MVP

PROXIMO_PASO
------------------------------------------------------------------------------
- Definir plan inicial y primer minibattle
- Ejecutar `hia state sync` cuando el tooling exista

DESCRIPCION
------------------------------------------------------------------------------
$Description

================================================================================
"@

    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Write-TemplateHumanReadme {
    param(
        [string]$Path,
        [string]$ProjectId,
        [string]$ProjectName,
        [string]$ProjectType,
        [string]$Description
    )
    $createdUtc = (Get-Date).ToUniversalTime().ToString("o")
    $content = @"
HIA PROJECT — BOOTSTRAP MVP
==========================

PROJECT_ID:   $ProjectId
PROJECT_NAME: $ProjectName
PROJECT_TYPE: $ProjectType
CREATED_UTC:  $createdUtc
STATUS:       BOOTSTRAPPED

DESCRIPTION
-----------
$Description

NOTES
-----
This project was created by HIA portfolio bootstrap (MB-1.8).
It contains minimal structure to be detected and entered by the portfolio shell.

"@
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

function Write-TemplateProjectHiaEntrypoint {
    param(
        [string]$Path,
        [string]$ProjectRoot
    )

    $script = @'
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
  if ($null -eq $sel) { $sel = '' }
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
'@

    Set-Content -LiteralPath $Path -Value $script -Encoding UTF8
}

function New-HIAProjectBootstrap {
    param(
        [string]$ProjectRoot,
        [string]$ProjectId,
        [string]$ProjectName,
        [string]$Description,
        [string]$ProjectType
    )

    if (Test-Path -LiteralPath $ProjectRoot) {
        throw "Project directory already exists: $ProjectRoot"
    }

    New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null

    $uiTerminal = Join-Path $ProjectRoot "01_UI\\terminal"
    $toolsDir = Join-Path $ProjectRoot "02_TOOLS"
    $logsDir = Join-Path $ProjectRoot "03_ARTIFACTS\\LOGS"
    $sessionsDir = Join-Path $ProjectRoot "03_ARTIFACTS\\sessions"
    $projectsDir = Join-Path $ProjectRoot "04_PROJECTS"
    $humanDir = Join-Path $ProjectRoot "HUMAN.README"

    foreach ($d in @($uiTerminal, $toolsDir, $logsDir, $sessionsDir, $projectsDir, $humanDir)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }

    $statePath = Join-Path $uiTerminal "PROJECT.STATE.LIVE.txt"
    Write-TemplateStateLive -Path $statePath -ProjectId $ProjectId -ProjectName $ProjectName -ProjectType $ProjectType -Description $Description

    $humanReadmePath = Join-Path $humanDir "README.txt"
    Write-TemplateHumanReadme -Path $humanReadmePath -ProjectId $ProjectId -ProjectName $ProjectName -ProjectType $ProjectType -Description $Description

    $hiaPath = Join-Path $uiTerminal "hia.ps1"
    Write-TemplateProjectHiaEntrypoint -Path $hiaPath -ProjectRoot $ProjectRoot

    return [ordered]@{
        project_id = $ProjectId
        project_name = $ProjectName
        project_type = $ProjectType
        project_root = $ProjectRoot
        state_path = $statePath
        hia_path = $hiaPath
        human_readme_path = $humanReadmePath
        created_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
}

function Invoke-HIAProjectBootstrapWizard {
    $currentRoot = Get-HIAProjectRoot
    $defaultBase = Get-DefaultBaseRoot -CurrentProjectRoot $currentRoot

    Write-Host ""
    Write-Host "HIA CREATE PROJECT (BOOTSTRAP MVP)" -ForegroundColor Cyan
    Write-Host ("DEFAULT_BASE_ROOT: {0}" -f $defaultBase) -ForegroundColor DarkGray
    Write-Host ""

    $projectIdValue = Normalize-ProjectId -Value (Read-Host -Prompt " project_id (short)")
    if ([string]::IsNullOrWhiteSpace($projectIdValue)) { throw "project_id required." }

    $projectNameValue = (Read-Host -Prompt " project_name (visible)").Trim()
    if ([string]::IsNullOrWhiteSpace($projectNameValue)) { $projectNameValue = $projectIdValue }

    $descriptionValue = (Read-Host -Prompt " description (brief)").Trim()
    if ([string]::IsNullOrWhiteSpace($descriptionValue)) { $descriptionValue = "Bootstrap project created by HIA." }

    $projectTypeValue = (Read-Host -Prompt " project_type (app/analysis/automation/framework/other) [other]").Trim()
    if ([string]::IsNullOrWhiteSpace($projectTypeValue)) { $projectTypeValue = "other" }

    $baseRootValue = (Read-Host -Prompt (" base_root [{0}]" -f $defaultBase)).Trim()
    if ([string]::IsNullOrWhiteSpace($baseRootValue)) { $baseRootValue = $defaultBase }

    $ptypeNorm = $projectTypeValue.ToLowerInvariant()
    if ($ptypeNorm -notin @("app", "analysis", "automation", "framework", "other")) {
        $ptypeNorm = "other"
    }

    $targetRoot = Join-Path $baseRootValue $projectIdValue
    $result = New-HIAProjectBootstrap -ProjectRoot $targetRoot -ProjectId $projectIdValue -ProjectName $projectNameValue -Description $descriptionValue -ProjectType $ptypeNorm

    Write-Host ""
    Write-Host "PROJECT CREATED" -ForegroundColor Green
    Write-Host ("ROOT: {0}" -f $result.project_root)
    Write-Host ("HIA:  {0}" -f $result.hia_path)
    Write-Host ("STATE:{0}" -f $result.state_path)
    Write-Host ""

    return $result
}

if (-not $script:IsDotSourced) {
    switch ($Command) {
        "wizard" {
            if ($NonInteractive) { throw "wizard cannot be NonInteractive." }
            $r = Invoke-HIAProjectBootstrapWizard
            $r | ConvertTo-Json -Depth 10
            break
        }
        "create" {
            if ([string]::IsNullOrWhiteSpace($BaseRoot)) {
                $currentRoot = Get-HIAProjectRoot
                $BaseRoot = Get-DefaultBaseRoot -CurrentProjectRoot $currentRoot
            }

            $projectIdNorm = Normalize-ProjectId -Value $ProjectId
            if ([string]::IsNullOrWhiteSpace($projectIdNorm)) { throw "ProjectId required." }
            if ([string]::IsNullOrWhiteSpace($ProjectName)) { $ProjectName = $projectIdNorm }
            if ([string]::IsNullOrWhiteSpace($Description)) { $Description = "Bootstrap project created by HIA." }
            if ([string]::IsNullOrWhiteSpace($ProjectType)) { $ProjectType = "other" }
            $ProjectType = $ProjectType.ToLowerInvariant()
            if ($ProjectType -notin @("app", "analysis", "automation", "framework", "other")) { $ProjectType = "other" }

            $targetRoot = Join-Path $BaseRoot $projectIdNorm
            $r = New-HIAProjectBootstrap -ProjectRoot $targetRoot -ProjectId $projectIdNorm -ProjectName $ProjectName -Description $Description -ProjectType $ProjectType
            $r | ConvertTo-Json -Depth 10
            break
        }
    }
}
