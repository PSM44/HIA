param(
    [string]$ProjectId = "PRJ_0001_HIA.PRODUCT",
    [string]$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "HIA_STATE_HELPERS.ps1")

function Get-RepoHead {
    param([string]$RepoRoot)

    $head = (& git -C $RepoRoot rev-parse --short HEAD 2>$null)
    $msg = (& git -C $RepoRoot log -1 --pretty=%s 2>$null)
    $branch = (& git -C $RepoRoot branch --show-current 2>$null)

    return [ordered]@{
        branch = [string]$branch
        head_short = [string]$head
        head_message = [string]$msg
    }
}

function Convert-HIAUtcValueToString {
    param(
        $Value,
        [string]$Default = "N/A"
    )

    if ($null -eq $Value) { return $Default }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $Default }
    return $text.Trim()
}

function Parse-NextAction {
    param([string]$Value)

    $raw = Normalize-HIANextActionLine -Line $Value
    $id = "N/A"
    $title = "N/A"
    $status = "UNKNOWN"

    if ($raw -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*\|\s*(?<title>.+?)\s*\|\s*(?<status>ready|READY)$') {
        $id = $Matches["id"]
        $title = $Matches["title"].Trim().TrimEnd(".")
        $status = $Matches["status"].ToUpperInvariant()
    }
    elseif ($raw -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*\|\s*(?<title>.+)$') {
        $id = $Matches["id"]
        $title = $Matches["title"].Trim().TrimEnd(".")
    }

    return [ordered]@{
        id = $id
        title = $title
        status = $status
        raw = $raw
        source = "CURRENT_STATE"
    }
}

$projectRoot = Join-Path $Root "04_PROJECTS\$ProjectId"
$stateDir = Join-Path $projectRoot "STATE"
$currentStatePath = Join-Path $stateDir "CURRENT_STATE.json"
$batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
$backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"
$sessionPath = Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json"

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

$currentObjective = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
    "04.00_OBJETIVO_ACTUAL",
    "04.00_CURRENT_OBJECTIVE"
)

$nextActionRaw = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
    "06.00_NEXT_ACTION",
    "06.00_PROXIMA_ACCION",
    "06.00_SIGUIENTE_ACCION",
    "05.00_NEXT_ACTION",
    "05.00_PROXIMA_ACCION",
    "05.00_SIGUIENTE_ACCION",
    "05.00_SIGUIENTE_MINIBATTLE",
    "05.00_NEXT_MINIBATTLE"
)

$fallbackRaw = "N/A"
if ($nextActionRaw -eq "N/A") {
    $fallbackRaw = Get-HIANextReadyBacklogItem -BacklogPath $backlogPath
    if ($fallbackRaw -ne "N/A") {
        $nextActionRaw = $fallbackRaw
    }
}

$nextAction = Parse-NextAction -Value $nextActionRaw

$sessionStatus = "N/A"
$sessionId = "N/A"
if (Test-Path -LiteralPath $sessionPath) {
    try {
        $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace([string]$session.status)) {
            $sessionStatus = [string]$session.status
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
            $sessionId = [string]$session.session_id
        }
    }
    catch { }
}

$evidenceState = "N/A"
$evidenceConsistency = "N/A"
$evidenceCapturedUtc = "N/A"
try {
    $enginePath = Join-Path $Root "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
    . $enginePath
    $evidence = Get-HIAProjectEvidenceContinuity -ProjectRootPath $projectRoot
    if ($null -ne $evidence) {
        $evidenceState = [string]$evidence.STATE
        $evidenceConsistency = [string]$evidence.CONSISTENCY
        $evidenceCapturedUtc = Convert-HIAUtcValueToString -Value $evidence.CAPTURED_UTC -Default "N/A"
    }
}
catch { }

$payload = [ordered]@{
    schema = "HIA_CURRENT_STATE.v1"
    project_id = $ProjectId
    generated_local = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz")
    generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    generator = "02_TOOLS/HIA_CURRENT_STATE_GENERATOR.ps1"
    current_objective = $currentObjective
    next_action = $nextAction
    evidence = [ordered]@{
        state = $evidenceState
        consistency = $evidenceConsistency
        captured_utc = $evidenceCapturedUtc
    }
    session = [ordered]@{
        status = $sessionStatus
        last_session_id = $sessionId
    }
    git = Get-RepoHead -RepoRoot $Root
    policy = [ordered]@{
        precedence = "CURRENT_STATE first; fallback to BATON/BACKLOG only if missing or invalid"
        fallback_allowed = $true
    }
}

$json = $payload | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $currentStatePath -Value $json -Encoding UTF8

Write-Host ("CURRENT_STATE_PATH: {0}" -f $currentStatePath)
Write-Host ("NEXT_ACTION_ID: {0}" -f $nextAction.id)
Write-Host ("NEXT_ACTION_RAW: {0}" -f $nextAction.raw)
if ($fallbackRaw -ne "N/A") {
    Write-Host ("FALLBACK_USED: {0}" -f $fallbackRaw)
}
