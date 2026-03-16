<#
===============================================================================
MODULE: HIA_STATE_ENGINE.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: STATE MANAGEMENT

OBJETIVO
Gestionar el estado del proyecto HIA de forma automatizada.

COMMANDS:
- show: Muestra estado actual
- update: Actualiza estado con nuevo hito/cambio
- sync: Sincroniza estado desde artifacts
- history: Muestra historial de cambios

VERSION: v1.0
DATE: 2026-03-16
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("show", "update", "sync", "history")]
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

$stateLivePath = Join-Path $ProjectRoot "01_UI\terminal\PROJECT.STATE.LIVE.txt"
$stateHistoryPath = Join-Path $ProjectRoot "03_ARTIFACTS\logs\STATE.HISTORY.txt"
$toolRegistryPath = Join-Path $ProjectRoot "02_TOOLS\TOOL.REGISTRY.json"
$agentRegistryPath = Join-Path $ProjectRoot "04_AGENTS\AGENT.REGISTRY.json"
$plansDir = Join-Path $ProjectRoot "03_ARTIFACTS\plans"
$logsDir = Join-Path $ProjectRoot "03_ARTIFACTS\logs"

foreach ($dir in @($logsDir, $plansDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

function Get-HIAStats {
    param([string]$Root)

    $stats = @{
        tools_count = 0
        agents_count = 0
        plans_total = 0
        plans_completed = 0
        plans_pending = 0
        last_radar = $null
        last_activity = $null
    }

    if (Test-Path $toolRegistryPath) {
        $toolReg = Get-Content $toolRegistryPath -Raw | ConvertFrom-Json
        $stats.tools_count = ($toolReg.tools.PSObject.Properties | Measure-Object).Count
    }

    if (Test-Path $agentRegistryPath) {
        $agentReg = Get-Content $agentRegistryPath -Raw | ConvertFrom-Json
        $stats.agents_count = ($agentReg.agents.PSObject.Properties | Measure-Object).Count
    }

    if (Test-Path $plansDir) {
        $planFiles = Get-ChildItem -Path $plansDir -Filter "*.json" -ErrorAction SilentlyContinue
        $stats.plans_total = $planFiles.Count

        foreach ($planFile in $planFiles) {
            try {
                $plan = Get-Content $planFile.FullName -Raw | ConvertFrom-Json
                if ($plan.status -eq "completed") {
                    $stats.plans_completed++
                }
                elseif ($plan.status -eq "planned" -or $plan.status -eq "approved") {
                    $stats.plans_pending++
                }
            }
            catch {
                # Skip invalid plan files
            }
        }
    }

    $radarDir = Join-Path $Root "03_ARTIFACTS\RADAR"
    if (Test-Path $radarDir) {
        $lastRadar = Get-ChildItem -Path $radarDir -Filter "*.txt" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($lastRadar) {
            $stats.last_radar = $lastRadar.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        }
    }

    $recentFile = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\\.git\\" -and $_.FullName -notmatch "\\node_modules\\" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($recentFile) {
        $stats.last_activity = $recentFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
    }

    return $stats
}

function Get-CompletedMiniBattles {
    $completed = @(
        @{ id = "MB-0.1"; name = "Command Router"; date = "2026-03-16" }
        @{ id = "MB-0.2"; name = "Tool & Agent Registry"; date = "2026-03-16" }
        @{ id = "MB-0.3"; name = "Smoke Test"; date = "2026-03-16" }
        @{ id = "MB-0.4"; name = "Agent Executor"; date = "2026-03-16" }
    )

    return $completed
}

function Write-StateHistory {
    param(
        [string]$Type,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp][$Type] $Message"

    if (-not (Test-Path $stateHistoryPath)) {
        @"
================================================================================
HIA STATE HISTORY
================================================================================
Registro de cambios de estado del proyecto.
Formato: [timestamp][type] message
================================================================================

"@ | Set-Content -Path $stateHistoryPath -Encoding UTF8
    }

    Add-Content -Path $stateHistoryPath -Value $entry -Encoding UTF8

    return $entry
}

function Update-StateLive {
    param(
        [hashtable]$Stats,
        [array]$MiniBattles
    )

    $now = Get-Date
    $content = @"
================================================================================
FILE: PROJECT.STATE.LIVE.txt
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: Operational State (LIVE)
GENERATED: $($now.ToString("yyyy-MM-dd HH:mm:ss"))
================================================================================

FOCO_ACTUAL
------------------------------------------------------------------------------
Sistema de orquestacion multi-agente con CLI funcional.

MVP_ACTIVO
------------------------------------------------------------------------------
MVP-0 — Kernel CLI estable

MINIBATTLES_COMPLETADOS
------------------------------------------------------------------------------
$($MiniBattles | ForEach-Object { "[$($_.id)] $($_.name) ($($_.date))" } | Out-String)
ESTADISTICAS
------------------------------------------------------------------------------
TOOLS_REGISTRADOS: $($Stats.tools_count)
AGENTS_REGISTRADOS: $($Stats.agents_count)
PLANS_TOTAL: $($Stats.plans_total)
PLANS_COMPLETADOS: $($Stats.plans_completed)
PLANS_PENDIENTES: $($Stats.plans_pending)
ULTIMO_RADAR: $($Stats.last_radar)
ULTIMA_ACTIVIDAD: $($Stats.last_activity)

COMANDOS_DISPONIBLES
------------------------------------------------------------------------------
hia help          - Lista todos los comandos
hia smoke         - Ejecuta smoke test
hia plan "task"   - Crea nuevo PLAN
hia apply ID      - Aprueba PLAN
hia state         - Muestra este estado
hia state sync    - Sincroniza estado
hia agent planner - Agente de planificacion
hia agent executor - Agente de ejecucion

PROXIMO_PASO
------------------------------------------------------------------------------
- MB-0.5: State Sync (en progreso)
- MB-0.6: Session Lifecycle
- MB-1.0: Console Web MVP

================================================================================
"@

    Set-Content -Path $stateLivePath -Value $content -Encoding UTF8

    return $stateLivePath
}

# -----------------------------------------------------------------------------
# COMMANDS
# -----------------------------------------------------------------------------

function Show-State {
    $stats = Get-HIAStats -Root $ProjectRoot
    $minibattles = Get-CompletedMiniBattles

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " HIA PROJECT STATE" -ForegroundColor Cyan
    Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "ESTADISTICAS:" -ForegroundColor Yellow
    Write-Host "  Tools registrados:    $($stats.tools_count)"
    Write-Host "  Agents registrados:   $($stats.agents_count)"
    Write-Host "  Plans totales:        $($stats.plans_total)"
    Write-Host "  Plans completados:    $($stats.plans_completed)"
    Write-Host "  Plans pendientes:     $($stats.plans_pending)"
    Write-Host "  Ultimo RADAR:         $($stats.last_radar)"
    Write-Host "  Ultima actividad:     $($stats.last_activity)"
    Write-Host ""

    Write-Host "MINIBATTLES COMPLETADOS:" -ForegroundColor Yellow
    foreach ($mb in $minibattles) {
        Write-Host "  [$($mb.id)] $($mb.name)" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "PROJECT_ROOT: $ProjectRoot" -ForegroundColor DarkGray
    Write-Host ""
}

function Update-State {
    param(
        [string]$Message,
        [string]$Type
    )

    if (-not $Message) {
        Write-Host "ERROR: -Message required for update" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Updating state..." -ForegroundColor Cyan

    $entry = Write-StateHistory -Type $Type.ToUpper() -Message $Message
    Write-Host "  History: $entry" -ForegroundColor Green

    $stats = Get-HIAStats -Root $ProjectRoot
    $minibattles = Get-CompletedMiniBattles
    $path = Update-StateLive -Stats $stats -MiniBattles $minibattles
    Write-Host "  Updated: $path" -ForegroundColor Green

    Write-Host ""
    Write-Host "STATE UPDATED" -ForegroundColor Green
    Write-Host ""
}

function Sync-State {
    Write-Host ""
    Write-Host "Syncing state from artifacts..." -ForegroundColor Cyan

    $stats = Get-HIAStats -Root $ProjectRoot
    $minibattles = Get-CompletedMiniBattles

    $path = Update-StateLive -Stats $stats -MiniBattles $minibattles

    Write-Host "  Stats collected" -ForegroundColor Green
    Write-Host "  MiniBattles: $($minibattles.Count) completed" -ForegroundColor Green
    Write-Host "  Updated: $path" -ForegroundColor Green

    Write-StateHistory -Type "SYNC" -Message "State synchronized"

    Write-Host ""
    Write-Host "STATE SYNCED" -ForegroundColor Green
    Write-Host ""
}

function Show-History {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " HIA STATE HISTORY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path $stateHistoryPath) {
        $lines = Get-Content $stateHistoryPath -Tail 20
        foreach ($line in $lines) {
            if ($line -match "^\[") {
                if ($line -match "\[MINIBATTLE\]") {
                    Write-Host $line -ForegroundColor Green
                }
                elseif ($line -match "\[MVP\]") {
                    Write-Host $line -ForegroundColor Cyan
                }
                elseif ($line -match "\[ERROR\]") {
                    Write-Host $line -ForegroundColor Red
                }
                else {
                    Write-Host $line
                }
            }
        }
    }
    else {
        Write-Host "No history yet." -ForegroundColor DarkGray
    }

    Write-Host ""
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host " HIA STATE ENGINE" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

switch ($Command) {
    "show" {
        Show-State
    }
    "update" {
        Update-State -Message $Message -Type $Type
    }
    "sync" {
        Sync-State
    }
    "history" {
        Show-History
    }
    default {
        Show-State
    }
}
