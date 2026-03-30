<#
===============================================================================
MODULE: HIA_INTERACTIVE_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: GUIDED INTERACTIVE CLI (MB-1.1)
===============================================================================

OBJETIVO
Implementar un modo interactivo guiado (menu + submenus) para peatón.

PRINCIPIOS
- Reusar comandos existentes via Invoke-HIARouter o scripts ya presentes.
- No inventar estados: leer artefactos reales cuando existan.
- No ejecutar acciones destructivas.

TEST/REPLAY (NO INVADE UX)
Si se define $env:HIA_INTERACTIVE_REPLAY con una ruta a un .txt, el motor
consume inputs línea por línea (útil para smoke/validación local sin teclado).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAInteractiveTimestamp {
    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Get-HIAProjectRootFromEntrypoint {
    param([string]$ProjectRoot)
    if (-not $ProjectRoot) { throw "ProjectRoot required for interactive engine." }
    return $ProjectRoot
}

function Get-HIALiveStatePath {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "01_UI\terminal\PROJECT.STATE.LIVE.txt")
}

function Get-HIASessionsDir {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "03_ARTIFACTS\sessions")
}

function Get-HIAPlansDir {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "03_ARTIFACTS\plans")
}

function Get-HIAActiveSessionPath {
    param([string]$ProjectRoot)
    $sessionsDir = Get-HIASessionsDir -ProjectRoot $ProjectRoot
    return (Join-Path $sessionsDir "ACTIVE_SESSION.json")
}

function Get-HIASectionText {
    param(
        [string]$Text,
        [string]$SectionName,
        [string]$NextSectionName
    )

    $lines = @($Text -split "\r?\n")
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $SectionName) {
            $startIndex = $i
            break
        }
    }
    if ($startIndex -lt 0) { return $null }

    $cursor = $startIndex + 1
    if ($cursor -lt $lines.Count -and $lines[$cursor].Trim() -match '^[-=]{3,}$') {
        $cursor++
    }

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
        ) {
            break
        }

        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $collected.Add($trimmed)
        }
    }

    if ($collected.Count -eq 0) { return $null }
    return ($collected -join [Environment]::NewLine).Trim()
}

function Read-HIAProjectStateLive {
    param([string]$ProjectRoot)

    $path = Get-HIALiveStatePath -ProjectRoot $ProjectRoot
    $state = [ordered]@{
        exists = $false
        live_path = $path
        generated_local = "UNKNOWN"
        foco_actual = "UNKNOWN"
        mvp_activo = "UNKNOWN"
        proximo_paso = "UNKNOWN"
        ultimo_radar = "UNKNOWN"
        ultima_actividad = "UNKNOWN"
        minibattles = @()
    }

    if (-not (Test-Path -LiteralPath $path)) {
        return $state
    }

    $raw = Get-Content -LiteralPath $path -Raw
    $state.exists = $true

    $generatedMatch = [regex]::Match($raw, '(?m)^GENERATED:\s*(.+)$')
    if ($generatedMatch.Success) {
        $state.generated_local = $generatedMatch.Groups[1].Value.Trim()
    }

    $foco = Get-HIASectionText -Text $raw -SectionName "FOCO_ACTUAL" -NextSectionName "MVP_ACTIVO"
    if ($foco) { $state.foco_actual = $foco }

    $mvp = Get-HIASectionText -Text $raw -SectionName "MVP_ACTIVO" -NextSectionName "MINIBATTLES_COMPLETADOS"
    if ($mvp) { $state.mvp_activo = $mvp }

    $nextStep = Get-HIASectionText -Text $raw -SectionName "PROXIMO_PASO" -NextSectionName ""
    if ($nextStep) { $state.proximo_paso = $nextStep }

    $miniText = Get-HIASectionText -Text $raw -SectionName "MINIBATTLES_COMPLETADOS" -NextSectionName "ESTADISTICAS"
    if ($miniText) {
        $miniLines = @($miniText -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\[MB-' })
        $state.minibattles = $miniLines
    }

    foreach ($line in ($raw -split "\r?\n")) {
        if ($line -match '^\s*ULTIMO_RADAR:\s*(.+)$') {
            $state.ultimo_radar = $matches[1].Trim()
        }
        elseif ($line -match '^\s*ULTIMA_ACTIVIDAD:\s*(.+)$') {
            $state.ultima_actividad = $matches[1].Trim()
        }
    }

    return $state
}

function Read-HIAActiveSessionSummary {
    param([string]$ProjectRoot)

    $path = Get-HIAActiveSessionPath -ProjectRoot $ProjectRoot
    $legacy = Join-Path (Get-HIASessionsDir -ProjectRoot $ProjectRoot) "SESSION.ACTIVE.json"

    $result = [ordered]@{
        status = "none"
        session_id = "NONE"
        started_utc = "NONE"
        path = $path
    }

    $candidate = $null
    if (Test-Path -LiteralPath $path) {
        $candidate = $path
    }
    elseif (Test-Path -LiteralPath $legacy) {
        $candidate = $legacy
        $result.path = $legacy
    }
    else {
        return $result
    }

    try {
        $session = Get-Content -LiteralPath $candidate -Raw | ConvertFrom-Json
        $status = [string]$session.status
        if ([string]::IsNullOrWhiteSpace($status)) { $status = "active" }
        $id = [string]$session.id
        if ([string]::IsNullOrWhiteSpace($id)) { $id = [string]$session.session_id }

        $started = [string]$session.started_utc
        if ([string]::IsNullOrWhiteSpace($started)) { $started = [string]$session.started_at_utc }
        if ([string]::IsNullOrWhiteSpace($started)) { $started = [string]$session.started_at }

        $result.status = $status
        $result.session_id = $(if ([string]::IsNullOrWhiteSpace($id)) { "UNKNOWN" } else { $id })
        $result.started_utc = $(if ([string]::IsNullOrWhiteSpace($started)) { "UNKNOWN" } else { $started })
        return $result
    }
    catch {
        $result.status = "unknown"
        $result.session_id = "UNKNOWN"
        $result.started_utc = "UNKNOWN"
        return $result
    }
}

function Write-HIAInteractiveHeader {
    param(
        [string]$ProjectRoot,
        [object]$StateLive,
        [object]$SessionSummary
    )

    try { Clear-Host } catch { }

    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " HIA — Human Intelligence Amplifier :: Guided Interactive CLI (MB-1.1)" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host (" ROOT:        {0}" -f $ProjectRoot)
    Write-Host (" MVP ACTIVO:  {0}" -f ($StateLive.mvp_activo -replace "\r?\n", " / "))
    Write-Host (" PROX PASO:   {0}" -f ($StateLive.proximo_paso -replace "\r?\n", " / "))
    Write-Host (" SESION:      {0} :: {1}" -f $SessionSummary.status, $SessionSummary.session_id)
    Write-Host (" STATE LIVE:  {0}" -f $(if ($StateLive.exists) { "OK" } else { "MISSING" }))
    Write-Host (" LIVE TS:     {0}" -f $StateLive.generated_local)
    Write-Host (" NOW:         {0}" -f (Get-HIAInteractiveTimestamp))
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Selecciona opcion (numero) • F1=Ayuda • X=Volver • 0=Salir (menu principal)" -ForegroundColor DarkGray
    Write-Host ""
}

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

    return (Read-Host -Prompt $Prompt)
}

function Pause-HIAInteractive {
    param([System.Collections.Generic.Queue[string]]$ReplayQueue)
    $null = Read-HIAInteractiveInput -Prompt " Enter para continuar..." -ReplayQueue $ReplayQueue
}

function Invoke-HIAInteractiveAction {
    param(
        [string]$ProjectRoot,
        [string]$Command,
        [string[]]$CommandArgs,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    try {
        Write-Host ""
        Write-Host ("==> hia {0} {1}" -f $Command, ($CommandArgs -join " ")) -ForegroundColor Cyan
        Write-Host ""

        Remove-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        Invoke-HIARouter -Command $Command -Args $CommandArgs

        $exitCode = 0
        $lastExit = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        if ($null -ne $lastExit) {
            $exitCode = [int]$lastExit
        }

        Write-Host ""
        if ($exitCode -eq 0) {
            Write-Host "RESULT: OK" -ForegroundColor Green
        }
        else {
            Write-Host ("RESULT: FAIL (exit {0})" -f $exitCode) -ForegroundColor Yellow
        }
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "ERROR: Accion fallo." -ForegroundColor Red
        Write-Host ("MESSAGE: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ""
    }
    finally {
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
    }
}

function Invoke-HIAWebExport {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    $scriptPath = Join-Path $ProjectRoot "02_TOOLS\HIA_WEB_CONSOLE_EXPORT.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Host "ERROR: Web export script not found." -ForegroundColor Red
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
        return
    }

    try {
        Write-Host ""
        Write-Host "EXPORTANDO DATA PARA CONSOLA WEB..." -ForegroundColor Cyan
        & $scriptPath -ProjectRoot $ProjectRoot
        Write-Host "RESULT: OK" -ForegroundColor Green
    }
    catch {
        Write-Host "RESULT: FAIL" -ForegroundColor Red
        Write-Host ("MESSAGE: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
    finally {
        Write-Host ""
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
    }
}

function Test-HIALocalhostPortInUse {
    param([int]$Port)
    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $async = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(250)
        if (-not $ok) {
            $client.Close()
            return $false
        }
        $client.EndConnect($async)
        $client.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-HIAWebServe {
    param(
        [string]$ProjectRoot,
        [int]$Port,
        [switch]$RunExport,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    $scriptPath = Join-Path $ProjectRoot "02_TOOLS\HIA_WEB_CONSOLE_SERVE.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Host "ERROR: Web serve script not found." -ForegroundColor Red
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
        return
    }

    $url = "http://localhost:$Port/"
    if (Test-HIALocalhostPortInUse -Port $Port) {
        Write-Host ""
        Write-Host "SERVER YA PARECE ACTIVO." -ForegroundColor Yellow
        Write-Host ("URL: {0}" -f $url)
        Write-Host ""
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
        return
    }

    $quotedScript = ('"{0}"' -f $scriptPath)
    $argString = "-NoProfile -ExecutionPolicy Bypass -File $quotedScript -Port $Port"
    if ($RunExport) { $argString += " -RunExport" }

    try {
        Write-Host ""
        Write-Host ("LEVANTANDO SERVIDOR: {0}" -f $url) -ForegroundColor Cyan
        Start-Process -FilePath "pwsh" -ArgumentList $argString -WorkingDirectory $ProjectRoot | Out-Null
        Start-Sleep -Milliseconds 250

        if (Test-HIALocalhostPortInUse -Port $Port) {
            Write-Host "RESULT: OK" -ForegroundColor Green
            Write-Host ("URL: {0}" -f $url)
        }
        else {
            Write-Host "RESULT: UNKNOWN" -ForegroundColor Yellow
            Write-Host ("No se pudo confirmar el puerto. Reintenta abrir: {0}" -f $url) -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "RESULT: FAIL" -ForegroundColor Red
        Write-Host ("MESSAGE: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
    finally {
        Write-Host ""
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
    }
}

function Invoke-HIAOpenUrl {
    param(
        [string]$Url,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    try {
        Write-Host ""
        Write-Host ("ABRIENDO: {0}" -f $Url) -ForegroundColor Cyan
        Start-Process $Url | Out-Null
        Write-Host "RESULT: OK" -ForegroundColor Green
    }
    catch {
        Write-Host "RESULT: FAIL" -ForegroundColor Yellow
        Write-Host ("No se pudo abrir automatico. Abre manual: {0}" -f $Url) -ForegroundColor Yellow
        Write-Host ("DETAILS: {0}" -f $_.Exception.Message) -ForegroundColor DarkGray
    }
    finally {
        Write-Host ""
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
    }
}

function Show-HIAHelpMainMenu {
    Write-Host ""
    Write-Host "AYUDA — Menu principal" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1  Estado del proyecto (solo lectura)."
    Write-Host "2  Continuar operacion guiada (sugerencias seguras)."
    Write-Host "3  Sesion (start/status/log/close)."
    Write-Host "4  Planes y minibattles (lectura de artifacts)."
    Write-Host "5  Consola web (export/serve/open)."
    Write-Host "6  Herramientas tecnicas (radar/validate/smoke/state sync)."
    Write-Host ""
    Write-Host "Navegacion:" -ForegroundColor Yellow
    Write-Host "  F1 = ayuda"
    Write-Host "  X  = volver (submenus)"
    Write-Host "  0  = salir (menu principal)"
    Write-Host ""
}

function Show-HIAHelpSubMenu {
    param([string]$Title)
    Write-Host ""
    Write-Host ("AYUDA — {0}" -f $Title) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opciones numericas ejecutan acciones reales."
    Write-Host "X vuelve al menu anterior."
    Write-Host "F1 muestra esta ayuda."
    Write-Host ""
}

function Show-HIAHelpTechToolsExtra {
    Write-Host "Acciones:" -ForegroundColor Yellow
    Write-Host "- AI Stack Check: valida disponibilidad de Codex/Claude Code/Ollama/OpenCode."
    Write-Host "  CLI directa: hia stack"
    Write-Host "- AI Task Dispatch: recomienda herramienta por TaskType segun playbooks."
    Write-Host "  CLI directa: hia ai <tasktype>"
    Write-Host "- AI Prompt Packs: resuelve prompt/contract por tool+tasktype."
    Write-Host "  CLI directa: hia ai prompt <tool> <tasktype>"
    Write-Host ""
}

function Show-HIAProjectStatusView {
    param(
        [string]$ProjectRoot,
        [object]$StateLive,
        [object]$SessionSummary
    )

    Write-Host ""
    Write-Host "ESTADO GENERAL" -ForegroundColor Yellow
    Write-Host ("- STATE LIVE:      {0}" -f $(if ($StateLive.exists) { "OK" } else { "MISSING" }))
    Write-Host ("- MVP ACTIVO:      {0}" -f ($StateLive.mvp_activo -replace "\r?\n", " / "))
    Write-Host ("- FOCO ACTUAL:     {0}" -f ($StateLive.foco_actual -replace "\r?\n", " / "))
    Write-Host ("- PROXIMO PASO:    {0}" -f ($StateLive.proximo_paso -replace "\r?\n", " / "))
    Write-Host ("- ULTIMO RADAR:    {0}" -f $StateLive.ultimo_radar)
    Write-Host ("- ULTIMA ACTIV.:   {0}" -f $StateLive.ultima_actividad)
    Write-Host ("- SESION:          {0} :: {1}" -f $SessionSummary.status, $SessionSummary.session_id)
    Write-Host ""

    $sessionsDir = Get-HIASessionsDir -ProjectRoot $ProjectRoot
    if (Test-Path -LiteralPath $sessionsDir) {
        $latest = Get-ChildItem -LiteralPath $sessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($latest) {
            Write-Host "ULTIMA SESION (archivo)" -ForegroundColor Yellow
            Write-Host ("- {0} ({1})" -f $latest.Name, $latest.LastWriteTime)
            Write-Host ""
        }
    }
}

function Get-HIAPlansSummaryLines {
    param([string]$ProjectRoot)
    $plansDir = Get-HIAPlansDir -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $plansDir)) {
        return @("Plans dir not found: $plansDir")
    }

    $files = Get-ChildItem -LiteralPath $plansDir -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    if (-not $files -or $files.Count -eq 0) {
        return @("No plan files found in: $plansDir")
    }

    $top = $files | Select-Object -First 10
    $lines = @("TOTAL: $($files.Count)", "MOST RECENT:")
    foreach ($f in $top) {
        $lines += ("- {0} :: {1}" -f $f.Name, $f.LastWriteTime)
    }
    return $lines
}

function Show-HIAGuidedOperation {
    param(
        [string]$ProjectRoot,
        [object]$StateLive,
        [object]$SessionSummary
    )

    Write-Host ""
    Write-Host "OPERACION GUIADA (SIN IA GENERATIVA)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "FOCO ACTUAL:" -ForegroundColor Cyan
    Write-Host ($StateLive.foco_actual)
    Write-Host ""
    Write-Host "PROXIMO PASO:" -ForegroundColor Cyan
    Write-Host ($StateLive.proximo_paso)
    Write-Host ""

    $suggestions = New-Object System.Collections.Generic.List[object]

    if (-not $StateLive.exists) {
        $suggestions.Add([ordered]@{ label = "Generar STATE LIVE (state sync)"; action = "state sync"; kind = "router" })
    }
    else {
        if ($StateLive.ultimo_radar -eq "UNKNOWN" -or $StateLive.ultimo_radar -eq "NONE") {
            $suggestions.Add([ordered]@{ label = "Ejecutar RADAR (indice)"; action = "radar"; kind = "router" })
        }
        if ($StateLive.ultima_actividad -eq "UNKNOWN" -or $StateLive.ultima_actividad -eq "NONE") {
            $suggestions.Add([ordered]@{ label = "Sincronizar estado (state sync)"; action = "state sync"; kind = "router" })
        }
    }

    if ($SessionSummary.status -eq "none" -or $SessionSummary.status -eq "closed") {
        $suggestions.Add([ordered]@{ label = "Iniciar sesion (session start)"; action = "session start"; kind = "router" })
    }
    elseif ($SessionSummary.status -eq "active") {
        $suggestions.Add([ordered]@{ label = "Agregar log a sesion"; action = "session log"; kind = "submenu" })
        $suggestions.Add([ordered]@{ label = "Validar (validate)"; action = "validate"; kind = "router" })
    }

    if ($suggestions.Count -eq 0) {
        $suggestions.Add([ordered]@{ label = "Ver estado del proyecto"; action = "status"; kind = "submenu" })
    }

    Write-Host "SUGERENCIAS SEGURAS:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $suggestions.Count; $i++) {
        Write-Host ("  {0}.- {1}" -f ($i + 1), $suggestions[$i].label)
    }
    Write-Host "  X.- Volver"
    Write-Host ""
}

function Invoke-HIAInteractiveSessionLogFlow {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    $message = Read-HIAInteractiveInput -Prompt " Mensaje para log: " -ReplayQueue $ReplayQueue
    if ([string]::IsNullOrWhiteSpace($message)) {
        Write-Host "CANCELLED: Mensaje vacio." -ForegroundColor Yellow
        Pause-HIAInteractive -ReplayQueue $ReplayQueue
        return
    }

    Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "session" -CommandArgs @("log", "-Message", $message) -ReplayQueue $ReplayQueue
}

function Show-HIAInteractiveMainMenu {
    Write-Host "HIA — Menu principal" -ForegroundColor Yellow
    Write-Host "1.- Ver estado del proyecto"
    Write-Host "2.- Continuar operacion guiada"
    Write-Host "3.- Sesion"
    Write-Host "4.- Planes y minibattles"
    Write-Host "5.- Consola web"
    Write-Host "6.- Herramientas tecnicas"
    Write-Host "F1.- Ayuda"
    Write-Host "0.- Salir"
    Write-Host ""
}

function Show-HIAInteractiveSubMenu {
    param(
        [string]$Title,
        [string[]]$Lines
    )
    Write-Host ("{0}" -f $Title) -ForegroundColor Yellow
    foreach ($l in $Lines) { Write-Host $l }
    Write-Host ""
}

function Invoke-HIAInteractiveMenuState {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveSubMenu -Title "A) Estado del proyecto" -Lines @(
            "1.- Ver estatus general",
            "2.- Ver MVP activo y proximo paso",
            "3.- Ver ultima sesion",
            "4.- Ver fuentes activas",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" { Show-HIAHelpSubMenu -Title "Estado del proyecto"; Pause-HIAInteractive -ReplayQueue $ReplayQueue; continue }
            "1" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "state" -CommandArgs @("show") -ReplayQueue $ReplayQueue }
            "2" {
                Write-Host ""
                Write-Host "MVP ACTIVO:" -ForegroundColor Yellow
                Write-Host $stateLive.mvp_activo
                Write-Host ""
                Write-Host "PROXIMO PASO:" -ForegroundColor Yellow
                Write-Host $stateLive.proximo_paso
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            "3" {
                $sessionsDir = Get-HIASessionsDir -ProjectRoot $ProjectRoot
                Write-Host ""
                if (-not (Test-Path -LiteralPath $sessionsDir)) {
                    Write-Host "No sessions dir." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                $latest = Get-ChildItem -LiteralPath $sessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if (-not $latest) {
                    Write-Host "No session summaries found yet." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                Write-Host ("ULTIMA SESION: {0}" -f $latest.Name) -ForegroundColor Yellow
                Write-Host ("PATH: {0}" -f $latest.FullName)
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            "4" {
                Write-Host ""
                Write-Host "FUENTES ACTIVAS (artefactos)" -ForegroundColor Yellow
                Write-Host ("- STATE LIVE: {0}" -f $stateLive.live_path)
                Write-Host ("- SESSIONS:   {0}" -f (Get-HIASessionsDir -ProjectRoot $ProjectRoot))
                Write-Host ("- PLANS:      {0}" -f (Get-HIAPlansDir -ProjectRoot $ProjectRoot))
                Write-Host ("- LOGS:       {0}" -f (Join-Path $ProjectRoot "03_ARTIFACTS\\logs"))
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            default { Write-Host "Seleccion invalida. Usa numero, F1, X." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveMenuSession {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveSubMenu -Title "C) Sesion" -Lines @(
            "1.- Iniciar sesion",
            "2.- Ver sesion actual",
            "3.- Agregar log a sesion",
            "4.- Cerrar sesion",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" { Show-HIAHelpSubMenu -Title "Sesion"; Pause-HIAInteractive -ReplayQueue $ReplayQueue; continue }
            "1" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "session" -CommandArgs @("start") -ReplayQueue $ReplayQueue }
            "2" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "session" -CommandArgs @("status") -ReplayQueue $ReplayQueue }
            "3" { Invoke-HIAInteractiveSessionLogFlow -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "4" {
                $msg = Read-HIAInteractiveInput -Prompt " Summary (opcional): " -ReplayQueue $ReplayQueue
                $args = @("close")
                if (-not [string]::IsNullOrWhiteSpace($msg)) {
                    $args += @("-Message", $msg)
                }
                Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "session" -CommandArgs $args -ReplayQueue $ReplayQueue
            }
            default { Write-Host "Seleccion invalida." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveMenuPlans {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveSubMenu -Title "D) Planes y minibattles" -Lines @(
            "1.- Ver planes",
            "2.- Ver plan actual (mas reciente)",
            "3.- Ver minibattle actual (desde STATE LIVE)",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" { Show-HIAHelpSubMenu -Title "Planes y minibattles"; Pause-HIAInteractive -ReplayQueue $ReplayQueue; continue }
            "1" {
                Write-Host ""
                Write-Host "PLANES (TOP 10)" -ForegroundColor Yellow
                (Get-HIAPlansSummaryLines -ProjectRoot $ProjectRoot) | ForEach-Object { Write-Host $_ }
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            "2" {
                Write-Host ""
                $plansDir = Get-HIAPlansDir -ProjectRoot $ProjectRoot
                if (-not (Test-Path -LiteralPath $plansDir)) {
                    Write-Host "Plans dir not found." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                $latest = Get-ChildItem -LiteralPath $plansDir -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if (-not $latest) {
                    Write-Host "No plan files found." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                Write-Host ("PLAN ACTUAL (archivo): {0}" -f $latest.Name) -ForegroundColor Yellow
                Write-Host ("PATH: {0}" -f $latest.FullName)
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            "3" {
                Write-Host ""
                Write-Host "MINIBATTLE ACTUAL / PROXIMO PASO:" -ForegroundColor Yellow
                Write-Host $stateLive.proximo_paso
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            default { Write-Host "Seleccion invalida." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveMenuTools {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveSubMenu -Title "F) Herramientas tecnicas" -Lines @(
            "1.- Radar",
            "2.- Validate",
            "3.- Smoke",
            "4.- State Sync",
            "5.- AI Stack Check",
            "6.- AI Task Dispatch",
            "7.- AI Prompt Packs",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" { Show-HIAHelpSubMenu -Title "Herramientas tecnicas"; Show-HIAHelpTechToolsExtra; Pause-HIAInteractive -ReplayQueue $ReplayQueue; continue }
            "1" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "radar" -CommandArgs @() -ReplayQueue $ReplayQueue }
            "2" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "validate" -CommandArgs @() -ReplayQueue $ReplayQueue }
            "3" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "smoke" -CommandArgs @() -ReplayQueue $ReplayQueue }
            "4" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "state" -CommandArgs @("sync") -ReplayQueue $ReplayQueue }
            "5" { Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "stack" -CommandArgs @() -ReplayQueue $ReplayQueue }
            "6" {
                Write-Host ""
                Write-Host "AI TASK DISPATCH" -ForegroundColor Yellow
                Write-Host "TaskTypes: architecture, repo_read, code_change, refactor, validation, audit, docs, quick_local, fallback, cost_sensitive, high_risk_change"
                Write-Host ""
                $tt = Read-HIAInteractiveInput -Prompt " TaskType: " -ReplayQueue $ReplayQueue
                if ([string]::IsNullOrWhiteSpace($tt)) {
                    Write-Host "CANCELLED." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "ai" -CommandArgs @($tt.Trim()) -ReplayQueue $ReplayQueue
            }
            "7" {
                Write-Host ""
                Write-Host "AI PROMPT PACKS" -ForegroundColor Yellow
                Write-Host "Tools: codex, claude_code, chatgpt, claude_cloud, ollama, opencode"
                Write-Host "TaskTypes: architecture, repo_read, code_change, refactor, validation, audit, docs, quick_local, fallback, cost_sensitive, high_risk_change"
                Write-Host ""
                $tool = Read-HIAInteractiveInput -Prompt " Tool: " -ReplayQueue $ReplayQueue
                $tt = Read-HIAInteractiveInput -Prompt " TaskType: " -ReplayQueue $ReplayQueue
                if ([string]::IsNullOrWhiteSpace($tool) -or [string]::IsNullOrWhiteSpace($tt)) {
                    Write-Host "CANCELLED." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command "ai" -CommandArgs @("prompt", $tool.Trim(), $tt.Trim()) -ReplayQueue $ReplayQueue
            }
            default { Write-Host "Seleccion invalida." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveMenuWeb {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        $defaultPort = 8080
        $url = "http://localhost:$defaultPort/"

        Show-HIAInteractiveSubMenu -Title "E) Consola web" -Lines @(
            "1.- Exportar datos",
            "2.- Levantar servidor local (puerto $defaultPort)",
            "3.- Abrir consola web (navegador)",
            "4.- Mostrar URL activa / instruccion",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" {
                Show-HIAHelpSubMenu -Title "Consola web"
                Write-Host "Notas:" -ForegroundColor Yellow
                Write-Host "- Export genera `01_UI\\web\\data\\console-data.json`."
                Write-Host ("- Serve levanta `02_TOOLS\\HIA_WEB_CONSOLE_SERVE.ps1` en {0}" -f $url)
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            "1" { Invoke-HIAWebExport -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "2" {
                $doExport = Read-HIAInteractiveInput -Prompt " Export antes de servir? (Y/N): " -ReplayQueue $ReplayQueue
                $runExport = $doExport.Trim().ToUpperInvariant() -eq "Y"
                Invoke-HIAWebServe -ProjectRoot $ProjectRoot -Port $defaultPort -RunExport:([bool]$runExport) -ReplayQueue $ReplayQueue
            }
            "3" {
                if (-not (Test-HIALocalhostPortInUse -Port $defaultPort)) {
                    Write-Host ""
                    Write-Host "Servidor no confirmado en el puerto." -ForegroundColor Yellow
                    Write-Host "Sugerencia: levanta servidor (opcion 2) y reintenta." -ForegroundColor Yellow
                    Write-Host ("URL: {0}" -f $url)
                    Write-Host ""
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                    continue
                }
                Invoke-HIAOpenUrl -Url $url -ReplayQueue $ReplayQueue
            }
            "4" {
                Write-Host ""
                Write-Host "URL CONSOLA WEB:" -ForegroundColor Yellow
                Write-Host ("- {0}" -f $url)
                Write-Host ""
                Write-Host "Si no abre, ejecuta:" -ForegroundColor Yellow
                Write-Host ("  pwsh -NoProfile -File `"{0}`" -Port {1} -RunExport" -f (Join-Path $ProjectRoot "02_TOOLS\\HIA_WEB_CONSOLE_SERVE.ps1"), $defaultPort)
                Write-Host ""
                Pause-HIAInteractive -ReplayQueue $ReplayQueue
            }
            default { Write-Host "Seleccion invalida." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveMenuGuided {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveSubMenu -Title "B) Operacion guiada" -Lines @(
            "1.- Mostrar foco actual",
            "2.- Mostrar proximo paso",
            "3.- Sugerir siguiente accion operativa segura",
            "4.- Ir a sesion",
            "5.- Ir a planes y minibattles",
            "6.- Ir a consola web",
            "7.- Ir a herramientas tecnicas",
            "F1.- Ayuda",
            "X.- Volver"
        )

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "X" { return }
            "F1" { Show-HIAHelpSubMenu -Title "Operacion guiada"; Pause-HIAInteractive -ReplayQueue $ReplayQueue; continue }
            "1" { Write-Host ""; Write-Host "FOCO ACTUAL:" -ForegroundColor Yellow; Write-Host $stateLive.foco_actual; Write-Host ""; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
            "2" { Write-Host ""; Write-Host "PROXIMO PASO:" -ForegroundColor Yellow; Write-Host $stateLive.proximo_paso; Write-Host ""; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
            "3" {
                Show-HIAGuidedOperation -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session
                $pick = (Read-HIAInteractiveInput -Prompt " Elegir sugerencia (1/2..) o X: " -ReplayQueue $ReplayQueue).Trim()
                if ($pick.ToUpperInvariant() -eq "X") { continue }

                if ($pick -match '^\d+$') {
                    $idx = [int]$pick - 1
                    $suggestions = New-Object System.Collections.Generic.List[object]

                    if (-not $stateLive.exists) {
                        $suggestions.Add([ordered]@{ label = "Generar STATE LIVE (state sync)"; action = "state sync"; kind = "router" })
                    }
                    else {
                        if ($stateLive.ultimo_radar -eq "UNKNOWN" -or $stateLive.ultimo_radar -eq "NONE") {
                            $suggestions.Add([ordered]@{ label = "Ejecutar RADAR (indice)"; action = "radar"; kind = "router" })
                        }
                        if ($stateLive.ultima_actividad -eq "UNKNOWN" -or $stateLive.ultima_actividad -eq "NONE") {
                            $suggestions.Add([ordered]@{ label = "Sincronizar estado (state sync)"; action = "state sync"; kind = "router" })
                        }
                    }

                    if ($session.status -eq "none" -or $session.status -eq "closed") {
                        $suggestions.Add([ordered]@{ label = "Iniciar sesion (session start)"; action = "session start"; kind = "router" })
                    }
                    elseif ($session.status -eq "active") {
                        $suggestions.Add([ordered]@{ label = "Agregar log a sesion"; action = "session log"; kind = "submenu" })
                        $suggestions.Add([ordered]@{ label = "Validar (validate)"; action = "validate"; kind = "router" })
                    }

                    if ($suggestions.Count -eq 0) {
                        $suggestions.Add([ordered]@{ label = "Ver estado del proyecto"; action = "status"; kind = "submenu" })
                    }

                    if ($idx -lt 0 -or $idx -ge $suggestions.Count) {
                        Write-Host "Seleccion invalida." -ForegroundColor Yellow
                        Pause-HIAInteractive -ReplayQueue $ReplayQueue
                        continue
                    }

                    $choice = $suggestions[$idx]
                    $action = [string]$choice.action
                    if ($choice.kind -eq "router") {
                        $parts = @($action.Split(" ", [StringSplitOptions]::RemoveEmptyEntries))
                        $cmd = $parts[0]
                        $args = @()
                        if ($parts.Count -gt 1) { $args = $parts[1..($parts.Count - 1)] }
                        Invoke-HIAInteractiveAction -ProjectRoot $ProjectRoot -Command $cmd -CommandArgs $args -ReplayQueue $ReplayQueue
                        continue
                    }
                    if ($action -eq "session log") {
                        Invoke-HIAInteractiveSessionLogFlow -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue
                        continue
                    }

                    Write-Host "No action bound." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                }
                else {
                    Write-Host "Seleccion invalida." -ForegroundColor Yellow
                    Pause-HIAInteractive -ReplayQueue $ReplayQueue
                }
            }
            "4" { Invoke-HIAInteractiveMenuSession -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "5" { Invoke-HIAInteractiveMenuPlans -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "6" { Invoke-HIAInteractiveMenuWeb -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "7" { Invoke-HIAInteractiveMenuTools -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            default { Write-Host "Seleccion invalida." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveLoop {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    while ($true) {
        $stateLive = Read-HIAProjectStateLive -ProjectRoot $ProjectRoot
        $session = Read-HIAActiveSessionSummary -ProjectRoot $ProjectRoot
        Write-HIAInteractiveHeader -ProjectRoot $ProjectRoot -StateLive $stateLive -SessionSummary $session

        Show-HIAInteractiveMainMenu

        $sel = (Read-HIAInteractiveInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()
        switch ($sel.ToUpperInvariant()) {
            "0" { return }
            "F1" { Show-HIAHelpMainMenu; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
            "1" { Invoke-HIAInteractiveMenuState -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "2" { Invoke-HIAInteractiveMenuGuided -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "3" { Invoke-HIAInteractiveMenuSession -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "4" { Invoke-HIAInteractiveMenuPlans -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "5" { Invoke-HIAInteractiveMenuWeb -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            "6" { Invoke-HIAInteractiveMenuTools -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue }
            default { Write-Host "Seleccion invalida. Usa 1-6, F1 o 0." -ForegroundColor Yellow; Pause-HIAInteractive -ReplayQueue $ReplayQueue }
        }
    }
}

function Invoke-HIAInteractiveEntrypoint {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    $root = Get-HIAProjectRootFromEntrypoint -ProjectRoot $ProjectRoot

    $queue = $ReplayQueue
    if (-not $queue) {
        $replayPath = $env:HIA_INTERACTIVE_REPLAY
        $queue = Get-HIAReplayQueue -ReplayPath $replayPath
        if ($queue) {
            Write-Host ("[REPLAY MODE] Using HIA_INTERACTIVE_REPLAY: {0}" -f $replayPath) -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 250
        }
    }

    Invoke-HIAInteractiveLoop -ProjectRoot $root -ReplayQueue $queue
}

# -----------------------------------------------------------------------------
# FUTURE MB EXTENSIONS (STUBS ONLY - NOT WIRED INTO MAIN MENU)
# -----------------------------------------------------------------------------

function Get-HIAProjectsStub {
    param([string]$PortfolioRoot)
    throw "NOT IMPLEMENTED (MB future): Project selector / portfolio shell."
}

function New-HIAProjectStub {
    param([string]$ProjectId)
    throw "NOT IMPLEMENTED (MB future): Create project wizard."
}

function Open-HIAVaultStub {
    param([string]$VaultRoot)
    throw "NOT IMPLEMENTED (MB future): Vault shell."
}
