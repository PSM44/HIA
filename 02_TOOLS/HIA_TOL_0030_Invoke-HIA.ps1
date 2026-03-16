<#
========================================================================================
SCRIPT: HIA_TOL_0030_Invoke-HIA.ps1
VERSION: v1.0-MVP
DATE: 2026-03-14
SYSTEM: HIA Execution Engine

OBJECTIVE
Core execution engine for HIA system.

FLOW
PLAN → APPLY → VALIDATE → LOG

========================================================================================
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [ValidateSet("DRAFT","CANON")]
    [string]$Mode = "DRAFT",

    [switch]$Force
)

# -------------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------------

$ProjectRoot = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$Tools = Join-Path $ProjectRoot "02_TOOLS"
$Artifacts = Join-Path $ProjectRoot "03_ARTIFACTS\LOGS"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $Artifacts "HIA.RUN.$timestamp.log"

# -------------------------------------------------------------------
# LOGGING
# -------------------------------------------------------------------

function Write-HIALog {

    param(
        [string]$Message,
        [string]$Level="INFO"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[HIA][$time][$Level] $Message"

    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

# -------------------------------------------------------------------
# PLAN
# -------------------------------------------------------------------

function Invoke-HIAPlan {

    param($Command)

    Write-HIALog "PLAN_START command=$Command"

    switch ($Command) {

        "radar" { return "RUN_RADAR" }

        "validate" { return "RUN_VALIDATORS" }

        "checkpoint" { return "RUN_CHECKPOINT" }

        "sync" { return "RUN_SYNC" }

        "status" { return "RUN_STATUS" }

        default {
            throw "Unknown command: $Command"
        }

    }
}

# -------------------------------------------------------------------
# APPLY
# -------------------------------------------------------------------

function Invoke-HIAApply {

    param($Action)

    Write-HIALog "APPLY_START action=$Action"

    switch ($Action) {

        "RUN_RADAR" {

            pwsh "$Tools\RADAR.ps1"

        }

        "RUN_VALIDATORS" {

            pwsh "$Tools\Invoke-HIAValidators.ps1" -Mode $Mode

        }

        "RUN_CHECKPOINT" {

            pwsh "$Tools\Invoke-HIAGitCheckpoint.ps1"

        }

        "RUN_SYNC" {

            pwsh "$Tools\Invoke-HIASync.ps1"

        }

        "RUN_STATUS" {

            git status

        }

        default {

            throw "Unknown action: $Action"

        }

    }

}

# -------------------------------------------------------------------
# VALIDATE
# -------------------------------------------------------------------

function Invoke-HIAValidate {

    Write-HIALog "VALIDATION_START"

    pwsh "$Tools\Invoke-HIAValidators.ps1" -Mode $Mode

}

# -------------------------------------------------------------------
# RADAR
# -------------------------------------------------------------------

function Invoke-HIARadar {

    Write-HIALog "RADAR_START"

    pwsh "$Tools\RADAR.ps1"

}

# -------------------------------------------------------------------
# MAIN
# -------------------------------------------------------------------

try {

    Write-HIALog "RUN_START command=$Command mode=$Mode"

    $action = Invoke-HIAPlan $Command

    Invoke-HIAApply $action

    Invoke-HIAValidate

    Invoke-HIARadar

    Write-HIALog "RUN_COMPLETE"

}
catch {

    Write-HIALog "ERROR $_" "ERROR"

    exit 1

}