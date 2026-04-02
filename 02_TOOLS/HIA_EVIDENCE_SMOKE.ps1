<#
===============================================================================
MODULE: HIA_EVIDENCE_SMOKE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: Evidence fixtures + smoke helper (MB-2.20)

OBJETIVO
Sembrar y resetear fixtures deterministas para validar:
- hia project review <PROJECT_ID>
- hia project continue <PROJECT_ID>

Sin dependencias nuevas. Sin tocar HUMAN governance.

PROJECT IDS (deterministas):
- PRJ_EVID_FRESH_OK      (fresh + consistent)
- PRJ_EVID_FRESH_BAD     (fresh + inconsistent)
- PRJ_EVID_STALE         (stale)
- PRJ_EVID_MISSING       (missing evidence)
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("seed","smoke","clean")]
    [string]$Mode = "seed"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectEnginePath = Join-Path $PSScriptRoot "HIA_PROJECT_ENGINE.ps1"
if (-not (Test-Path -LiteralPath $projectEnginePath)) {
    throw "HIA_PROJECT_ENGINE.ps1 not found."
}
. $projectEnginePath

function Ensure-HIAProject {
    param([string]$ProjectId)
    try { $null = Resolve-HIAProjectRoot -ProjectId $ProjectId; return }
    catch {
        New-HIAProject -ProjectId $ProjectId
    }
}

function Set-FileUtc {
    param([string]$Path,[datetime]$Utc)
    (Get-Item -LiteralPath $Path).LastWriteTimeUtc = $Utc
}

function Seed-FreshConsistent {
    $projId = "PRJ_EVID_FRESH_OK"
    Ensure-HIAProject $projId
    $root = Resolve-HIAProjectRoot -ProjectId $projId
    $art = Join-Path $root "ARTIFACTS"
    $tasks = Join-Path $art "TASKS"
    $logs = Join-Path $art "LOGS"
    New-Item -ItemType Directory -Force -Path $tasks | Out-Null
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $now = (Get-Date).ToUniversalTime()
    $outPath = Join-Path $tasks "FIXTURE_FRESH_OK.txt"
    $logPath = Join-Path $logs "FIXTURE_FRESH_OK.log"
    "# fixture fresh consistent" | Set-Content -LiteralPath $outPath -Encoding UTF8
    ("{0:o} | TASK=fixture-fresh-ok | RESULT=created" -f $now) | Set-Content -LiteralPath $logPath -Encoding UTF8
    Set-FileUtc -Path $outPath -Utc $now
    Set-FileUtc -Path $logPath -Utc $now
    $snapshot = [ordered]@{
        project_id = $projId
        source_task = "fixture-fresh-ok"
        output_path = $outPath
        log_path = $logPath
        status = "created"
        captured_utc = $now.ToString("o")
        session_id = "fixture-session-fresh"
    }
    ($snapshot | ConvertTo-Json -Depth 4) | Set-Content -LiteralPath (Join-Path $art "LAST.ACTION.json") -Encoding UTF8
}

function Seed-FreshInconsistent {
    $projId = "PRJ_EVID_FRESH_BAD"
    Ensure-HIAProject $projId
    $root = Resolve-HIAProjectRoot -ProjectId $projId
    $art = Join-Path $root "ARTIFACTS"
    $tasks = Join-Path $art "TASKS"
    $logs = Join-Path $art "LOGS"
    New-Item -ItemType Directory -Force -Path $tasks | Out-Null
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $now = (Get-Date).ToUniversalTime()
    $outPath = Join-Path $tasks "FIXTURE_FRESH_BAD.txt"
    $logPath = Join-Path $logs "FIXTURE_FRESH_BAD.log"
    "# fixture fresh inconsistent" | Set-Content -LiteralPath $outPath -Encoding UTF8
    ("{0:o} | TASK=fixture-other-task | RESULT=created" -f $now) | Set-Content -LiteralPath $logPath -Encoding UTF8
    Set-FileUtc -Path $outPath -Utc $now
    Set-FileUtc -Path $logPath -Utc ($now.AddHours(-10))
    $snapshot = [ordered]@{
        project_id = $projId
        source_task = "fixture-fresh-bad"
        output_path = $outPath
        log_path = $logPath
        status = "created"
        captured_utc = $now.ToString("o")
        session_id = "fixture-session-bad"
    }
    ($snapshot | ConvertTo-Json -Depth 4) | Set-Content -LiteralPath (Join-Path $art "LAST.ACTION.json") -Encoding UTF8
}

function Seed-Stale {
    $projId = "PRJ_EVID_STALE"
    Ensure-HIAProject $projId
    $root = Resolve-HIAProjectRoot -ProjectId $projId
    $art = Join-Path $root "ARTIFACTS"
    $tasks = Join-Path $art "TASKS"
    $logs = Join-Path $art "LOGS"
    New-Item -ItemType Directory -Force -Path $tasks | Out-Null
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    $old = (Get-Date "2026-03-20T00:00:00Z").ToUniversalTime()
    $outPath = Join-Path $tasks "FIXTURE_STALE.txt"
    $logPath = Join-Path $logs "FIXTURE_STALE.log"
    "# fixture stale" | Set-Content -LiteralPath $outPath -Encoding UTF8
    ("{0:o} | TASK=fixture-stale | RESULT=created" -f $old) | Set-Content -LiteralPath $logPath -Encoding UTF8
    Set-FileUtc -Path $outPath -Utc $old
    Set-FileUtc -Path $logPath -Utc $old
    $snapshot = [ordered]@{
        project_id = $projId
        source_task = "fixture-stale"
        output_path = $outPath
        log_path = $logPath
        status = "created"
        captured_utc = $old.ToString("o")
        session_id = "fixture-session-stale"
    }
    ($snapshot | ConvertTo-Json -Depth 4) | Set-Content -LiteralPath (Join-Path $art "LAST.ACTION.json") -Encoding UTF8
}

function Seed-Missing {
    $projId = "PRJ_EVID_MISSING"
    Ensure-HIAProject $projId
    $root = Resolve-HIAProjectRoot -ProjectId $projId
    $art = Join-Path $root "ARTIFACTS"
    $tasks = Join-Path $art "TASKS"
    $logs = Join-Path $art "LOGS"
    New-Item -ItemType Directory -Force -Path $tasks | Out-Null
    New-Item -ItemType Directory -Force -Path $logs | Out-Null
    Remove-Item -LiteralPath (Join-Path $art "LAST.ACTION.json") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $tasks "*") -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $logs "*") -Force -ErrorAction SilentlyContinue
}

function Clean-Fixtures {
    $fixtureIds = @(
        "PRJ_EVID_FRESH_OK",
        "PRJ_EVID_FRESH_BAD",
        "PRJ_EVID_STALE",
        "PRJ_EVID_MISSING"
    )
    foreach ($fixtureId in $fixtureIds) {
        try {
            $root = Resolve-HIAProjectRoot -ProjectId $fixtureId
        }
        catch {
            continue
        }
        $art = Join-Path $root "ARTIFACTS"
        $tasks = Join-Path $art "TASKS"
        $logs = Join-Path $art "LOGS"
        Remove-Item -LiteralPath (Join-Path $art "LAST.ACTION.json") -Force -ErrorAction SilentlyContinue
        if (Test-Path -LiteralPath $tasks) { Remove-Item -LiteralPath (Join-Path $tasks "*") -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $logs) { Remove-Item -LiteralPath (Join-Path $logs "*") -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "Fixtures cleaned (ARTIFACTS reset; projects retained)." -ForegroundColor Yellow
}

function Invoke-Seed {
    Write-Host "Seeding evidence fixtures..." -ForegroundColor Cyan
    Seed-FreshConsistent
    Seed-FreshInconsistent
    Seed-Stale
    Seed-Missing
    Write-Host "Fixtures ready." -ForegroundColor Green
}

function Invoke-Smoke {
    Invoke-Seed
    $hiaPath = ".\\01_UI\\terminal\\hia.ps1"
    $cases = @(
        @{label="review fresh consistent"; args=@("project","review","PRJ_EVID_FRESH_OK"); expectState="FRESH"; expectConsistency="CONSISTENT"},
        @{label="continue fresh consistent"; args=@("project","continue","PRJ_EVID_FRESH_OK"); expectState="FRESH"; expectConsistency="CONSISTENT"},
        @{label="review fresh inconsistent"; args=@("project","review","PRJ_EVID_FRESH_BAD"); expectState="FRESH"; expectConsistency="INCONSISTENT"},
        @{label="continue fresh inconsistent"; args=@("project","continue","PRJ_EVID_FRESH_BAD"); expectState="FRESH"; expectConsistency="INCONSISTENT"},
        @{label="review stale"; args=@("project","review","PRJ_EVID_STALE"); expectState="STALE"; expectConsistency="CONSISTENT"},
        @{label="review missing"; args=@("project","review","PRJ_EVID_MISSING"); expectState="MISSING"; expectConsistency="N/A"},
        @{label="continue unknown"; args=@("project","continue","UNKNOWN"); expectState="ERROR"; expectConsistency="ERROR"}
    )
    $fail = $false
    foreach ($c in $cases) {
        Write-Host ""
        Write-Host ("=== SMOKE {0} ===" -f $c.label) -ForegroundColor Yellow
        $output = & pwsh -NoProfile -File $hiaPath @($c.args) 2>&1
        $text = $output -join "`n"
        $state = "UNKNOWN"
        $consistency = "UNKNOWN"
        if ($text -match 'EVIDENCE_STATE:\s*([A-Z]+)') { $state = $Matches[1] }
        if ($text -match 'EVIDENCE_CONSISTENCY:\s*([A-Z/]+)') { $consistency = $Matches[1] }
        $errorPath = ($text -match 'Project not found')
        $pass = $false
        if ($c.expectState -eq "ERROR") {
            $pass = $errorPath
        }
        else {
            $pass = ($state -eq $c.expectState -and $consistency -eq $c.expectConsistency)
        }
        if ($pass) {
            Write-Host ("PASS [{0}] state={1} consistency={2}" -f $c.label, $state, $consistency) -ForegroundColor Green
        }
        else {
            Write-Host ("FAIL [{0}] got state={1} consistency={2} (expected {3}/{4})" -f $c.label, $state, $consistency, $c.expectState, $c.expectConsistency) -ForegroundColor Red
            $fail = $true
        }
    }
    if ($fail) { exit 1 }
    Write-Host ""
    Write-Host "SMOKE PASS" -ForegroundColor Green
    exit 0
}

if ($Mode -eq "seed") {
    Invoke-Seed
    exit 0
}

if ($Mode -eq "clean") {
    Clean-Fixtures
    exit 0
}

Invoke-Smoke
