<#
===============================================================================
MODULE: HIA_AI_DISPATCH_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: AI TASK DISPATCH (MB-1.5)
===============================================================================

OBJETIVO
Despachar tareas IA por TaskType usando playbooks canónicos y disponibilidad real
del stack (vía `hia stack -Json` / HIA_TOL_0043_Check-AIStack.ps1).

NO IMPLEMENTA
- runtime multiagente
- ejecución paralela
- auto-apply / auto-commit
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) { return $current }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { throw "PROJECT_ROOT not found." }
        $current = $parent
    }
}

function Get-HIAStackCheckPath {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "02_TOOLS\\Maintenance\\HIA_TOL_0043_Check-AIStack.ps1")
}

function Get-HIAPlaybooksPath {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "00_FRAMEWORK\\HIA_RTG_0004_AI.EXECUTION.PLAYBOOKS.txt")
}

function Read-HIAStackStatus {
    param([string]$ProjectRoot)

    $checkPath = Get-HIAStackCheckPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $checkPath)) {
        return $null
    }

    try {
        $json = & $checkPath -Json 2>$null | Out-String
        if ([string]::IsNullOrWhiteSpace($json)) { return $null }
        return ($json | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Get-HIAStackComponentStates {
    param(
        [object]$StackStatus,
        [string]$ComponentName
    )
    if ($null -eq $StackStatus) { return $null }
    foreach ($row in @($StackStatus.rows)) {
        if ([string]$row.component -eq $ComponentName) {
            return $row.states
        }
    }
    return $null
}

function Get-HIAProviderReadiness {
    param(
        [object]$StackStatus,
        [string]$Provider
    )

    # Providers that are not local executables in HIA are "guidance-only".
    if ($Provider -in @("CHATGPT", "CLAUDE_CLOUD")) {
        return [ordered]@{
            installed = $true
            available = $true
            authenticated = "unknown"
            ready = $true
            evidence = "guidance-only"
        }
    }

    if ($Provider -eq "CODEX") {
        $s = Get-HIAStackComponentStates -StackStatus $StackStatus -ComponentName "Codex CLI"
        return [ordered]@{
            installed = [bool]$s.installed
            available = [bool]$s.available
            authenticated = [string]$s.authenticated
            ready = [bool]$s.ready
            evidence = "stack:Codex CLI"
        }
    }

    if ($Provider -eq "OPENAI_ROUTER") {
        # Use router provider OPENAI (cloud) as guidance-only; real execution may be dry-run.
        $auth = Get-HIAStackComponentStates -StackStatus $StackStatus -ComponentName "OpenAI auth"
        $authed = "unknown"
        if ($auth) { $authed = [string]$auth.authenticated }
        return [ordered]@{
            installed = $true
            available = $true
            authenticated = $authed
            ready = $true
            evidence = "router:OPENAI"
        }
    }

    if ($Provider -eq "CLAUDE_CODE") {
        $s = Get-HIAStackComponentStates -StackStatus $StackStatus -ComponentName "Claude Code"
        return [ordered]@{
            installed = [bool]$s.installed
            available = [bool]$s.available
            authenticated = [string]$s.authenticated
            ready = [bool]$s.ready
            evidence = "stack:Claude Code"
        }
    }

    if ($Provider -eq "OLLAMA") {
        $s = Get-HIAStackComponentStates -StackStatus $StackStatus -ComponentName "Ollama"
        return [ordered]@{
            installed = [bool]$s.installed
            available = [bool]$s.available
            authenticated = [string]$s.authenticated
            ready = [bool]$s.ready
            evidence = "stack:Ollama"
        }
    }

    if ($Provider -eq "OPENCODE") {
        $s = Get-HIAStackComponentStates -StackStatus $StackStatus -ComponentName "OpenCode"
        return [ordered]@{
            installed = [bool]$s.installed
            available = [bool]$s.available
            authenticated = [string]$s.authenticated
            ready = [bool]$s.ready
            evidence = "stack:OpenCode"
        }
    }

    if ($Provider -eq "LOCAL_TOOL") {
        return [ordered]@{
            installed = $true
            available = $true
            authenticated = "n/a"
            ready = $true
            evidence = "always"
        }
    }

    return [ordered]@{
        installed = $false
        available = $false
        authenticated = "unknown"
        ready = $false
        evidence = "unknown-provider"
    }
}

function Get-HIADispatchPolicy {
    # Policy is aligned with 00_FRAMEWORK/HIA_RTG_0004_AI.EXECUTION.PLAYBOOKS.txt
    # (Do not parse the document at runtime; keep this mapping minimal and explicit.)
    return @{
        ARCHITECTURE = @{
            risk_default = "MED"
            primary = "CHATGPT"
            secondary = "CLAUDE_CLOUD"
            fallback = "CODEX"
            no_primary = "No usar QUICK_LOCAL ni modelos locales como sustituto de arquitectura crítica."
            suggest = "Si es HIGH, pide doble revisión (ChatGPT + Claude cloud) y deja decisiones trazables."
            require_second_review = $true
        }
        REPO_READ = @{
            risk_default = "LOW"
            primary = "CLAUDE_CODE"
            secondary = "CHATGPT"
            fallback = "OPENCODE"
            no_primary = "No usar local si el repo es grande y el contexto no cabe; no resumir para decisiones críticas sin 2da revisión."
            suggest = "Si el resumen guía decisiones críticas, pide 2da revisión cloud."
            require_second_review = $false
        }
        CODE_CHANGE = @{
            risk_default = "MED"
            primary = "CLAUDE_CODE"
            secondary = "CODEX"
            fallback = "CHATGPT"
            no_primary = "No despachar dos IAs a escribir el mismo cambio; no aceptar sin validación real."
            suggest = "Tras el cambio, ejecutar validate/smoke según aplique."
            require_second_review = $false
        }
        REFACTOR = @{
            risk_default = "MED"
            primary = "CLAUDE_CODE"
            secondary = "CODEX"
            fallback = "CHATGPT"
            no_primary = "No hacer refactor grande sin tests/validators; Ollama/OpenCode solo si acotado."
            suggest = "Divide refactor en pasos y valida por etapa."
            require_second_review = $false
        }
        VALIDATION = @{
            risk_default = "LOW"
            primary = "LOCAL_TOOL"
            secondary = "CHATGPT"
            fallback = "CODEX"
            no_primary = "No usar cloud para inventar resultados; siempre ejecutar herramientas reales."
            suggest = "Corre `hia validate` o `hia smoke` y usa IA solo para interpretar fallos."
            require_second_review = $false
        }
        AUDIT = @{
            risk_default = "HIGH"
            primary = "CHATGPT"
            secondary = "CLAUDE_CLOUD"
            fallback = "CODEX"
            no_primary = "No usar QUICK_LOCAL como auditoría; no cerrar findings sin revisión humana en HIGH."
            suggest = "En HIGH, exige doble revisión cloud + validación local cuando aplique."
            require_second_review = $true
        }
        DOCS = @{
            risk_default = "LOW"
            primary = "CHATGPT"
            secondary = "CLAUDE_CODE"
            fallback = "CODEX"
            no_primary = "No generar docs operativos críticos sin revisión humana."
            suggest = "Mantén consistencia con documentos canónicos en 00_FRAMEWORK."
            require_second_review = $false
        }
        QUICK_LOCAL = @{
            risk_default = "LOW"
            primary = "LOCAL_TOOL"
            secondary = "OLLAMA"
            fallback = "OPENCODE"
            no_primary = "No usar QUICK_LOCAL para arquitectura o canon."
            suggest = "Usa comandos deterministas; si requiere juicio, escala."
            require_second_review = $false
        }
        FALLBACK = @{
            risk_default = "MED"
            primary = "CHATGPT"
            secondary = "CODEX"
            fallback = "LOCAL_TOOL"
            no_primary = "No continuar a ciegas sin confirmar disponibilidad/ready."
            suggest = "Primero ejecuta `hia stack` para confirmar estado."
            require_second_review = $false
        }
        COST_SENSITIVE = @{
            risk_default = "LOW"
            primary = "OLLAMA"
            secondary = "OPENCODE"
            fallback = "CHATGPT"
            no_primary = "Local no define canon; escala si la calidad no alcanza."
            suggest = "Si el resultado impacta decisiones, escala a cloud."
            require_second_review = $false
        }
        HIGH_RISK_CHANGE = @{
            risk_default = "HIGH"
            primary = "CODEX"
            secondary = "CLAUDE_CODE"
            fallback = "CHATGPT"
            no_primary = "Prohibido usar solo modelo local; requiere 2da revisión + validación real."
            suggest = "Exige doble revisión y corre `hia validate`/`hia smoke`."
            require_second_review = $true
        }
    }
}

function Select-HIADispatchTool {
    param(
        [object]$StackStatus,
        [string[]]$Candidates
    )

    foreach ($c in $Candidates) {
        $r = Get-HIAProviderReadiness -StackStatus $StackStatus -Provider $c
        if ($r.ready) { return $c }
    }

    # If none ready, return first candidate but mark as not ready in decision.
    return $Candidates[0]
}

function Get-HIAActionSuggestion {
    param(
        [string]$SelectedTool,
        [string]$TaskType
    )

    switch ($SelectedTool) {
        "CLAUDE_CODE" { return "Run: hia claude status  (then: hia claude run <args...>)" }
        "OLLAMA" { return "Run: hia ollama status  (then: hia ollama models / hia ollama run <model> <prompt>)" }
        "OPENCODE" { return "Run: opencode --version (then use OpenCode locally as per playbooks)" }
        "CODEX" { return "Use Codex workflow for this TaskType; verify with: hia stack (Codex CLI states)" }
        "LOCAL_TOOL" {
            if ($TaskType -eq "VALIDATION") { return "Run: hia validate  (or: hia smoke)" }
            return "Run deterministic HIA tools (state/session/validate/smoke) as needed."
        }
        "CHATGPT" { return "Use ChatGPT (cloud) following playbooks; capture decisions in session log." }
        "CLAUDE_CLOUD" { return "Use Claude (cloud) for second opinion/review; keep traceability." }
        default { return "Run: hia stack (confirm readiness) then proceed." }
    }
}

function Write-HIADispatchLog {
    param(
        [string]$ProjectRoot,
        [hashtable]$Decision
    )

    $logDir = Join-Path $ProjectRoot "03_ARTIFACTS\\LOGS"
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $logPath = Join-Path $logDir "HIA_AI_DISPATCH.log"
    $line = "{0} | tasktype={1} | risk={2} | selected={3} | primary={4} | secondary={5} | fallback={6} | degraded={7}" -f `
        ((Get-Date).ToUniversalTime().ToString("o")),
        $Decision.tasktype,
        $Decision.risk,
        $Decision.selected_tool,
        $Decision.primary,
        $Decision.secondary,
        $Decision.fallback,
        $Decision.degraded

    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

function Invoke-HIAAiDispatch {
    param(
        [string]$TaskType,
        [string]$Risk = ""
    )

    if ([string]::IsNullOrWhiteSpace($TaskType)) { throw "TaskType required." }

    $projectRoot = Get-HIAProjectRoot
    $playbooksPath = Get-HIAPlaybooksPath -ProjectRoot $projectRoot
    $stack = Read-HIAStackStatus -ProjectRoot $projectRoot

    $policy = Get-HIADispatchPolicy
    $tt = $TaskType.ToUpperInvariant()
    if (-not $policy.ContainsKey($tt)) {
        throw "Unknown TaskType '$TaskType'. Supported: $(@($policy.Keys) -join ', ')"
    }

    $entry = $policy[$tt]
    $riskFinal = if ([string]::IsNullOrWhiteSpace($Risk)) { [string]$entry.risk_default } else { $Risk.ToUpperInvariant() }

    $primary = [string]$entry.primary
    $secondary = [string]$entry.secondary
    $fallback = [string]$entry.fallback

    $candidates = @($primary, $secondary, $fallback)
    $selected = Select-HIADispatchTool -StackStatus $stack -Candidates $candidates

    $degraded = $selected -ne $primary
    $primaryReady = (Get-HIAProviderReadiness -StackStatus $stack -Provider $primary).ready
    $selectedReady = (Get-HIAProviderReadiness -StackStatus $stack -Provider $selected).ready

    $decision = [ordered]@{
        tasktype = $tt
        risk = $riskFinal
        primary = $primary
        secondary = $secondary
        fallback = $fallback
        selected_tool = $selected
        degraded = $degraded
        primary_ready = $primaryReady
        selected_ready = $selectedReady
        no_primary = [string]$entry.no_primary
        require_second_review = [bool]$entry.require_second_review
        next_action = (Get-HIAActionSuggestion -SelectedTool $selected -TaskType $tt)
        playbooks = [ordered]@{
            canonical_file = $playbooksPath
        }
        generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    }

    Write-HIADispatchLog -ProjectRoot $projectRoot -Decision $decision

    Write-Host ""
    Write-Host "HIA AI DISPATCH" -ForegroundColor Cyan
    Write-Host ("TASKTYPE: {0}" -f $decision.tasktype)
    Write-Host ("RISK:     {0}" -f $decision.risk)
    Write-Host ("PRIMARY:  {0} (ready={1})" -f $decision.primary, $decision.primary_ready)
    Write-Host ("SECOND:   {0}" -f $decision.secondary)
    Write-Host ("FALLBACK: {0}" -f $decision.fallback)
    Write-Host ("SELECTED: {0} (ready={1})" -f $decision.selected_tool, $decision.selected_ready)
    if ($decision.degraded) {
        Write-Host "NOTE: Primary not ready; degraded to secondary/fallback." -ForegroundColor Yellow
    }
    if ($decision.require_second_review -and $decision.risk -eq "HIGH") {
        Write-Host "RULE: HIGH_RISK requires second review + validation real." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "DO NOT USE PRIMARY WHEN:" -ForegroundColor Yellow
    Write-Host ("- {0}" -f $decision.no_primary)
    Write-Host ""
    Write-Host "NEXT ACTION:" -ForegroundColor Yellow
    Write-Host ("- {0}" -f $decision.next_action)
    Write-Host ""
    Write-Host ("TRACE: 03_ARTIFACTS\\LOGS\\HIA_AI_DISPATCH.log") -ForegroundColor DarkGray
    Write-Host ("PLAYBOOKS: {0}" -f $playbooksPath) -ForegroundColor DarkGray
    Write-Host ""

    return $decision
}
