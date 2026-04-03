<#
===============================================================================
MODULE: HIA_SESSION_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: SESSION LIFECYCLE

OBJETIVO
Gestionar sesiones activas con persistencia real en 03_ARTIFACTS\sessions.

COMMANDS:
- start: inicia sesion
- status: muestra sesion activa
- log: agrega trazabilidad
- close: cierra sesion, sincroniza estado y opcionalmente crea checkpoint git

VERSION: v1.2
DATE: 2026-03-29
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "close", "status", "log")]
    [string]$Command = "status",

    [Parameter(Mandatory = $false)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [string]$Operator = $env:USERNAME,

    [Parameter(Mandatory = $false)]
    [switch]$GitCheckpoint,

    [Parameter(Mandatory = $false)]
    [switch]$NoGitCheckpoint,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    param([string]$CandidateRoot)

    if ($CandidateRoot) {
        $resolved = (Resolve-Path -LiteralPath $CandidateRoot).Path
        if (Test-Path (Join-Path $resolved "02_TOOLS")) {
            return $resolved
        }
    }

    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path (Join-Path $current "02_TOOLS")) {
            return $current
        }

        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }

        $current = $parent
    }
}

$script:ProjectRoot = Get-HIAProjectRoot -CandidateRoot $ProjectRoot
$script:SessionsDir = Join-Path $script:ProjectRoot "03_ARTIFACTS\sessions"
$script:ActiveSessionPath = Join-Path $script:SessionsDir "ACTIVE_SESSION.json"
$script:LegacyActiveSessionPath = Join-Path $script:SessionsDir "SESSION.ACTIVE.json"
$script:StateEnginePath = Join-Path $script:ProjectRoot "02_TOOLS\HIA_STATE_ENGINE.ps1"

if (-not (Test-Path -LiteralPath $script:SessionsDir)) {
    New-Item -ItemType Directory -Path $script:SessionsDir -Force | Out-Null
}

function Convert-HIAUtcString {
    param([object]$Value)

    if ($null -eq $Value) { return "NONE" }
    if ($Value -is [datetime]) { return $Value.ToUniversalTime().ToString("o") }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return "NONE" }
    return $text
}

function Get-HIASessionId {
    $candidate = "SESSION_" + (Get-Date).ToString("yyyyMMdd_HHmmss")
    $summaryPath = Join-Path $script:SessionsDir "$candidate.json"
    if (-not (Test-Path -LiteralPath $summaryPath)) {
        return $candidate
    }

    return ("SESSION_{0}" -f [guid]::NewGuid().ToString("N"))
}

function Get-HIASessionArtifacts {
    param([string]$SessionId)

    return @{
        SummaryPath = Join-Path $script:SessionsDir ("{0}.json" -f $SessionId)
        LogPath = Join-Path $script:SessionsDir ("{0}.log.txt" -f $SessionId)
    }
}

function Write-HIASessionLogLine {
    param(
        [string]$SessionId,
        [string]$Message
    )

    $artifacts = Get-HIASessionArtifacts -SessionId $SessionId
    $line = "[{0}] {1}" -f ((Get-Date).ToUniversalTime().ToString("o")), $Message
    Add-Content -Path $artifacts.LogPath -Value $line -Encoding UTF8
}

function Save-HIAActiveSession {
    param([object]$Session)

    $Session | ConvertTo-Json -Depth 20 | Set-Content -Path $script:ActiveSessionPath -Encoding UTF8
}

function Remove-HIAActiveSession {
    if (Test-Path -LiteralPath $script:ActiveSessionPath) {
        Remove-Item -LiteralPath $script:ActiveSessionPath -Force
    }
    if (Test-Path -LiteralPath $script:LegacyActiveSessionPath) {
        Remove-Item -LiteralPath $script:LegacyActiveSessionPath -Force
    }
}

function Set-HIASessionValue {
    param(
        [object]$Session,
        [string]$Key,
        [object]$Value
    )

    if ($null -eq $Session.PSObject.Properties[$Key]) {
        Add-Member -InputObject $Session -NotePropertyName $Key -NotePropertyValue $Value -Force
        return
    }

    $Session.$Key = $Value
}

function Get-HIAActiveSession {
    $candidatePath = $null
    if (Test-Path -LiteralPath $script:ActiveSessionPath) {
        $candidatePath = $script:ActiveSessionPath
    }
    elseif (Test-Path -LiteralPath $script:LegacyActiveSessionPath) {
        $candidatePath = $script:LegacyActiveSessionPath
    }

    if (-not $candidatePath) {
        return $null
    }

    try {
        $session = Get-Content -Path $candidatePath -Raw | ConvertFrom-Json
        $sessionId = [string]$session.id
        if ([string]::IsNullOrWhiteSpace($sessionId)) {
            $sessionId = [string]$session.session_id
        }
        if ([string]::IsNullOrWhiteSpace($sessionId)) {
            $sessionId = Get-HIASessionId
            $session | Add-Member -NotePropertyName "id" -NotePropertyValue $sessionId -Force
        }
        $session | Add-Member -NotePropertyName "__path" -NotePropertyValue $candidatePath -Force
        return $session
    }
    catch {
        throw ("Invalid session file: {0}" -f $candidatePath)
    }
}

function Get-HIASessionStats {
    param([object]$Session)

    $plansCreated = 0
    $plansDir = Join-Path $script:ProjectRoot "03_ARTIFACTS\plans"
    if (Test-Path -LiteralPath $plansDir) {
        $plansCreated = @(Get-ChildItem -Path $plansDir -File -ErrorAction SilentlyContinue | Where-Object {
            $_.LastWriteTimeUtc -gt (Get-Date).ToUniversalTime().AddHours(-24)
        }).Count
    }

    return @{
        plans_created_24h = $plansCreated
        logs_count = @($Session.logs).Count
    }
}

function Format-HIADuration {
    param([TimeSpan]$Duration)

    if ($Duration.TotalHours -ge 1) {
        return "{0}h {1}m" -f [math]::Floor($Duration.TotalHours), $Duration.Minutes
    }
    if ($Duration.TotalMinutes -ge 1) {
        return "{0}m {1}s" -f [math]::Floor($Duration.TotalMinutes), $Duration.Seconds
    }
    return "{0}s" -f [math]::Floor($Duration.TotalSeconds)
}

function Invoke-HIAStateSync {
    if (-not (Test-Path -LiteralPath $script:StateEnginePath)) {
        Write-Host "WARNING: HIA_STATE_ENGINE.ps1 not found. State sync skipped." -ForegroundColor Yellow
        return $false
    }

    & $script:StateEnginePath -Command sync -ProjectRoot $script:ProjectRoot

    $exitVar = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    if ($null -eq $exitVar) {
        return $true
    }

    return ([int]$exitVar.Value -eq 0)
}

function Invoke-HIAGitCheckpoint {
    param([string]$CommitMessage)

    Push-Location $script:ProjectRoot
    try {
        $hasChanges = @(git status --porcelain 2>$null).Count -gt 0
        if (-not $hasChanges) {
            Write-Host "  No changes to commit." -ForegroundColor DarkGray
            return $true
        }

        git add -A | Out-Null
        git commit -m $CommitMessage | Out-Null
        Write-Host "  Git checkpoint created." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host ("  Git checkpoint failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        return $false
    }
    finally {
        Pop-Location
    }
}

function Start-HIASession {
    param([string]$OperatorName)

    $existing = Get-HIAActiveSession
    if ($existing) {
        Write-Host ""
        Write-Host "ERROR: Session already active." -ForegroundColor Red
        Write-Host ("  ID: {0}" -f $existing.id)
        Write-Host ("  Operator: {0}" -f $existing.operator)
        Write-Host ("  Started: {0}" -f $existing.started_at)
        Write-Host ""
        Write-Host "Use 'hia session close' first." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    $now = Get-Date
    $sessionId = Get-HIASessionId
    $session = [ordered]@{
        id = $sessionId
        session_id = $sessionId
        operator = $OperatorName
        status = "active"
        started_at = $now.ToString("yyyy-MM-dd HH:mm:ss")
        started_utc = $now.ToUniversalTime().ToString("o")
        closed_utc = $null
        project_root = $script:ProjectRoot
        logs = @()
    }

    Save-HIAActiveSession -Session $session
    Write-HIASessionLogLine -SessionId $sessionId -Message ("SESSION STARTED by {0}" -f $OperatorName)

    Write-Host ""
    Write-Host "PROJECT SESSION STARTED" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $sessionId)
    Write-Host ("OPERATOR: {0}" -f $OperatorName)
    Write-Host ("PATH: {0}" -f $script:ActiveSessionPath)
    Write-Host ""
    return $true
}

function Show-HIASessionStatus {
    $session = Get-HIAActiveSession

    Write-Host ""
    Write-Host "PROJECT SESSION STATUS" -ForegroundColor Cyan

    if (-not $session) {
        Write-Host "STATUS: NONE"
        Write-Host ("PATH: {0}" -f $script:ActiveSessionPath)
        Write-Host ""
        return $true
    }

    $status = [string]$session.status
    if ([string]::IsNullOrWhiteSpace($status)) {
        $status = "active"
    }

    Write-Host ("STATUS: {0}" -f $status)
    Write-Host ("SESSION_ID: {0}" -f $session.id)
    Write-Host ("STARTED_UTC: {0}" -f (Convert-HIAUtcString -Value $session.started_utc))
    Write-Host ("CLOSED_UTC: {0}" -f (Convert-HIAUtcString -Value $session.closed_utc))
    Write-Host ("PATH: {0}" -f $script:ActiveSessionPath)
    Write-Host ""
    return $true
}

function Add-HIASessionLog {
    param([string]$LogMessage)

    if ([string]::IsNullOrWhiteSpace($LogMessage)) {
        Write-Host ""
        Write-Host "ERROR: -Message required." -ForegroundColor Red
        Write-Host ""
        return $false
    }

    $session = Get-HIAActiveSession
    if (-not $session -or [string]$session.status -ne "active") {
        Write-Host ""
        Write-Host "ERROR: No active session." -ForegroundColor Red
        Write-Host "Use 'hia session start' first." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    $entry = [ordered]@{
        time = (Get-Date).ToString("HH:mm:ss")
        time_utc = (Get-Date).ToUniversalTime().ToString("o")
        message = $LogMessage
    }

    $logs = @($session.logs)
    $logs += $entry
    $session.logs = $logs

    Save-HIAActiveSession -Session $session
    Write-HIASessionLogLine -SessionId $session.id -Message ("LOG: {0}" -f $LogMessage)

    Write-Host ""
    Write-Host ("LOG ADDED: {0}" -f $LogMessage) -ForegroundColor Green
    Write-Host ""
    return $true
}

function Close-HIASession {
    param(
        [string]$SummaryMessage,
        [bool]$DoGitCheckpoint
    )

    $session = Get-HIAActiveSession
    if (-not $session -or [string]$session.status -ne "active") {
        Write-Host ""
        Write-Host "ERROR: No active session." -ForegroundColor Red
        Write-Host "Use 'hia session start' first." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    $now = Get-Date
    $startedRaw = Convert-HIAUtcString -Value $session.started_utc
    if ($startedRaw -eq "NONE") {
        $startedRaw = Convert-HIAUtcString -Value $session.started_at
    }
    if ($startedRaw -eq "NONE") {
        $startedRaw = $now.ToUniversalTime().ToString("o")
    }
    $startedAtUtc = [DateTime]::Parse($startedRaw)
    $duration = $now.ToUniversalTime() - $startedAtUtc.ToUniversalTime()
    $summary = if ([string]::IsNullOrWhiteSpace($SummaryMessage)) { "Session completed" } else { $SummaryMessage }

    Set-HIASessionValue -Session $session -Key "status" -Value "closed"
    Set-HIASessionValue -Session $session -Key "closed_at" -Value $now.ToString("yyyy-MM-dd HH:mm:ss")
    Set-HIASessionValue -Session $session -Key "closed_utc" -Value $now.ToUniversalTime().ToString("o")
    Set-HIASessionValue -Session $session -Key "duration_seconds" -Value ([math]::Floor($duration.TotalSeconds))
    Set-HIASessionValue -Session $session -Key "duration_formatted" -Value (Format-HIADuration -Duration $duration)
    Set-HIASessionValue -Session $session -Key "summary" -Value $summary
    Set-HIASessionValue -Session $session -Key "stats" -Value (Get-HIASessionStats -Session $session)

    $artifacts = Get-HIASessionArtifacts -SessionId $session.id
    $session | ConvertTo-Json -Depth 20 | Set-Content -Path $artifacts.SummaryPath -Encoding UTF8
    Write-HIASessionLogLine -SessionId $session.id -Message ("SESSION CLOSED: {0}" -f $summary)

    Write-Host ""
    Write-Host "CLOSING SESSION..." -ForegroundColor Cyan

    $stateSynced = Invoke-HIAStateSync
    if ($stateSynced) {
        Write-Host "  State synced." -ForegroundColor Green
    }
    else {
        Write-Host "  State sync failed." -ForegroundColor Yellow
    }

    if ($DoGitCheckpoint) {
        Write-Host "  Creating optional Git checkpoint..." -ForegroundColor Cyan
        $checkpointMessage = "SESSION: $($session.id) - $summary"
        $null = Invoke-HIAGitCheckpoint -CommitMessage $checkpointMessage
    }

    Remove-HIAActiveSession

    Write-Host ""
    Write-Host "PROJECT SESSION CLOSED" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $session.id)
    Write-Host ("DURATION: {0}" -f $session.duration_formatted)
    Write-Host ("SUMMARY_PATH: {0}" -f $artifacts.SummaryPath)
    Write-Host ("LOG_PATH: {0}" -f $artifacts.LogPath)
    Write-Host ""

    return $stateSynced
}

$commandResult = $true
$useGitCheckpoint = $GitCheckpoint -and (-not $NoGitCheckpoint)

switch ($Command) {
    "start" { $commandResult = Start-HIASession -OperatorName $Operator }
    "status" { $commandResult = Show-HIASessionStatus }
    "log" { $commandResult = Add-HIASessionLog -LogMessage $Message }
    "close" { $commandResult = Close-HIASession -SummaryMessage $Message -DoGitCheckpoint $useGitCheckpoint }
    default { $commandResult = Show-HIASessionStatus }
}

# Normalize exit code map: 0 success, 1 known failure
$global:HIA_EXIT_CODE = if ($commandResult) { 0 } else { 1 }
exit $global:HIA_EXIT_CODE
