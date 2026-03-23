<#
===============================================================================
MODULE: HIA_RUN_ENGINE.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: EXECUTION ENGINE

OBJETIVO
Ejecutar PLAN previamente aprobado.

VERSION: v1.0-DRAFT
DATE: 2026-03-23
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PlanId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-HIARun {

    param(
        [string]$PlanId
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $plansDir = Join-Path $projectRoot "03_ARTIFACTS\plans"
    $planPath = Join-Path $plansDir "$PlanId.txt"

    if (-not (Test-Path $planPath)) {
        Write-Host ""
        Write-Host "PLAN NOT FOUND: $PlanId" -ForegroundColor Red
        Write-Host ""
        return
    }

    $content = Get-Content $planPath

    # -----------------------------
    # PARSE STATUS
    # -----------------------------
    $statusIndex = $content.IndexOf("STATUS") + 1
    $status = $content[$statusIndex]

    if ($status -ne "approved") {
        Write-Host ""
        Write-Host "PLAN NOT APPROVED" -ForegroundColor Yellow
        Write-Host "STATUS: $status"
        Write-Host ""
        return
    }

    # -----------------------------
    # PARSE TASK
    # -----------------------------
    $taskIndex = $content.IndexOf("TASK") + 1
    $task = $content[$taskIndex]

    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host " HIA RUN ENGINE"
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "PLAN_ID: $PlanId"
    Write-Host "TASK: $task"
    Write-Host ""

    # -----------------------------
    # EXECUTION MAPPING (MVP)
    # -----------------------------
    switch ($task.ToLower()) {

        "run radar" {
            Write-Host "Executing RADAR..." -ForegroundColor Green
            & "$projectRoot\02_TOOLS\RADAR.ps1"
        }

        "run validate" {
            Write-Host "Executing VALIDATE..." -ForegroundColor Green
            & "$projectRoot\02_TOOLS\Invoke-HIAValidators.ps1"
        }

        default {
            Write-Host ""
            Write-Host "UNKNOWN TASK: $task" -ForegroundColor Red
            Write-Host ""
            return
        }
    }

    # -----------------------------
    # UPDATE PLAN STATUS
    # -----------------------------
$statusIndex = $content.IndexOf("STATUS") + 1
$content[$statusIndex] = "executed"
Set-Content -Path $planPath -Value $content -Encoding UTF8

    Write-Host ""
    Write-Host "PLAN EXECUTED" -ForegroundColor Green
    Write-Host ""

}

Invoke-HIARun -PlanId $PlanId