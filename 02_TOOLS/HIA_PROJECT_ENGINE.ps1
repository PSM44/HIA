<#
===============================================================================
MODULE: HIA_PROJECT_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: PROJECT ENGINE

OBJETIVO
Listar proyectos activos dentro de 04_PROJECTS.

COMMANDS:
- Get-HIAProjects
===============================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjects {
    $projectsRoot = Join-Path $PSScriptRoot "..\04_PROJECTS"

    if (-not (Test-Path -LiteralPath $projectsRoot)) {
        Write-Host ""
        Write-Host ("ERROR: Project directory not found: {0}" -f $projectsRoot) -ForegroundColor Red
        Write-Host ""
        return
    }

    $projectsRoot = (Resolve-Path -LiteralPath $projectsRoot).Path
    $projects = @(Get-ChildItem -LiteralPath $projectsRoot -Directory -Force -ErrorAction Stop | Sort-Object Name)

    Write-Host ""
    Write-Host "PROYECTOS DETECTADOS" -ForegroundColor Cyan
    Write-Host "-------------------"

    if ($projects.Count -eq 0) {
        Write-Host "No projects found."
        Write-Host ""
        return
    }

    $i = 1
    foreach ($proj in $projects) {
        Write-Host ("{0}. {1}" -f $i, $proj.Name)
        $i++
    }

    Write-Host ""
}
