<#
===============================================================================
MODULE: HIA_SESSION_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: SESSION LIFECYCLE

OBJETIVO
Gestionar sesiones activas con persistencia en archivos.

COMMANDS:
- start: inicia una sesion activa
- status: muestra estado de sesion
- log: agrega trazabilidad a sesion activa
- close: cierra sesion y sincroniza estado LIVE

VERSION: v1.1
DATE: 2026-03-24
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
        $resolved = (Resolve-Path $CandidateRoot).Path
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
$script:ActiveSessionFile = Join-Path $script:SessionsDir "SESSION.ACTIVE.json"
$script:SessionHistoryDir = Join-Path $script:SessionsDir "history"
$script:StateEnginePath = Join-Path $script:ProjectRoot "02_TOOLS\HIA_STATE_ENGINE.ps1"

foreach ($dir in @($script:SessionsDir, $script:SessionHistoryDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Get-HIAActiveSession {
    if (-not (Test-Path $script:ActiveSessionFile)) {
        return $null
    }

    try {
        return (Get-Content -Path $script:ActiveSessionFile -Raw | ConvertFrom-Json)
    }
    catch {
        Write-Host "ERROR: SESSION.ACTIVE.json is invalid." -ForegroundColor Red
        return $null
    }
}

function Save-HIAActiveSession {
    param([object]$Session)
    $Session | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ActiveSessionFile -Encoding UTF8
}

function Remove-HIAActiveSession {
    if (Test-Path $script:ActiveSessionFile) {
        Remove-Item -Path $script:ActiveSessionFile -Force
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

function Get-HIASessionStats {
    param([string]$Root)

    $stats = @{
        plans_created = 0
        logs_count = 0
    }

    $plansDir = Join-Path $Root "03_ARTIFACTS\plans"
    if (Test-Path $plansDir) {
        $recentPlans = Get-ChildItem -Path $plansDir -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '^PLAN_.*\.txt$|^.*\.json$' -and $_.LastWriteTimeUtc -gt (Get-Date).ToUniversalTime().AddHours(-24)
        }
        $stats.plans_created = @($recentPlans).Count
    }

    return $stats
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
    param([string]$Root)

    if (-not (Test-Path $script:StateEnginePath)) {
        Write-Host "WARNING: HIA_STATE_ENGINE.ps1 not found, state sync skipped." -ForegroundColor Yellow
        return $false
    }

    & $script:StateEnginePath -Command sync -ProjectRoot $Root

    $exitVar = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    if ($null -eq $exitVar) {
        return $true
    }

    return ([int]$exitVar.Value -eq 0)
}

function Invoke-HIAGitCheckpoint {
    param(
        [string]$Root,
        [string]$Message
    )

    Push-Location $Root
    try {
        $hasChanges = @(git status --porcelain 2>$null).Count -gt 0
        if (-not $hasChanges) {
            Write-Host "  No changes to commit." -ForegroundColor DarkGray
            return $true
        }

        git add -A | Out-Null
        git commit -m $Message | Out-Null
        Write-Host "  Git checkpoint created." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  Git checkpoint failed: $($_.Exception.Message)" -ForegroundColor Yellow
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
        Write-Host "  ID: $($existing.id)"
        Write-Host "  Operator: $($existing.operator)"
        Write-Host "  Started: $($existing.started_at)"
        Write-Host ""
        Write-Host "Use 'hia session close' first." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    $now = Get-Date
    $session = [ordered]@{
        id = "SESSION_" + $now.ToString("yyyyMMdd_HHmmss")
        operator = $OperatorName
        status = "active"
        started_at = $now.ToString("yyyy-MM-dd HH:mm:ss")
        started_utc = $now.ToUniversalTime().ToString("o")
        timezone = "America/Santiago"
        project_root = $script:ProjectRoot
        logs = @()
    }

    Save-HIAActiveSession -Session $session

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " SESSION STARTED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ID:        $($session.id)"
    Write-Host "  Operator:  $($session.operator)"
    Write-Host "  Started:   $($session.started_at)"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  hia session status"
    Write-Host "  hia session log -Message `"note`""
    Write-Host "  hia session close"
    Write-Host ""

    return $true
}

function Show-HIASessionStatus {
    $session = Get-HIAActiveSession

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " SESSION STATUS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not $session) {
        Write-Host "  No active session." -ForegroundColor DarkGray
        Write-Host "  Use 'hia session start' to begin." -ForegroundColor Yellow
        Write-Host ""
        return $true
    }

    $duration = (Get-Date) - [DateTime]::Parse($session.started_at)
    $logCount = @($session.logs).Count

    Write-Host "  Status:    ACTIVE" -ForegroundColor Green
    Write-Host "  ID:        $($session.id)"
    Write-Host "  Operator:  $($session.operator)"
    Write-Host "  Started:   $($session.started_at)"
    Write-Host "  Duration:  $(Format-HIADuration -Duration $duration)"
    Write-Host "  Logs:      $logCount"
    Write-Host ""

    if ($logCount -gt 0) {
        Write-Host "Recent logs:" -ForegroundColor Yellow
        foreach ($log in (@($session.logs) | Select-Object -Last 5)) {
            Write-Host "  [$($log.time)] $($log.message)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    return $true
}

function Add-HIASessionLog {
    param([string]$LogMessage)

    if (-not $LogMessage) {
        Write-Host ""
        Write-Host "ERROR: -Message required." -ForegroundColor Red
        Write-Host ""
        return $false
    }

    $session = Get-HIAActiveSession
    if (-not $session) {
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

    Write-Host ""
    Write-Host "LOG ADDED: $LogMessage" -ForegroundColor Green
    Write-Host ""
    return $true
}

function Close-HIASession {
    param(
        [string]$SummaryMessage,
        [bool]$DoGitCheckpoint
    )

    $session = Get-HIAActiveSession
    if (-not $session) {
        Write-Host ""
        Write-Host "ERROR: No active session." -ForegroundColor Red
        Write-Host "Use 'hia session start' first." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    $now = Get-Date
    $duration = $now - [DateTime]::Parse($session.started_at)
    $summary = if ($SummaryMessage) { $SummaryMessage } else { "Session completed" }
    $stats = Get-HIASessionStats -Root $script:ProjectRoot
    $stats.logs_count = @($session.logs).Count

    Set-HIASessionValue -Session $session -Key "status" -Value "closed"
    Set-HIASessionValue -Session $session -Key "closed_at" -Value $now.ToString("yyyy-MM-dd HH:mm:ss")
    Set-HIASessionValue -Session $session -Key "closed_utc" -Value $now.ToUniversalTime().ToString("o")
    Set-HIASessionValue -Session $session -Key "duration_seconds" -Value ([math]::Floor($duration.TotalSeconds))
    Set-HIASessionValue -Session $session -Key "duration_formatted" -Value (Format-HIADuration -Duration $duration)
    Set-HIASessionValue -Session $session -Key "summary" -Value $summary
    Set-HIASessionValue -Session $session -Key "stats" -Value $stats

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " CLOSING SESSION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ID:        $($session.id)"
    Write-Host "  Operator:  $($session.operator)"
    Write-Host "  Duration:  $($session.duration_formatted)"
    Write-Host "  Logs:      $($stats.logs_count)"
    Write-Host "  Plans:     $($stats.plans_created) created (24h)"
    Write-Host ""

    Write-Host "Syncing state..." -ForegroundColor Cyan
    $stateSynced = Invoke-HIAStateSync -Root $script:ProjectRoot
    if ($stateSynced) {
        Write-Host "  State synced." -ForegroundColor Green
    }
    else {
        Write-Host "  State sync failed." -ForegroundColor Yellow
    }

    if ($DoGitCheckpoint) {
        Write-Host ""
        Write-Host "Creating Git checkpoint..." -ForegroundColor Cyan
        $commitMsg = "SESSION: $($session.id) - $summary"
        $null = Invoke-HIAGitCheckpoint -Root $script:ProjectRoot -Message $commitMsg
    }

    $archivePath = Join-Path $script:SessionHistoryDir "$($session.id).json"
    $session | ConvertTo-Json -Depth 10 | Set-Content -Path $archivePath -Encoding UTF8
    Remove-HIAActiveSession

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " SESSION CLOSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Summary:  $summary"
    Write-Host "  Archive:  $archivePath"
    Write-Host ""

    return $stateSynced
}

$commandResult = $true
$useGitCheckpoint = $GitCheckpoint -and (-not $NoGitCheckpoint)

switch ($Command) {
    "start" {
        $commandResult = Start-HIASession -OperatorName $Operator
    }
    "status" {
        $commandResult = Show-HIASessionStatus
    }
    "log" {
        $commandResult = Add-HIASessionLog -LogMessage $Message
    }
    "close" {
        $commandResult = Close-HIASession -SummaryMessage $Message -DoGitCheckpoint $useGitCheckpoint
    }
    default {
        $commandResult = Show-HIASessionStatus
    }
}

if ($commandResult) { exit 0 }
exit 1
