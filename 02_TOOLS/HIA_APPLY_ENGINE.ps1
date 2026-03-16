<#
===============================================================================
MODULE: HIA_APPLY_ENGINE.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: APPLY GATE

OBJETIVO
Permitir aprobación humana antes de ejecutar un PLAN.

VERSION: v1.0-DRAFT
DATE: 2026-03-16
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PlanId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-HIAApply {

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PlanId
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."

    $plansDir = Join-Path $projectRoot "03_ARTIFACTS\plans"

    $planPath = Join-Path $plansDir "$PlanId.txt"

    if (-not (Test-Path $planPath)) {

        Write-Host ""
        Write-Host "PLAN NOT FOUND: $PlanId"
        Write-Host ""
        return

    }

    $content = Get-Content $planPath

    $taskLineIndex = $content.IndexOf("TASK") + 1
    $task = $content[$taskLineIndex]

    $statusLineIndex = $content.IndexOf("STATUS") + 1
    $status = $content[$statusLineIndex]

    Write-Host ""
    Write-Host "PLAN STATUS: $status"
    Write-Host ""

    if ($status -ne "planned") {

        Write-Host "PLAN is not in planned state."
        return

    }

    Write-Host "PLAN_ID: $PlanId"
    Write-Host "TASK: $task"
    Write-Host ""

    Write-Host "Confirm execution context"
    Write-Host ""

    $now = Get-Date

    $date = $now.ToString("yyyy-MM-dd")
    $time = $now.ToString("HH:mm")

    $tz = "America/Santiago"
    $city = "Santiago, Chile"

    Write-Host "DATE......: $date"
    Write-Host "TIME......: $time"
    Write-Host "TZ........: $tz"
    Write-Host "CITY......: $city"
    Write-Host ""

    $approval = Read-Host "Approve PLAN execution? (y/n)"

    if ($approval -ne "y") {

        Write-Host ""
        Write-Host "PLAN execution cancelled."
        Write-Host ""
        return

    }

    $updatedContent = $content -replace "STATUS\s+planned", "STATUS`napproved"

    Set-Content -Path $planPath -Value $updatedContent -Encoding UTF8

    Write-Host ""
    Write-Host "PLAN APPROVED" -ForegroundColor Green
    Write-Host ""

}

Invoke-HIAApply -PlanId $PlanId
