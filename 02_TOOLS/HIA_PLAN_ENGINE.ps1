<#
===============================================================================
MODULE: HIA_PLAN_ENGINE.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: PLAN ENGINE

OBJETIVO
Crear objetos PLAN dentro del sistema HIA.

Cada PLAN representa una intención de ejecución futura.

VERSION: v1.0-DRAFT
DATE: 2026-03-16
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Task
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-HIAPlan {

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Task
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."

    $plansDir = Join-Path $projectRoot "03_ARTIFACTS\plans"

    if (-not (Test-Path $plansDir)) {
        New-Item -ItemType Directory -Path $plansDir -Force | Out-Null
    }

    $existingPlans = Get-ChildItem $plansDir -Filter "PLAN_*.txt" -ErrorAction SilentlyContinue

    if (-not $existingPlans) {
        $nextId = 1
    }
    else {
        $numbers = @()

        foreach ($file in $existingPlans) {
            $name = $file.Name -replace "PLAN_" -replace ".txt"
            if ($name -match '^\d+$') {
                $numbers += [int]$name
            }
        }

        if ($numbers.Count -eq 0) {
            $nextId = 1
        }
        else {
            $nextId = ($numbers | Measure-Object -Maximum).Maximum + 1
        }
    }

    $planId = "PLAN_" + $nextId.ToString("0000")
    $planPath = Join-Path $plansDir "$planId.txt"

    # Best-effort uniqueness in case of concurrent plan creation
    while (Test-Path $planPath) {
        $nextId++
        $planId = "PLAN_" + $nextId.ToString("0000")
        $planPath = Join-Path $plansDir "$planId.txt"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

    $content = @"
PLAN_ID: $planId

TASK
$Task

STATUS
planned

CREATED
$timestamp

NEXT_ACTION
awaiting apply
"@

    Set-Content -Path $planPath -Value $content -Encoding UTF8

    Write-Host ""
    Write-Host "PLAN CREATED" -ForegroundColor Green
    Write-Host ""
    Write-Host "ID: $planId"
    Write-Host "PATH:"
    Write-Host $planPath
    Write-Host ""

    # -------------------------------------------------------
    # UPDATE REGISTRY
    # -------------------------------------------------------

    $registry = Join-Path $plansDir "PLAN.REGISTRY.txt"
    $utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $registryLine = "$planId | CREATED | $utc | HUMAN | $planPath | $Task"
    Add-Content -Path $registry -Value $registryLine -Encoding UTF8

    # -------------------------------------------------------
    # UPDATE INDEX
    # -------------------------------------------------------

    $index = Join-Path $plansDir "PLAN.INDEX.txt"
    $indexLine = "$planId | planned | $utc | $planPath | $Task"
    Add-Content -Path $index -Value $indexLine -Encoding UTF8
}

New-HIAPlan -Task $Task
