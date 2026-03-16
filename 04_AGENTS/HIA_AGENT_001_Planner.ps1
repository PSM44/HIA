<#
================================================================================
AGENT: HIA_AGENT_001_Planner
VERSION: v1.0-MVP
OBJECTIVE
Transform human request into executable plan.
================================================================================
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Request
)

$ProjectRoot = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$PlanDir = Join-Path $ProjectRoot "03_ARTIFACTS\PLANS"

if (!(Test-Path $PlanDir)) {
    New-Item -ItemType Directory -Path $PlanDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$planFile = Join-Path $PlanDir "PLAN.$timestamp.json"

function Get-HIAPlan {

    param($Request)

    $requestLower = $Request.ToLower()

    switch -Regex ($requestLower) {

        "radar" {
            return @{
                goal="run radar"
                steps=@("radar")
            }
        }

        "validate" {
            return @{
                goal="validate repository"
                steps=@("validate")
            }
        }

        "status" {
            return @{
                goal="show repository status"
                steps=@("status")
            }
        }

        "analyze" {
            return @{
                goal="analyze repository"
                steps=@("validate","radar")
            }
        }

        default {
            return @{
                goal="unknown request"
                steps=@("status")
            }
        }
    }
}

$plan = Get-HIAPlan $Request

$planJson = $plan | ConvertTo-Json -Depth 5

$planJson | Out-File $planFile

Write-Host "PLAN CREATED:"
Write-Host $planJson
Write-Host ""
Write-Host "Saved to:"
Write-Host $planFile