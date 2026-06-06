<#
===============================================================================
FILE..............: HIA_RELEASE_READINESS_VALIDATOR.ps1
PROJECT...........: PRJ_0001_HIA.PRODUCT
TYPE..............: GOVERNED RELEASE-READINESS VALIDATOR
VERSION...........: v0.2
DATE..............: 2026-06-06
CITY..............: Santiago, Chile
PURPOSE...........: Validar PASS/FAIL estricto de release-readiness.
NOTE..............: Usa Test-* naming. Prohibido Validate-*.
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

$checks = New-Object System.Collections.Generic.List[object]

function Add-HIACheck {
    param([string]$Id, [string]$Status, [string]$Detail)
    $checks.Add([pscustomobject]@{ id=$Id; status=$Status; detail=$Detail }) | Out-Null
}

function Get-HIAFileRaw {
    param([string]$RelPath)
    $path = Join-Path $RepoRoot $RelPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return "" }
    return [System.IO.File]::ReadAllText($path)
}

function Test-HIAFileExists {
    param([string]$Id, [string]$RelPath)
    $path = Join-Path $RepoRoot $RelPath
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Add-HIACheck $Id "PASS" "$RelPath exists"
        return
    }
    Add-HIACheck $Id "FAIL" "$RelPath missing"
}

function Invoke-HIACommandText {
    param([string]$Command)
    $old = Get-Location
    try {
        Set-Location -LiteralPath $RepoRoot
        $out = powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $Command 2>&1
        return (($out | ForEach-Object { [string]$_ }) -join "`n")
    }
    finally {
        Set-Location -LiteralPath $old
    }
}

function Test-HIAGitClean {
    $out = (& git -C $RepoRoot status --short 2>&1)
    $txt = (($out | ForEach-Object { [string]$_ }) -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($txt)) {
        Add-HIACheck "GIT_CLEAN" "PASS" "git status --short clean"
    }
    else {
        Add-HIACheck "GIT_CLEAN" "FAIL" ("git dirty: " + $txt)
    }
}

function Test-HIACurrentStateStrict {
    $rel = "04_PROJECTS/$ProjectId/STATE/CURRENT_STATE.json"
    $full = Join-Path $RepoRoot $rel

    Test-HIAFileExists "CURRENT_STATE_EXISTS" $rel
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return }

    try {
        $json = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json
        $next = $json.next_action

        if ($json.schema -eq "HIA_CURRENT_STATE.v1") {
            Add-HIACheck "CURRENT_STATE_SCHEMA" "PASS" "schema=HIA_CURRENT_STATE.v1"
        } else {
            Add-HIACheck "CURRENT_STATE_SCHEMA" "FAIL" ("schema=" + [string]$json.schema)
        }

        if ($json.project_id -eq $ProjectId) {
            Add-HIACheck "CURRENT_STATE_PROJECT" "PASS" "project_id matches"
        } else {
            Add-HIACheck "CURRENT_STATE_PROJECT" "FAIL" ("project_id=" + [string]$json.project_id)
        }

        foreach ($field in @("id","raw","text")) {
            $value = [string]$next.$field
            if ($value -match [regex]::Escape($ExpectedNextActionId)) {
                Add-HIACheck ("CURRENT_STATE_NEXT_ACTION_" + $field.ToUpperInvariant()) "PASS" ($field + "=" + $value)
            } else {
                Add-HIACheck ("CURRENT_STATE_NEXT_ACTION_" + $field.ToUpperInvariant()) "FAIL" ($field + "=" + $value)
            }
        }

        if ([string]$json.evidence.state -eq "FRESH") {
            Add-HIACheck "CURRENT_STATE_EVIDENCE_FRESH" "PASS" "evidence.state=FRESH"
        } else {
            Add-HIACheck "CURRENT_STATE_EVIDENCE_FRESH" "FAIL" ("evidence.state=" + [string]$json.evidence.state)
        }
    }
    catch {
        Add-HIACheck "CURRENT_STATE_PARSE" "FAIL" $_.Exception.Message
    }
}

function Test-HIACliStrict {
    $commands = @(
        @{ id="CLI_CONTINUE"; cmd=".\01_UI\terminal\hia.ps1 project continue $ProjectId"; fields=@("NEXT_ACTION:", "RESUME_RECOMMENDATION:", "NEXT_ACTION_SOURCE: CURRENT_STATE") },
        @{ id="CLI_STATUS"; cmd=".\01_UI\terminal\hia.ps1 project status $ProjectId"; fields=@("NEXT_ACTION:", "NEXT_STEP_SNAPSHOT:", "NEXT_ACTION_SOURCE: CURRENT_STATE") },
        @{ id="CLI_REVIEW"; cmd=".\01_UI\terminal\hia.ps1 project review $ProjectId"; fields=@("CURRENT_STATE_STATUS:", "NEXT_ACTION") }
    )

    foreach ($c in $commands) {
        $out = Invoke-HIACommandText ("Set-Location '" + $RepoRoot + "'; " + $c.cmd)
        $ok = $true
        foreach ($f in $c.fields) {
            if ($out -notmatch [regex]::Escape($f)) { $ok = $false }
        }
        if ($out -notmatch [regex]::Escape($ExpectedNextActionId)) { $ok = $false }

        if ($ok) {
            Add-HIACheck $c.id "PASS" ($c.cmd + " proves " + $ExpectedNextActionId)
        } else {
            Add-HIACheck $c.id "FAIL" ($c.cmd + " does not prove " + $ExpectedNextActionId)
        }
    }
}

function Test-HIAStateJsStrict {
    $rel = "01_UI/web/control-tower-shell/assets/hia.state.js"
    Test-HIAFileExists "STATE_JS_EXISTS" $rel
    $txt = Get-HIAFileRaw $rel

    if ($txt -match "CURRENT_STATE_PRIMARY") {
        Add-HIACheck "STATE_JS_CURRENT_STATE_PRIMARY" "PASS" "resolver_status CURRENT_STATE_PRIMARY present"
    } else {
        Add-HIACheck "STATE_JS_CURRENT_STATE_PRIMARY" "FAIL" "CURRENT_STATE_PRIMARY missing"
    }

    if ($txt -match "current_state_status:\s*`"VALID`"") {
        Add-HIACheck "STATE_JS_VALID" "PASS" "current_state_status VALID"
    } else {
        Add-HIACheck "STATE_JS_VALID" "FAIL" "current_state_status VALID missing"
    }

    if ($txt -match ("next_action:\s*`"" + [regex]::Escape($ExpectedNextActionId))) {
        Add-HIACheck "STATE_JS_NEXT_ACTION" "PASS" "next_action starts with expected id"
    } else {
        Add-HIACheck "STATE_JS_NEXT_ACTION" "FAIL" "next_action does not start with expected id"
    }

    if ($txt -match "SEMANTIC_HASH") {
        Add-HIACheck "STATE_JS_SEMANTIC_HASH" "PASS" "SEMANTIC_HASH present"
    } else {
        Add-HIACheck "STATE_JS_SEMANTIC_HASH" "FAIL" "SEMANTIC_HASH missing"
    }
}

function Test-HIAGovernanceAndRadar {
    foreach ($rel in @(
        "04_PROJECTS/$ProjectId/GOVERNANCE/CURRENT_STATE.CONTRACT.md",
        "04_PROJECTS/$ProjectId/GOVERNANCE/EVIDENCE.VERSIONING.POLICY.md",
        "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt",
        "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt",
        "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt"
    )) {
        Test-HIAFileExists ("FILE_" + ($rel -replace '[^A-Za-z0-9]', '_')) $rel
    }
}

function Test-HIAControlTowerGeneratorStrict {
    $generator = Join-Path $RepoRoot "02_TOOLS\HIA_CONTROL_TOWER_STATE_GENERATOR.ps1"
    if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) {
        Add-HIACheck "CONTROL_TOWER_GENERATOR_EXISTS" "FAIL" "generator missing"
        return
    }

    $out = Invoke-HIACommandText ("& '" + $generator + "' -ProjectId '" + $ProjectId + "' -RepoRoot '" + $RepoRoot + "'")
    if (($out -match "WRITE_MODE:\s*CHECK") -and ($out -match "CURRENT_STATE_STATUS:\s*VALID") -and ($out -match [regex]::Escape($ExpectedNextActionId))) {
        Add-HIACheck "CONTROL_TOWER_GENERATOR_CHECK" "PASS" "generator CHECK proves expected state"
    } else {
        Add-HIACheck "CONTROL_TOWER_GENERATOR_CHECK" "FAIL" "generator CHECK does not prove expected state"
    }
}

Write-Host "========== HIA RELEASE READINESS VALIDATOR / START =========="
Write-Host ("PROJECT_ID.......: {0}" -f $ProjectId)
Write-Host ("EXPECTED_NEXT....: {0}" -f $ExpectedNextActionId)
Write-Host ("REPO_ROOT........: {0}" -f $RepoRoot)
Write-Host "======================================================================"

Test-HIAGitClean
Test-HIACurrentStateStrict
Test-HIACliStrict
Test-HIAStateJsStrict
Test-HIAGovernanceAndRadar
Test-HIAControlTowerGeneratorStrict

$failCount = @($checks | Where-Object { $_.status -ne "PASS" }).Count
foreach ($check in $checks) {
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
