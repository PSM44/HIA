<#
===============================================================================
FILE..............: HIA_RELEASE_READINESS_VALIDATOR.ps1
PROJECT...........: PRJ_0001_HIA.PRODUCT
TYPE..............: GOVERNED RELEASE-READINESS VALIDATOR
VERSION...........: v0.1
DATE..............: 2026-06-05
CITY..............: Santiago, Chile
PURPOSE...........: Ejecutar validación PASS/FAIL de CURRENT_STATE, CLI, snapshot, evidencia,
                     RADAR y git clean antes de release-candidate interno.
NOTE..............: Usa Test-* naming. No usar Validate-* para evitar verbos no aprobados.
===============================================================================
#>

[CmdletBinding()]
param(
    [string]$RepoRoot = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA",
    [string]$ProjectId = "PRJ_0001_HIA.PRODUCT",
    [string]$ExpectedNextActionId = "PRJPB_009X"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Checks = New-Object System.Collections.Generic.List[object]

function Add-HIACheck {
    param(
        [string]$Id,
        [string]$Status,
        [string]$Detail
    )

    $script:Checks.Add([pscustomobject]@{
        id = $Id
        status = $Status
        detail = $Detail
    }) | Out-Null
}

function Test-HIAFileExists {
    param(
        [string]$Id,
        [string]$Path
    )

    $full = Join-Path $RepoRoot $Path
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        Add-HIACheck -Id $Id -Status "PASS" -Detail "$Path exists"
        return $true
    }

    Add-HIACheck -Id $Id -Status "FAIL" -Detail "$Path missing"
    return $false
}

function Get-HIAFileText {
    param([string]$Path)

    $full = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        return ""
    }

    return [System.IO.File]::ReadAllText($full)
}

function Test-HIAContains {
    param(
        [string]$Id,
        [string]$Path,
        [string]$Pattern,
        [string]$HumanDetail
    )

    $text = Get-HIAFileText -Path $Path
    if ($text -match $Pattern) {
        Add-HIACheck -Id $Id -Status "PASS" -Detail $HumanDetail
        return $true
    }

    Add-HIACheck -Id $Id -Status "FAIL" -Detail "$HumanDetail not found in $Path"
    return $false
}

function Invoke-HIACommandText {
    param([string]$CommandText)

    $old = Get-Location
    try {
        Set-Location -LiteralPath $RepoRoot
        $output = powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $CommandText 2>&1
        return (($output | ForEach-Object { [string]$_ }) -join "`n")
    }
    finally {
        Set-Location -LiteralPath $old
    }
}

function Test-HIAGitClean {
    $status = (& git -C $RepoRoot status --short 2>&1)
    $text = (($status | ForEach-Object { [string]$_ }) -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        Add-HIACheck -Id "GIT_CLEAN" -Status "PASS" -Detail "git status --short clean"
        return $true
    }

    Add-HIACheck -Id "GIT_CLEAN" -Status "FAIL" -Detail ("git status not clean: " + $text)
    return $false
}

function Test-HIACurrentState {
    $path = "04_PROJECTS/$ProjectId/STATE/CURRENT_STATE.json"
    $full = Join-Path $RepoRoot $path

    if (-not (Test-HIAFileExists -Id "CURRENT_STATE_EXISTS" -Path $path)) {
        return
    }

    try {
        $json = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json
        if ($json.schema -eq "HIA_CURRENT_STATE.v1") {
            Add-HIACheck -Id "CURRENT_STATE_SCHEMA" -Status "PASS" -Detail "schema=HIA_CURRENT_STATE.v1"
        }
        else {
            Add-HIACheck -Id "CURRENT_STATE_SCHEMA" -Status "FAIL" -Detail ("schema=" + [string]$json.schema)
        }

        if ($json.project_id -eq $ProjectId) {
            Add-HIACheck -Id "CURRENT_STATE_PROJECT" -Status "PASS" -Detail "project_id matches"
        }
        else {
            Add-HIACheck -Id "CURRENT_STATE_PROJECT" -Status "FAIL" -Detail ("project_id=" + [string]$json.project_id)
        }

        $nextId = [string]$json.next_action.id
        if ($nextId -eq $ExpectedNextActionId) {
            Add-HIACheck -Id "CURRENT_STATE_NEXT_ACTION" -Status "PASS" -Detail ("next_action.id=" + $nextId)
        }
        else {
            Add-HIACheck -Id "CURRENT_STATE_NEXT_ACTION" -Status "FAIL" -Detail ("expected=" + $ExpectedNextActionId + " actual=" + $nextId)
        }

        if ([string]$json.evidence.state -eq "FRESH") {
            Add-HIACheck -Id "CURRENT_STATE_EVIDENCE_FRESH" -Status "PASS" -Detail "evidence.state=FRESH"
        }
        else {
            Add-HIACheck -Id "CURRENT_STATE_EVIDENCE_FRESH" -Status "FAIL" -Detail ("evidence.state=" + [string]$json.evidence.state)
        }
    }
    catch {
        Add-HIACheck -Id "CURRENT_STATE_JSON_PARSE" -Status "FAIL" -Detail $_.Exception.Message
    }
}

function Test-HIACliContinuity {
    $commands = @(
        @{ id = "CLI_CONTINUE"; cmd = ".\01_UI\terminal\hia.ps1 project continue $ProjectId" },
        @{ id = "CLI_STATUS";   cmd = ".\01_UI\terminal\hia.ps1 project status $ProjectId" },
        @{ id = "CLI_REVIEW";   cmd = ".\01_UI\terminal\hia.ps1 project review $ProjectId" }
    )

    foreach ($item in $commands) {
        $out = Invoke-HIACommandText -CommandText ("Set-Location '" + $RepoRoot + "'; " + $item.cmd)
        if (($out -match $ExpectedNextActionId) -and ($out -match "CURRENT_STATE")) {
            Add-HIACheck -Id $item.id -Status "PASS" -Detail ($item.cmd + " returns " + $ExpectedNextActionId + " from CURRENT_STATE")
        }
        else {
            Add-HIACheck -Id $item.id -Status "FAIL" -Detail ($item.cmd + " did not prove " + $ExpectedNextActionId + " from CURRENT_STATE")
        }
    }
}

function Test-HIAControlTowerSnapshot {
    $path = "01_UI/web/control-tower-shell/assets/hia.state.js"

    Test-HIAFileExists -Id "STATE_JS_EXISTS" -Path $path | Out-Null
    Test-HIAContains -Id "STATE_JS_CURRENT_STATE_PRIMARY" -Path $path -Pattern "CURRENT_STATE_PRIMARY" -HumanDetail "hia.state.js declares CURRENT_STATE_PRIMARY" | Out-Null
    Test-HIAContains -Id "STATE_JS_VALID" -Path $path -Pattern "current_state_status:\s*`"VALID`"" -HumanDetail "hia.state.js declares current_state_status VALID" | Out-Null
    Test-HIAContains -Id "STATE_JS_NEXT_ACTION" -Path $path -Pattern ([regex]::Escape($ExpectedNextActionId)) -HumanDetail ("hia.state.js contains " + $ExpectedNextActionId) | Out-Null
    Test-HIAContains -Id "STATE_JS_SEMANTIC_HASH" -Path $path -Pattern "SEMANTIC_HASH" -HumanDetail "hia.state.js contains SEMANTIC_HASH" | Out-Null
}

function Test-HIAGovernanceDocs {
    Test-HIAFileExists -Id "GOV_CURRENT_STATE_CONTRACT" -Path "04_PROJECTS/$ProjectId/GOVERNANCE/CURRENT_STATE.CONTRACT.md" | Out-Null
    Test-HIAFileExists -Id "GOV_EVIDENCE_POLICY" -Path "04_PROJECTS/$ProjectId/GOVERNANCE/EVIDENCE.VERSIONING.POLICY.md" | Out-Null
    Test-HIAContains -Id "GOV_CURRENT_STATE_PRIMARY" -Path "04_PROJECTS/$ProjectId/GOVERNANCE/CURRENT_STATE.CONTRACT.md" -Pattern "CURRENT_STATE" -HumanDetail "CURRENT_STATE contract references CURRENT_STATE" | Out-Null
    Test-HIAContains -Id "GOV_EVIDENCE_VERSIONING" -Path "04_PROJECTS/$ProjectId/GOVERNANCE/EVIDENCE.VERSIONING.POLICY.md" -Pattern "EVIDENCE|ARTIFACTS|DELIVERY|STATE" -HumanDetail "Evidence policy references evidence/versioning scope" | Out-Null
}

function Test-HIARadarPresence {
    Test-HIAFileExists -Id "RADAR_LITE" -Path "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt" | Out-Null
    Test-HIAFileExists -Id "RADAR_INDEX" -Path "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt" | Out-Null
    Test-HIAFileExists -Id "RADAR_CORE" -Path "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt" | Out-Null
}

function Test-HIAControlTowerGeneratorCheck {
    $generator = Join-Path $RepoRoot "02_TOOLS\HIA_CONTROL_TOWER_STATE_GENERATOR.ps1"
    if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) {
        Add-HIACheck -Id "CONTROL_TOWER_GENERATOR_EXISTS" -Status "FAIL" -Detail "generator missing"
        return
    }

    $out = Invoke-HIACommandText -CommandText ("& '" + $generator + "' -ProjectId '" + $ProjectId + "' -RepoRoot '" + $RepoRoot + "'")
    if (($out -match "WRITE_MODE:\s*CHECK") -and ($out -match "CURRENT_STATE_STATUS:\s*VALID") -and ($out -match $ExpectedNextActionId)) {
        Add-HIACheck -Id "CONTROL_TOWER_GENERATOR_CHECK" -Status "PASS" -Detail "generator CHECK returns VALID and expected next action"
    }
    else {
        Add-HIACheck -Id "CONTROL_TOWER_GENERATOR_CHECK" -Status "FAIL" -Detail "generator CHECK did not prove VALID expected state"
    }
}

Write-Host "========== HIA RELEASE READINESS VALIDATOR / START =========="
Write-Host ("PROJECT_ID.......: {0}" -f $ProjectId)
Write-Host ("EXPECTED_NEXT....: {0}" -f $ExpectedNextActionId)
Write-Host ("REPO_ROOT........: {0}" -f $RepoRoot)
Write-Host "======================================================================"

Test-HIAGitClean
Test-HIACurrentState
Test-HIACliContinuity
Test-HIAControlTowerSnapshot
Test-HIAGovernanceDocs
Test-HIARadarPresence
Test-HIAControlTowerGeneratorCheck

$failCount = @($script:Checks | Where-Object { $_.status -ne "PASS" }).Count
foreach ($check in $script:Checks) {
    Write-Host ("{0} | {1} | {2}" -f $check.status, $check.id, $check.detail)
}

if ($failCount -eq 0) {
    Write-Host "RESULT...........: PASS"
    Write-Host "========== HIA RELEASE READINESS VALIDATOR / END =========="
    exit 0
}

Write-Host ("RESULT...........: FAIL ({0} failing checks)" -f $failCount)
Write-Host "========== HIA RELEASE READINESS VALIDATOR / END =========="
exit 1
