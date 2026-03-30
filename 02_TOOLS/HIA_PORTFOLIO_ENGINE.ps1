<#
===============================================================================
MODULE: HIA_PORTFOLIO_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: PORTFOLIO / PROJECT SELECTOR SHELL (MB-1.7)
===============================================================================

OBJETIVO
Portfolio shell mínima que permite:
- Ver proyectos activos detectados
- Entrar a un proyecto y reusar el shell interactivo del proyecto
- Mostrar estado mínimo por proyecto (MVP activo, próximo paso, última sesión)
- Create project / Vault como stubs honestos

DETECCIÓN (HONESTA Y SIMPLE)
Proyecto válido si el directorio contiene:
- 02_TOOLS\
- 01_UI\terminal\hia.ps1

REPLAY (para validación no interactiva)
Si $env:HIA_INTERACTIVE_REPLAY apunta a un .txt, consume inputs línea por línea.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAReplayQueue {
    param([string]$ReplayPath)
    if ([string]::IsNullOrWhiteSpace($ReplayPath)) { return $null }
    if (-not (Test-Path -LiteralPath $ReplayPath)) { return $null }
    $lines = @(Get-Content -LiteralPath $ReplayPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    if ($lines.Count -eq 0) { return $null }
    $q = [System.Collections.Generic.Queue[string]]::new()
    foreach ($l in $lines) { $q.Enqueue($l) }
    return ,$q
}

function Read-HIAInteractiveInput {
    param(
        [string]$Prompt,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )
    if ($ReplayQueue -and $ReplayQueue.Count -gt 0) {
        $next = $ReplayQueue.Dequeue()
        Write-Host ("{0}{1}" -f $Prompt, $next) -ForegroundColor DarkGray
        return $next
    }
    $v = Read-Host -Prompt $Prompt
    if ($null -eq $v) { return "" }
    return $v
}

function Pause-HIAInteractive {
    param([System.Collections.Generic.Queue[string]]$ReplayQueue)
    $null = Read-HIAInteractiveInput -Prompt " Enter para continuar..." -ReplayQueue $ReplayQueue
}

function Try-ReadFileRaw {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { return $null }
        return (Get-Content -LiteralPath $Path -Raw)
    }
    catch {
        return $null
    }
}

function Get-HIASectionText {
    param(
        [string]$Text,
        [string]$SectionName,
        [string]$NextSectionName
    )
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $lines = @($Text -split "\r?\n")
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $SectionName) { $startIndex = $i; break }
    }
    if ($startIndex -lt 0) { return $null }
    $cursor = $startIndex + 1
    if ($cursor -lt $lines.Count -and $lines[$cursor].Trim() -match '^[-=]{3,}$') { $cursor++ }

    $collected = New-Object System.Collections.Generic.List[string]
    for ($k = $cursor; $k -lt $lines.Count; $k++) {
        $line = $lines[$k]
        $trimmed = $line.Trim()
        if ($NextSectionName -and $trimmed -eq $NextSectionName) { break }
        if ($trimmed -match '^={5,}$') { break }
        if (
            $trimmed -match '^[A-Z0-9_.]+$' -and
            ($k + 1) -lt $lines.Count -and
            $lines[$k + 1].Trim() -match '^[-=]{3,}$'
        ) { break }
        if (-not [string]::IsNullOrWhiteSpace($line)) { $collected.Add($trimmed) }
    }
    if ($collected.Count -eq 0) { return $null }
    return ($collected -join [Environment]::NewLine).Trim()
}

function Read-HIAProjectMiniState {
    param([string]$ProjectRoot)
    $livePath = Join-Path $ProjectRoot "01_UI\\terminal\\PROJECT.STATE.LIVE.txt"
    $raw = Try-ReadFileRaw -Path $livePath

    $state = [ordered]@{
        live_exists = $false
        live_path = $livePath
        mvp_activo = "UNKNOWN"
        proximo_paso = "UNKNOWN"
        generated_local = "UNKNOWN"
    }

    if ($null -eq $raw) { return $state }
    $state.live_exists = $true

    $generatedMatch = [regex]::Match($raw, '(?m)^GENERATED:\s*(.+)$')
    if ($generatedMatch.Success) { $state.generated_local = $generatedMatch.Groups[1].Value.Trim() }

    $mvp = Get-HIASectionText -Text $raw -SectionName "MVP_ACTIVO" -NextSectionName "MINIBATTLES_COMPLETADOS"
    if ($mvp) { $state.mvp_activo = ($mvp -replace "\r?\n", " / ") }
    $next = Get-HIASectionText -Text $raw -SectionName "PROXIMO_PASO" -NextSectionName ""
    if ($next) { $state.proximo_paso = ($next -replace "\r?\n", " / ") }
    return $state
}

function Get-HIALastSessionSummary {
    param([string]$ProjectRoot)
    $sessionsDir = Join-Path $ProjectRoot "03_ARTIFACTS\\sessions"
    try {
        if (-not (Test-Path -LiteralPath $sessionsDir)) { return "NONE" }
        $latest = Get-ChildItem -LiteralPath $sessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if (-not $latest) { return "NONE" }
        return ("{0} ({1})" -f $latest.Name, $latest.LastWriteTime)
    }
    catch {
        return "UNKNOWN"
    }
}

function Test-HIAProjectCandidate {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Path "02_TOOLS") -PathType Container)) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $Path "01_UI\\terminal\\hia.ps1") -PathType Leaf)) { return $false }
    return $true
}

function Get-HIAPortfolioProjects {
    param([string]$PortfolioRoot)
    $projects = New-Object System.Collections.Generic.List[object]
    $dirs = Get-ChildItem -LiteralPath $PortfolioRoot -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $full = $d.FullName
        if (Test-HIAProjectCandidate -Path $full) {
            $mini = Read-HIAProjectMiniState -ProjectRoot $full
            $lastSession = Get-HIALastSessionSummary -ProjectRoot $full
            $projects.Add([ordered]@{
                name = $d.Name
                path = $full
                mvp_activo = $mini.mvp_activo
                proximo_paso = $mini.proximo_paso
                live_exists = $mini.live_exists
                generated_local = $mini.generated_local
                last_session = $lastSession
            })
        }
    }
    $arr = @($projects | Sort-Object name)
    if ($arr -isnot [array]) { $arr = @($arr) }
    return $arr
}

function Write-HIAPortfolioHeader {
    param([string]$PortfolioRoot)
    try { Clear-Host } catch { }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " HIA — Portfolio Shell (MB-1.7)" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host (" PORTFOLIO_ROOT: {0}" -f $PortfolioRoot)
    Write-Host (" NOW:            {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Selecciona opcion (numero) • F1=Ayuda • 0=Salir" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-HIAPortfolioHelp {
    Write-Host ""
    Write-Host "AYUDA — Portfolio shell" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1  Lista proyectos detectados (con estado mínimo)."
    Write-Host "4  Entrar a un proyecto y abrir su shell operativo."
    Write-Host "2/3 Son stubs honestos (no implementados en MB-1.7)."
    Write-Host ""
}

function Show-HIAPortfolioMenu {
    Write-Host "HIA — Menú principal" -ForegroundColor Yellow
    Write-Host "1.- Ver proyectos activos"
    Write-Host "2.- Crear proyecto"
    Write-Host "3.- Ver Vault"
    Write-Host "4.- Entrar a proyecto"
    Write-Host "5.- Herramientas técnicas globales"
    Write-Host "F1.- Ayuda"
    Write-Host "0.- Salir"
    Write-Host ""
}

function Show-HIAProjectsList {
    param([object[]]$Projects)
    Write-Host ""
    Write-Host ("PROYECTOS DETECTADOS: {0}" -f $Projects.Count) -ForegroundColor Yellow
    Write-Host ""
    for ($i = 0; $i -lt $Projects.Count; $i++) {
        $p = $Projects[$i]
        $status = if ($p.live_exists) { "OK" } else { "NO_STATE" }
        Write-Host ("{0}.- {1} [{2}]" -f ($i + 1), $p.name, $status) -ForegroundColor Cyan
        Write-Host ("    PATH: {0}" -f $p.path) -ForegroundColor DarkGray
        Write-Host ("    MVP:  {0}" -f $p.mvp_activo)
        Write-Host ("    NEXT: {0}" -f $p.proximo_paso)
        Write-Host ("    LAST_SESSION: {0}" -f $p.last_session) -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Invoke-HIAEnterProjectShell {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )
    $enginePath = Join-Path $ProjectRoot "02_TOOLS\\HIA_INTERACTIVE_ENGINE.ps1"
    if (Test-Path -LiteralPath $enginePath) {
        . $enginePath
        Invoke-HIAInteractiveEntrypoint -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue
        return
    }

    # Fallback: if project does not have the full engine, run its own entrypoint.
    $projectEntrypoint = Join-Path $ProjectRoot "01_UI\\terminal\\hia.ps1"
    if (-not (Test-Path -LiteralPath $projectEntrypoint)) {
        Write-Host ""
        Write-Host "ERROR: Project entrypoint not found." -ForegroundColor Red
        Write-Host ("PATH: {0}" -f $projectEntrypoint) -ForegroundColor DarkGray
        Write-Host ""
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
        return
    }

    & pwsh -NoProfile -File $projectEntrypoint
    Pause-HIAInteractive -ReplayQueue $ReplayQueue
}

function Invoke-HIAPortfolioShell {
    param([string]$ProjectRoot)

    $portfolioRoot = Split-Path $ProjectRoot -Parent
    $queue = Get-HIAReplayQueue -ReplayPath $env:HIA_INTERACTIVE_REPLAY

    while ($true) {
        Write-HIAPortfolioHeader -PortfolioRoot $portfolioRoot
        Show-HIAPortfolioMenu

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $queue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "0" { return }
            "F1" { Show-HIAPortfolioHelp; Pause-HIAInteractive -ReplayQueue $queue }
            "1" {
                $projects = @(Get-HIAPortfolioProjects -PortfolioRoot $portfolioRoot)
                Show-HIAProjectsList -Projects $projects
                Pause-HIAInteractive -ReplayQueue $queue
            }
            "2" {
                Write-Host ""
                $bootstrapPath = Join-Path $ProjectRoot "02_TOOLS\\HIA_PROJECT_BOOTSTRAP_ENGINE.ps1"
                if (-not (Test-Path -LiteralPath $bootstrapPath)) {
                    Write-Host "ERROR: Bootstrap engine not found." -ForegroundColor Red
                    Write-Host ("PATH: {0}" -f $bootstrapPath) -ForegroundColor DarkGray
                    Write-Host ""
                    Pause-HIAInteractive -ReplayQueue $queue
                    continue
                }

                try {
                    Write-Host "CREATE PROJECT (BOOTSTRAP MVP)" -ForegroundColor Yellow
                    Write-Host "Inputs: project_id, project_name, description, project_type, base_root" -ForegroundColor DarkGray
                    Write-Host ""

                    $pid = Read-HIAInteractiveInput -Prompt " project_id (short): " -ReplayQueue $queue
                    $pname = Read-HIAInteractiveInput -Prompt " project_name (visible): " -ReplayQueue $queue
                    $desc = Read-HIAInteractiveInput -Prompt " description (brief): " -ReplayQueue $queue
                    $ptype = Read-HIAInteractiveInput -Prompt " project_type (app/analysis/automation/framework/other) [other]: " -ReplayQueue $queue
                    $base = Read-HIAInteractiveInput -Prompt " base_root (blank=default portfolio root): " -ReplayQueue $queue

                    $args = @(
                        "-Command", "create",
                        "-ProjectId", $pid,
                        "-ProjectName", $pname,
                        "-Description", $desc,
                        "-ProjectType", $(if ([string]::IsNullOrWhiteSpace($ptype)) { "other" } else { $ptype }),
                        "-BaseRoot", $base
                    )

                    $json = & $bootstrapPath @args 2>&1 | Out-String
                    $result = $null
                    try { $result = ($json | ConvertFrom-Json) } catch { $result = $null }

                    if ($null -eq $result -or [string]::IsNullOrWhiteSpace([string]$result.project_root)) {
                        Write-Host ""
                        Write-Host "CREATE PROJECT FAILED" -ForegroundColor Red
                        Write-Host "DETAILS:" -ForegroundColor Yellow
                        Write-Host $json
                        Write-Host ""
                        Pause-HIAInteractive -ReplayQueue $queue
                        continue
                    }

                    Write-Host ""
                    Write-Host "CREATE PROJECT COMPLETE" -ForegroundColor Green
                    Write-Host ("ROOT: {0}" -f $result.project_root)
                    Write-Host ""

                    $enter = Read-HIAInteractiveInput -Prompt " Entrar al proyecto ahora? (Y/N): " -ReplayQueue $queue
                    if ($enter.Trim().ToUpperInvariant() -eq "Y") {
                        Invoke-HIAEnterProjectShell -ProjectRoot ([string]$result.project_root) -ReplayQueue $queue
                    }
                    else {
                        Pause-HIAInteractive -ReplayQueue $queue
                    }
                }
                catch {
                    Write-Host ""
                    Write-Host "CREATE PROJECT ERROR" -ForegroundColor Red
                    Write-Host ("MESSAGE: {0}" -f $_.Exception.Message) -ForegroundColor Red
                    Write-Host ""
                    Pause-HIAInteractive -ReplayQueue $queue
                }
            }
            "3" {
                Write-Host ""
                Write-Host "VAULT (STUB)" -ForegroundColor Yellow
                Write-Host "NOT IMPLEMENTED in MB-1.7." -ForegroundColor Yellow
                Write-Host "Next: implement vault shell in a future minibattle." -ForegroundColor DarkGray
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $queue
            }
            "4" {
                $projects = @(Get-HIAPortfolioProjects -PortfolioRoot $portfolioRoot)
                Show-HIAProjectsList -Projects $projects
                if ($projects.Count -eq 0) {
                    Write-Host "No projects detected." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $queue
                    continue
                }
                $pick = (Read-HIAInteractiveInput -Prompt " Elegir proyecto (numero) o X: " -ReplayQueue $queue).Trim()
                if ($pick.ToUpperInvariant() -eq "X") { continue }
                if (-not ($pick -match '^\d+$')) {
                    Write-Host "Seleccion invalida." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $queue
                    continue
                }
                $idx = [int]$pick - 1
                if ($idx -lt 0 -or $idx -ge $projects.Count) {
                    Write-Host "Seleccion fuera de rango." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $queue
                    continue
                }
                $target = $projects[$idx]
                Invoke-HIAEnterProjectShell -ProjectRoot $target.path -ReplayQueue $queue
            }
            "5" {
                Write-Host ""
                Write-Host "HERRAMIENTAS TÉCNICAS GLOBALES" -ForegroundColor Yellow
                Write-Host "- (MVP) Usa `hia stack` dentro del proyecto para diagnóstico del AI stack." -ForegroundColor DarkGray
                Write-Host "- (MVP) Entra a un proyecto para tools específicas (radar/validate/smoke/etc.)." -ForegroundColor DarkGray
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $queue
            }
            default {
                Write-Host "Seleccion invalida. Usa 1-5, F1 o 0." -ForegroundColor Yellow
                Pause-HIAInteractive -ReplayQueue $queue
            }
        }
    }
}
