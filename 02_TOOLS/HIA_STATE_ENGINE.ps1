<#
===============================================================================
MODULE: HIA_STATE_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: STATE MANAGEMENT

OBJETIVO
Gestionar el estado LIVE del proyecto HIA en forma regenerable.

COMMANDS:
- show: Muestra el estado LIVE actual (solo lectura)
- sync: Recalcula y regenera PROJECT.STATE.LIVE.txt
- update: Registra nota en historial y sincroniza LIVE
- history: Muestra historial de cambios de estado

VERSION: v1.1
DATE: 2026-03-23
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("show", "sync", "update", "history")]
    [string]$Command = "show",

    [Parameter(Mandatory = $false)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [ValidateSet("minibattle", "mvp", "milestone", "note")]
    [string]$Type = "note",

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

function Get-HIALiveStatePath {
    param([string]$Root)
    return (Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt")
}

function Read-HIAStateFile {
    param([string]$Path)

    $result = @{
        Exists = $false
        Raw = ""
        Lines = @()
        Stats = @{}
        MiniBattles = @()
        FocusActual = "Sistema de orquestacion multi-agente con CLI funcional."
        MvpActivo = "MVP-0 - Kernel CLI estable"
    }

    if (-not (Test-Path $Path)) {
        return $result
    }

    $raw = Get-Content -Path $Path -Raw
    $lines = Get-Content -Path $Path

    $result.Exists = $true
    $result.Raw = $raw
    $result.Lines = $lines

    foreach ($line in $lines) {
        if ($line -match '^(TOOLS_REGISTRADOS|AGENTS_REGISTRADOS|PLANS_TOTAL|PLANS_COMPLETADOS|PLANS_PENDIENTES|ULTIMO_RADAR|ULTIMA_ACTIVIDAD):\s*(.+)$') {
            $result.Stats[$matches[1]] = $matches[2].Trim()
        }
    }

    $miniPattern = '(?ms)MINIBATTLES_COMPLETADOS\s*-+\s*(.*?)\s*ESTADISTICAS'
    $miniMatch = [regex]::Match($raw, $miniPattern)
    if ($miniMatch.Success) {
        $miniLines = $miniMatch.Groups[1].Value -split "(`r`n|`n|`r)"
        foreach ($miniLine in $miniLines) {
            $trimmed = $miniLine.Trim()
            if ($trimmed -match '^\[MB-') {
                $result.MiniBattles += $trimmed
            }
        }
    }

    $focusPattern = '(?ms)FOCO_ACTUAL\s*-+\s*(.*?)\s*MVP_ACTIVO'
    $focusMatch = [regex]::Match($raw, $focusPattern)
    if ($focusMatch.Success) {
        $candidate = ($focusMatch.Groups[1].Value -replace '\s+$', '').Trim()
        if ($candidate) {
            $result.FocusActual = $candidate
        }
    }

    $mvpPattern = '(?ms)MVP_ACTIVO\s*-+\s*(.*?)\s*MINIBATTLES_COMPLETADOS'
    $mvpMatch = [regex]::Match($raw, $mvpPattern)
    if ($mvpMatch.Success) {
        $candidate = ($mvpMatch.Groups[1].Value -replace '\s+$', '').Trim()
        if ($candidate) {
            $result.MvpActivo = $candidate
        }
    }

    return $result
}

function Get-HIAToolCount {
    param(
        [string]$Root,
        [hashtable]$ExistingState
    )

    $toolRegistryPath = Join-Path $Root "02_TOOLS\TOOL.REGISTRY.json"
    if (Test-Path $toolRegistryPath) {
        try {
            $toolReg = Get-Content -Path $toolRegistryPath -Raw | ConvertFrom-Json
            return [string](($toolReg.tools.PSObject.Properties | Measure-Object).Count)
        }
        catch {
            # Fallback below
        }
    }

    if ($ExistingState.Stats.ContainsKey("TOOLS_REGISTRADOS")) {
        return $ExistingState.Stats["TOOLS_REGISTRADOS"]
    }

    return "UNKNOWN"
}

function Get-HIAAgentCount {
    param(
        [string]$Root,
        [hashtable]$ExistingState
    )

    $agentRegistryPath = Join-Path $Root "04_AGENTS\AGENT.REGISTRY.json"
    if (Test-Path $agentRegistryPath) {
        try {
            $agentReg = Get-Content -Path $agentRegistryPath -Raw | ConvertFrom-Json
            return [string](($agentReg.agents.PSObject.Properties | Measure-Object).Count)
        }
        catch {
            # Fallback below
        }
    }

    if ($ExistingState.Stats.ContainsKey("AGENTS_REGISTRADOS")) {
        return $ExistingState.Stats["AGENTS_REGISTRADOS"]
    }

    return "UNKNOWN"
}

function Get-HIAPlanStats {
    param(
        [string]$Root,
        [hashtable]$ExistingState
    )

    $plansDir = Join-Path $Root "03_ARTIFACTS\plans"
    $stats = @{
        Total = $null
        Completed = $null
        Pending = $null
    }

    if (Test-Path $plansDir) {
        $total = 0
        $completed = 0
        $pending = 0

        $txtPlans = Get-ChildItem -Path $plansDir -Filter "PLAN_*.txt" -ErrorAction SilentlyContinue
        foreach ($plan in $txtPlans) {
            $total++
            try {
                $lines = Get-Content -Path $plan.FullName
                $statusIndex = $lines.IndexOf("STATUS")
                if ($statusIndex -ge 0 -and ($statusIndex + 1) -lt $lines.Count) {
                    $status = $lines[$statusIndex + 1].Trim().ToLowerInvariant()
                    switch ($status) {
                        "completed" { $completed++ }
                        "executed" { $completed++ }
                        "done" { $completed++ }
                        "planned" { $pending++ }
                        "approved" { $pending++ }
                        "pending" { $pending++ }
                        "executing" { $pending++ }
                    }
                }
            }
            catch {
                # Ignore malformed file and continue counting
            }
        }

        $jsonPlans = Get-ChildItem -Path $plansDir -Filter "*.json" -ErrorAction SilentlyContinue
        foreach ($plan in $jsonPlans) {
            $total++
            try {
                $obj = Get-Content -Path $plan.FullName -Raw | ConvertFrom-Json
                $status = [string]$obj.status
                if ($status) {
                    switch ($status.ToLowerInvariant()) {
                        "completed" { $completed++ }
                        "executed" { $completed++ }
                        "done" { $completed++ }
                        "planned" { $pending++ }
                        "approved" { $pending++ }
                        "pending" { $pending++ }
                        "executing" { $pending++ }
                    }
                }
            }
            catch {
                # Ignore malformed file and continue counting
            }
        }

        $stats.Total = [string]$total
        $stats.Completed = [string]$completed
        $stats.Pending = [string]$pending
    }

    if (-not $stats.Total) {
        $stats.Total = if ($ExistingState.Stats.ContainsKey("PLANS_TOTAL")) { $ExistingState.Stats["PLANS_TOTAL"] } else { "UNKNOWN" }
    }

    if (-not $stats.Completed) {
        $stats.Completed = if ($ExistingState.Stats.ContainsKey("PLANS_COMPLETADOS")) { $ExistingState.Stats["PLANS_COMPLETADOS"] } else { "UNKNOWN" }
    }

    if (-not $stats.Pending) {
        $stats.Pending = if ($ExistingState.Stats.ContainsKey("PLANS_PENDIENTES")) { $ExistingState.Stats["PLANS_PENDIENTES"] } else { "UNKNOWN" }
    }

    return $stats
}

function Get-HIARadarTimestamp {
    param(
        [string]$Root,
        [hashtable]$ExistingState
    )

    $radarDir = Join-Path $Root "03_ARTIFACTS\RADAR"
    if (Test-Path $radarDir) {
        $files = Get-ChildItem -Path $radarDir -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '^Radar\..*\.ACTIVE\.txt$'
        }

        if (-not $files) {
            $files = Get-ChildItem -Path $radarDir -Filter "*.txt" -File -ErrorAction SilentlyContinue
        }

        if ($files) {
            $latest = $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
            if ($latest) {
                return $latest.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm 'UTC'")
            }
        }
    }

    if ($ExistingState.Stats.ContainsKey("ULTIMO_RADAR")) {
        return $ExistingState.Stats["ULTIMO_RADAR"]
    }

    return "UNKNOWN"
}

function Get-HIALastActivityTimestamp {
    param(
        [string]$Root,
        [hashtable]$ExistingState
    )

    try {
        $recent = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\node_modules\\' } |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1

        if ($recent) {
            return $recent.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm 'UTC'")
        }
    }
    catch {
        # Fallback below
    }

    if ($ExistingState.Stats.ContainsKey("ULTIMA_ACTIVIDAD")) {
        return $ExistingState.Stats["ULTIMA_ACTIVIDAD"]
    }

    return "UNKNOWN"
}

function Get-HIAAvailableCommands {
    param([string]$Root)

    $commands = @(
        @{ Cmd = "hia help"; Desc = "Lista todos los comandos" }
    )

    $toolRegistryPath = Join-Path $Root "02_TOOLS\TOOL.REGISTRY.json"
    if (Test-Path $toolRegistryPath) {
        try {
            $toolReg = Get-Content -Path $toolRegistryPath -Raw | ConvertFrom-Json
            foreach ($tool in ($toolReg.tools.PSObject.Properties | Sort-Object Name)) {
                $scriptName = [string]$tool.Value.script
                $scriptPath = Join-Path $Root "02_TOOLS\$scriptName"
                if (-not (Test-Path $scriptPath)) {
                    $scriptPath = Join-Path $Root "02_TOOLS\Maintenance\$scriptName"
                }

                if (-not (Test-Path $scriptPath)) {
                    continue
                }

                $cmdText = switch ($tool.Name.ToLowerInvariant()) {
                    "plan" { 'hia plan "task"' }
                    "apply" { "hia apply PLAN_0001" }
                    "run" { "hia run PLAN_0001" }
                    "state" { "hia state [show|sync|history]" }
                    default { "hia $($tool.Name)" }
                }

                $descText = if ($tool.Value.description) { [string]$tool.Value.description } else { "Comando disponible" }
                $commands += @{ Cmd = $cmdText; Desc = $descText }
            }
        }
        catch {
            # Keep currently known commands only
        }
    }

    $agentRegistryPath = Join-Path $Root "04_AGENTS\AGENT.REGISTRY.json"
    if (Test-Path $agentRegistryPath) {
        try {
            $agentReg = Get-Content -Path $agentRegistryPath -Raw | ConvertFrom-Json
            foreach ($agent in ($agentReg.agents.PSObject.Properties | Sort-Object Name)) {
                $commands += @{
                    Cmd = "hia agent $($agent.Name)"
                    Desc = if ($agent.Value.description) { [string]$agent.Value.description } else { "Agente disponible" }
                }
            }
        }
        catch {
            # Ignore if malformed
        }
    }

    $formatted = @()
    foreach ($entry in $commands) {
        $formatted += ("{0,-30} - {1}" -f $entry.Cmd, $entry.Desc)
    }

    return $formatted | Sort-Object -Unique
}

function Get-HIANextStep {
    return @(
        "- MB-0.6: Session Lifecycle",
        "- MB-1.0: Console Web MVP"
    )
}

function Get-HIAMiniBattlesCompletados {
    param(
        [hashtable]$ExistingState,
        [string]$Root
    )

    $result = @()
    if ($ExistingState.MiniBattles.Count -gt 0) {
        $result = @($ExistingState.MiniBattles)
    }
    else {
        $result = @(
            "[MB-0.1] Command Router (2026-03-16)",
            "[MB-0.2] Tool & Agent Registry (2026-03-16)",
            "[MB-0.3] Smoke Test (2026-03-16)",
            "[MB-0.4] Agent Executor (2026-03-16)"
        )
    }

    $toolRegistryPath = Join-Path $Root "02_TOOLS\TOOL.REGISTRY.json"
    $hasStateTool = $false
    if (Test-Path $toolRegistryPath) {
        try {
            $toolReg = Get-Content -Path $toolRegistryPath -Raw | ConvertFrom-Json
            $hasStateTool = $null -ne $toolReg.tools.state
        }
        catch {
            $hasStateTool = $false
        }
    }

    if ($hasStateTool -and -not ($result | Where-Object { $_ -match '^\[MB-0\.5\]' })) {
        $result += "[MB-0.5] State Sync (2026-03-23)"
    }

    return $result
}

function Write-StateHistory {
    param(
        [string]$Type,
        [string]$Message
    )

    if (-not (Test-Path $script:LogsDir)) {
        New-Item -Path $script:LogsDir -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp][$Type] $Message"

    if (-not (Test-Path $script:StateHistoryPath)) {
        @"
================================================================================
HIA STATE HISTORY
================================================================================
Registro de cambios de estado del proyecto.
Formato: [timestamp][type] message
================================================================================

"@ | Set-Content -Path $script:StateHistoryPath -Encoding UTF8
    }

    Add-Content -Path $script:StateHistoryPath -Value $entry -Encoding UTF8
    return $entry
}

function Show-HIAState {
    $stateData = Read-HIAStateFile -Path $script:StateLivePath
    if (-not $stateData.Exists) {
        Write-Host ""
        Write-Host "STATE FILE NOT FOUND:" -ForegroundColor Yellow
        Write-Host "  $script:StateLivePath"
        Write-Host ""
        Write-Host "Run: hia state sync" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Get-Content -Path $script:StateLivePath
}

function Sync-HIAState {
    $existingState = Read-HIAStateFile -Path $script:StateLivePath

    $toolsCount = Get-HIAToolCount -Root $script:ProjectRoot -ExistingState $existingState
    $agentsCount = Get-HIAAgentCount -Root $script:ProjectRoot -ExistingState $existingState
    $planStats = Get-HIAPlanStats -Root $script:ProjectRoot -ExistingState $existingState
    $radarTimestamp = Get-HIARadarTimestamp -Root $script:ProjectRoot -ExistingState $existingState
    $lastActivity = Get-HIALastActivityTimestamp -Root $script:ProjectRoot -ExistingState $existingState
    $availableCommands = Get-HIAAvailableCommands -Root $script:ProjectRoot
    $miniBattles = Get-HIAMiniBattlesCompletados -ExistingState $existingState -Root $script:ProjectRoot
    $nextStep = Get-HIANextStep

    if (-not (Test-Path $script:StateLiveDir)) {
        New-Item -Path $script:StateLiveDir -ItemType Directory -Force | Out-Null
    }

    $generatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $focusActual = $existingState.FocusActual
    $mvpActivo = $existingState.MvpActivo

    $content = @"
================================================================================
FILE: PROJECT.STATE.LIVE.txt
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: Operational State (LIVE)
GENERATED: $generatedAt
================================================================================

FOCO_ACTUAL
------------------------------------------------------------------------------
$focusActual

MVP_ACTIVO
------------------------------------------------------------------------------
$mvpActivo

MINIBATTLES_COMPLETADOS
------------------------------------------------------------------------------
$($miniBattles -join [Environment]::NewLine)

ESTADISTICAS
------------------------------------------------------------------------------
TOOLS_REGISTRADOS: $toolsCount
AGENTS_REGISTRADOS: $agentsCount
PLANS_TOTAL: $($planStats.Total)
PLANS_COMPLETADOS: $($planStats.Completed)
PLANS_PENDIENTES: $($planStats.Pending)
ULTIMO_RADAR: $radarTimestamp
ULTIMA_ACTIVIDAD: $lastActivity

COMANDOS_DISPONIBLES
------------------------------------------------------------------------------
$($availableCommands -join [Environment]::NewLine)

PROXIMO_PASO
------------------------------------------------------------------------------
$($nextStep -join [Environment]::NewLine)

================================================================================
"@

    Set-Content -Path $script:StateLivePath -Value $content -Encoding UTF8

    Write-StateHistory -Type "SYNC" -Message "State synchronized" | Out-Null

    Write-Host ""
    Write-Host "STATE SYNC COMPLETE" -ForegroundColor Green
    Write-Host "LIVE_PATH: $script:StateLivePath"
    Write-Host ""
    Write-Host "UPDATED_FIELDS:" -ForegroundColor Cyan
    Write-Host "  TOOLS_REGISTRADOS = $toolsCount"
    Write-Host "  AGENTS_REGISTRADOS = $agentsCount"
    Write-Host "  PLANS_TOTAL = $($planStats.Total)"
    Write-Host "  PLANS_COMPLETADOS = $($planStats.Completed)"
    Write-Host "  PLANS_PENDIENTES = $($planStats.Pending)"
    Write-Host "  ULTIMO_RADAR = $radarTimestamp"
    Write-Host "  ULTIMA_ACTIVIDAD = $lastActivity"
    Write-Host "  COMANDOS_DISPONIBLES = $($availableCommands.Count)"
    Write-Host "  PROXIMO_PASO = $($nextStep -join '; ')"
    Write-Host ""
}

function Show-HIAStateHistory {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " HIA STATE HISTORY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path $script:StateHistoryPath) {
        Get-Content -Path $script:StateHistoryPath -Tail 30
    }
    else {
        Write-Host "No history yet." -ForegroundColor DarkGray
    }

    Write-Host ""
}

function Update-HIAState {
    param(
        [string]$Message,
        [string]$Type
    )

    if (-not $Message) {
        Write-Host "ERROR: -Message required for update" -ForegroundColor Red
        return
    }

    $entry = Write-StateHistory -Type $Type.ToUpperInvariant() -Message $Message
    Sync-HIAState
    Write-Host "HISTORY_ENTRY: $entry" -ForegroundColor Green
}

$script:ProjectRoot = Get-HIAProjectRoot -CandidateRoot $ProjectRoot
$script:StateLivePath = Get-HIALiveStatePath -Root $script:ProjectRoot
$script:StateLiveDir = Split-Path -Path $script:StateLivePath -Parent
$script:StateHistoryPath = Join-Path $script:ProjectRoot "03_ARTIFACTS\logs\STATE.HISTORY.txt"
$script:LogsDir = Join-Path $script:ProjectRoot "03_ARTIFACTS\logs"

switch ($Command) {
    "show" { Show-HIAState }
    "sync" { Sync-HIAState }
    "history" { Show-HIAStateHistory }
    "update" { Update-HIAState -Message $Message -Type $Type }
    default { Show-HIAState }
}
