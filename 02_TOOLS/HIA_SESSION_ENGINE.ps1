<#
===============================================================================
MODULE: HIA_SESSION_ENGINE.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: SESSION LIFECYCLE

OBJETIVO
Gestionar el ciclo de vida de sesiones de trabajo en HIA.

COMMANDS:
- start: Inicia nueva sesion
- close: Cierra sesion activa con resumen
- status: Muestra estado de sesion actual
- log: Registra nota en sesion activa

VERSION: v1.0
DATE: 2026-03-16
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
    [switch]$NoGitCheckpoint,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# RESOLVE PROJECT ROOT
# -----------------------------------------------------------------------------

if (-not $ProjectRoot) {
    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path (Join-Path $current "02_TOOLS")) {
            $ProjectRoot = $current
            break
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }
        $current = $parent
    }
}

# -----------------------------------------------------------------------------
# PATHS
# -----------------------------------------------------------------------------

$sessionsDir = Join-Path $ProjectRoot "03_ARTIFACTS\sessions"
$activeSessionFile = Join-Path $sessionsDir "SESSION.ACTIVE.json"
$sessionHistoryDir = Join-Path $sessionsDir "history"
$logsDir = Join-Path $ProjectRoot "03_ARTIFACTS\logs"

foreach ($dir in @($sessionsDir, $sessionHistoryDir, $logsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

function Get-ActiveSession {
    if (Test-Path $activeSessionFile) {
        return Get-Content $activeSessionFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-ActiveSession {
    param([object]$Session)
    $Session | ConvertTo-Json -Depth 10 | Set-Content -Path $activeSessionFile -Encoding UTF8
}

function Remove-ActiveSession {
    if (Test-Path $activeSessionFile) {
        Remove-Item $activeSessionFile -Force
    }
}

function Get-SessionStats {
    param([string]$Root)

    $stats = @{
        commands_executed = 0
        plans_created = 0
        files_modified = 0
    }

    $plansDir = Join-Path $Root "03_ARTIFACTS\plans"
    if (Test-Path $plansDir) {
        $recentPlans = Get-ChildItem -Path $plansDir -Filter "*.json" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }
        $stats.plans_created = $recentPlans.Count
    }

    return $stats
}

function Set-SessionValue {
    param(
        [object]$Session,
        [string]$Key,
        [object]$Value
    )

    if ($null -eq ($Session.PSObject.Properties[$Key])) {
        Add-Member -InputObject $Session -NotePropertyName $Key -NotePropertyValue $Value -Force
        return
    }

    $Session.$Key = $Value
}

function Format-Duration {
    param([TimeSpan]$Duration)

    if ($Duration.TotalHours -ge 1) {
        return "{0}h {1}m" -f [math]::Floor($Duration.TotalHours), $Duration.Minutes
    }
    elseif ($Duration.TotalMinutes -ge 1) {
        return "{0}m {1}s" -f [math]::Floor($Duration.TotalMinutes), $Duration.Seconds
    }
    else {
        return "{0}s" -f $Duration.Seconds
    }
}

function Invoke-GitCheckpoint {
    param(
        [string]$Root,
        [string]$Message
    )

    Push-Location $Root
    try {
        $status = git status --porcelain 2>&1
        if ($status) {
            git add -A 2>&1 | Out-Null
            git commit -m $Message 2>&1 | Out-Null
            Write-Host "  Git checkpoint created" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "  No changes to commit" -ForegroundColor DarkGray
            return $false
        }
    }
    catch {
        Write-Host "  Git checkpoint failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
    finally {
        Pop-Location
    }
}

function Invoke-StateSync {
    param([string]$Root)

    $stateEngine = Join-Path $Root "02_TOOLS\HIA_STATE_ENGINE.ps1"
    if (Test-Path $stateEngine) {
        & $stateEngine -Command sync -ProjectRoot $Root 2>&1 | Out-Null
    }
}

# -----------------------------------------------------------------------------
# COMMANDS
# -----------------------------------------------------------------------------

function Start-HIASession {
    param([string]$Operator)

    $existing = Get-ActiveSession
    if ($existing) {
        Write-Host ""
        Write-Host "ERROR: Session already active" -ForegroundColor Red
        Write-Host "  Started: $($existing.started_at)"
        Write-Host "  Operator: $($existing.operator)"
        Write-Host ""
        Write-Host "Use 'hia session close' to end current session first." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $sessionId = "SESSION_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    $now = Get-Date

    $session = @{
        id = $sessionId
        operator = $Operator
        started_at = $now.ToString("yyyy-MM-dd HH:mm:ss")
        started_utc = $now.ToUniversalTime().ToString("o")
        status = "active"
        logs = @()
        timezone = "America/Santiago"
        project_root = $ProjectRoot
    }

    Save-ActiveSession -Session $session

    Write-Host ""
    Write-Host "Running system check..." -ForegroundColor Cyan
    $smokeScript = Join-Path $ProjectRoot "02_TOOLS\Invoke-HIASmoke.ps1"
    if (Test-Path $smokeScript) {
        $null = & $smokeScript -ProjectRoot $ProjectRoot 2>&1
        $smokePass = $LASTEXITCODE -eq 0
    }
    else {
        $smokePass = $true
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " SESSION STARTED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ID:        $sessionId"
    Write-Host "  Operator:  $Operator"
    Write-Host "  Started:   $($session.started_at)"
    Write-Host "  System:    $(if ($smokePass) { 'OK' } else { 'WARNINGS' })"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Yellow
    Write-Host "  hia session log -Message `"note`"  - Add session note"
    Write-Host "  hia session status                - Check session"
    Write-Host "  hia session close                 - End session"
    Write-Host ""
}

function Close-HIASession {
    param(
        [string]$Message,
        [bool]$DoGitCheckpoint
    )

    $session = Get-ActiveSession
    if (-not $session) {
        Write-Host ""
        Write-Host "ERROR: No active session" -ForegroundColor Red
        Write-Host "Use 'hia session start' to begin a session." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $now = Get-Date
    $startTime = [DateTime]::Parse($session.started_at)
    $duration = $now - $startTime

    $stats = Get-SessionStats -Root $ProjectRoot

    Set-SessionValue -Session $session -Key "status" -Value "closed"
    Set-SessionValue -Session $session -Key "closed_at" -Value $now.ToString("yyyy-MM-dd HH:mm:ss")
    Set-SessionValue -Session $session -Key "closed_utc" -Value $now.ToUniversalTime().ToString("o")
    Set-SessionValue -Session $session -Key "duration_seconds" -Value ([math]::Floor($duration.TotalSeconds))
    Set-SessionValue -Session $session -Key "duration_formatted" -Value (Format-Duration -Duration $duration)
    $summaryText = if ($Message) { $Message } else { "Session completed" }
    Set-SessionValue -Session $session -Key "summary" -Value $summaryText
    Set-SessionValue -Session $session -Key "stats" -Value $stats

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " CLOSING SESSION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ID:        $($session.id)"
    Write-Host "  Operator:  $($session.operator)"
    Write-Host "  Duration:  $($session.duration_formatted)"
    Write-Host "  Plans:     $($stats.plans_created) created"
    Write-Host ""

    Write-Host "Syncing state..." -ForegroundColor Cyan
    Invoke-StateSync -Root $ProjectRoot
    Write-Host "  State synced" -ForegroundColor Green

    if ($DoGitCheckpoint) {
        Write-Host ""
        Write-Host "Creating Git checkpoint..." -ForegroundColor Cyan
        $commitMsg = "SESSION: $($session.id) - $($session.summary)"
        Invoke-GitCheckpoint -Root $ProjectRoot -Message $commitMsg
    }

    $archivePath = Join-Path $sessionHistoryDir "$($session.id).json"
    $session | ConvertTo-Json -Depth 10 | Set-Content -Path $archivePath -Encoding UTF8

    Remove-ActiveSession

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " SESSION CLOSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Duration: $($session.duration_formatted)"
    Write-Host "  Summary:  $($session.summary)"
    Write-Host "  Archive:  $archivePath"
    Write-Host ""
}

function Show-SessionStatus {
    $session = Get-ActiveSession

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " SESSION STATUS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (-not $session) {
        Write-Host "  No active session" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Use 'hia session start' to begin." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $now = Get-Date
    $startTime = [DateTime]::Parse($session.started_at)
    $duration = $now - $startTime

    Write-Host "  Status:    ACTIVE" -ForegroundColor Green
    Write-Host "  ID:        $($session.id)"
    Write-Host "  Operator:  $($session.operator)"
    Write-Host "  Started:   $($session.started_at)"
    Write-Host "  Duration:  $(Format-Duration -Duration $duration)"
    Write-Host "  Logs:      $($session.logs.Count) entries"
    Write-Host ""

    if ($session.logs.Count -gt 0) {
        Write-Host "Recent logs:" -ForegroundColor Yellow
        $recentLogs = $session.logs | Select-Object -Last 5
        foreach ($log in $recentLogs) {
            Write-Host "  [$($log.time)] $($log.message)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

function Add-SessionLog {
    param([string]$Message)

    if (-not $Message) {
        Write-Host ""
        Write-Host "ERROR: -Message required" -ForegroundColor Red
        Write-Host ""
        return
    }

    $session = Get-ActiveSession
    if (-not $session) {
        Write-Host ""
        Write-Host "ERROR: No active session" -ForegroundColor Red
        Write-Host "Use 'hia session start' to begin a session." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $logEntry = @{
        time = (Get-Date).ToString("HH:mm:ss")
        message = $Message
    }

    if (-not $session.logs) {
        $session | Add-Member -NotePropertyName "logs" -NotePropertyValue @() -Force
    }

    $logs = @($session.logs)
    $logs += $logEntry
    $session.logs = $logs

    Save-ActiveSession -Session $session

    Write-Host ""
    Write-Host "LOG ADDED: $Message" -ForegroundColor Green
    Write-Host ""
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host " HIA SESSION ENGINE" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

switch ($Command) {
    "start" {
        Start-HIASession -Operator $Operator
    }
    "close" {
        Close-HIASession -Message $Message -DoGitCheckpoint (-not $NoGitCheckpoint)
    }
    "status" {
        Show-SessionStatus
    }
    "log" {
        Add-SessionLog -Message $Message
    }
    default {
        Show-SessionStatus
    }
}
