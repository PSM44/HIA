<#
===============================================================================
MODULE: HIA_AI_ROUTER.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: AI ROUTER ENGINE

OBJETIVO
Route tasks using MODEL.ROUTING.REGISTRY.json policy.

COMMANDS:
- route
- show-policy

VERSION: v0.2
DATE: 2026-03-26
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "route",

    [Parameter(Mandatory = $false)]
    [Alias("task_type")]
    [string]$TaskType,

    [Parameter(Mandatory = $false)]
    [Alias("task_prompt")]
    [string]$TaskPrompt
    ,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
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

function Get-HIAModelRoutingRegistryPath {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "02_TOOLS\MODEL.ROUTING.REGISTRY.json")
}

function Read-HIAModelRoutingRegistry {
    param([string]$RegistryPath)

    if (-not (Test-Path $RegistryPath)) {
        throw "MODEL.ROUTING.REGISTRY.json not found: $RegistryPath"
    }

    return (Get-Content -Path $RegistryPath -Raw | ConvertFrom-Json)
}

function Get-HIATaskType {
    param(
        [string]$ProvidedTaskType,
        [string]$Prompt,
        [string]$DefaultTaskType
    )

    if ($ProvidedTaskType) {
        $t = $ProvidedTaskType.ToUpperInvariant()
        switch ($t) {
            "ARCHITECTURE" { return "ARCHITECTURE" }
            "REPO_READ" { return "REPO_READ" }
            "CODE_CHANGE" { return "CODE_CHANGE" }
            "REFACTOR" { return "REFACTOR" }
            "VALIDATION" { return "VALIDATION" }
            "AUDIT" { return "AUDIT" }
            "DOCS" { return "DOCS" }
            "QUICK_LOCAL" { return "QUICK_LOCAL" }
            "COST_SENSITIVE" { return "COST_SENSITIVE" }
            "HIGH_RISK_CHANGE" { return "HIGH_RISK_CHANGE" }
            "FALLBACK" { return "FALLBACK" }
            default { return $t }
        }
    }

    if (-not $Prompt) {
        return $DefaultTaskType
    }

    $p = $Prompt.ToLowerInvariant()
    if ($p -match '(readme|documentation|document|spec|manual)') { return "DOCS" }
    if ($p -match '(architecture|design|system design|diagram)') { return "ARCHITECTURE" }
    if ($p -match '(audit|investigate|diagnostic|security)') { return "AUDIT" }
    if ($p -match '(validate|validator|test|smoke)') { return "VALIDATION" }
    if ($p -match '(refactor)') { return "REFACTOR" }
    if ($p -match '(code change|implement|fix bug|bug|powershell|python|function)') { return "CODE_CHANGE" }
    if ($p -match '(read repo|repo read|scan repo|summarize repo)') { return "REPO_READ" }
    if ($p -match '(run|execute|tool|command|shell|git)') { return "QUICK_LOCAL" }
    return "REASONING"
}

function Test-HIAProviderAvailability {
    param(
        [psobject]$ProviderConfig
    )

    $source = [string]$ProviderConfig.availability_source
    if (-not $source) {
        return $true
    }

    if ($source -eq "always") {
        return $true
    }

    if ($source.StartsWith("env:", [System.StringComparison]::OrdinalIgnoreCase)) {
        $varName = $source.Substring(4)
        return (-not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($varName)))
    }

    if ($source.StartsWith("command:", [System.StringComparison]::OrdinalIgnoreCase)) {
        $commandName = $source.Substring(8)
        return ($null -ne (Get-Command $commandName -ErrorAction SilentlyContinue))
    }

    if ($source.StartsWith("path:", [System.StringComparison]::OrdinalIgnoreCase)) {
        $path = $source.Substring(5)
        if ([string]::IsNullOrWhiteSpace($path)) { return $false }
        return (Test-Path -LiteralPath $path)
    }

    return $false
}

function Get-HIAPolicyCandidates {
    param(
        [psobject]$Registry,
        [string]$DetectedTaskType
    )

    $providers = @()
    $taskPolicy = $Registry.task_type_policy.($DetectedTaskType)

    if ($taskPolicy -and $taskPolicy.preferred_providers) {
        foreach ($p in $taskPolicy.preferred_providers) {
            $providers += [string]$p
        }
    }

    if ($providers.Count -eq 0) {
        foreach ($prop in $Registry.providers.PSObject.Properties) {
            $providerName = $prop.Name
            $preferredFor = @($prop.Value.preferred_for)
            if ($preferredFor -contains $DetectedTaskType) {
                $providers += $providerName
            }
        }

        if ($providers.Count -eq 0) {
            $providers += [string]$Registry.defaults.provider
        }
    }

    # Make unique while preserving order
    $orderedUnique = New-Object System.Collections.Generic.List[string]
    foreach ($item in $providers) {
        if (-not $orderedUnique.Contains($item)) {
            $null = $orderedUnique.Add($item)
        }
    }

    return @($orderedUnique)
}

function Select-HIARouteDecision {
    param(
        [psobject]$Registry,
        [string]$DetectedTaskType
    )

    $candidates = Get-HIAPolicyCandidates -Registry $Registry -DetectedTaskType $DetectedTaskType

    $selectedProvider = $null
    foreach ($candidate in $candidates) {
        $cfg = $Registry.providers.($candidate)
        if ($null -eq $cfg) { continue }

        $isAvailable = Test-HIAProviderAvailability -ProviderConfig $cfg
        if ($isAvailable) {
            $selectedProvider = $candidate
            break
        }
    }

    if (-not $selectedProvider) {
        $selectedProvider = [string]$Registry.defaults.provider
    }

    $selectedCfg = $Registry.providers.($selectedProvider)
    $fallbackTarget = "NONE"

    $fallbackList = @()
    if ($selectedCfg -and $selectedCfg.fallback_order) {
        $fallbackList += @($selectedCfg.fallback_order)
    }

    foreach ($f in $fallbackList) {
        if ($f -eq $selectedProvider) { continue }
        $fallbackCfg = $Registry.providers.($f)
        if ($fallbackCfg -and (Test-HIAProviderAvailability -ProviderConfig $fallbackCfg)) {
            $fallbackTarget = $f
            break
        }
    }

    $rationale = "Policy registry selected $selectedProvider for task_type=$DetectedTaskType."

    return [ordered]@{
        task_type = $DetectedTaskType
        selected_provider = $selectedProvider
        selected_target = if ($selectedCfg.default_target) { [string]$selectedCfg.default_target } else { "UNKNOWN" }
        execution_mode = if ($selectedCfg.execution_mode) { [string]$selectedCfg.execution_mode } else { "dry_run" }
        rationale = $rationale
        fallback_target = $fallbackTarget
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
}

function Invoke-HIALocalTool {
    param([string]$Prompt)

    $allowList = @(
        "Get-Date",
        "Get-Location",
        "git status",
        "git branch"
    )

    foreach ($cmd in $allowList) {
        if ($Prompt.Trim().StartsWith($cmd, [System.StringComparison]::OrdinalIgnoreCase)) {
            try {
                $output = Invoke-Expression $Prompt 2>&1 | Out-String
                return @{
                    response = $output.Trim()
                    tokens_used = 0
                }
            }
            catch {
                return @{
                    response = "LOCAL_TOOL execution error: $($_.Exception.Message)"
                    tokens_used = 0
                }
            }
        }
    }

    return @{
        response = "LOCAL_TOOL selected. Prompt not in allowlist; execution skipped."
        tokens_used = 0
    }
}

function Invoke-HIARouteExecution {
    param(
        [hashtable]$Decision,
        [string]$Prompt
    )

    if ($Decision.selected_provider -eq "LOCAL_TOOL") {
        return Invoke-HIALocalTool -Prompt $Prompt
    }

    if ($Decision.selected_provider -eq "OLLAMA" -and $Decision.execution_mode -eq "live") {
        try {
            $out = & ollama run $Decision.selected_target $Prompt 2>&1 | Out-String
            return @{
                response = $out.Trim()
                tokens_used = 0
            }
        }
        catch {
            return @{
                response = "OLLAMA execution error: $($_.Exception.Message)"
                tokens_used = 0
            }
        }
    }

    return @{
        response = "$($Decision.selected_provider) selected ($($Decision.execution_mode)). Dry-run response."
        tokens_used = 0
    }
}

function Write-HIARouterLog {
    param(
        [string]$ProjectRoot,
        [hashtable]$Decision,
        [hashtable]$Result,
        [string]$Prompt
    )

    $logDir = Join-Path $ProjectRoot "03_ARTIFACTS\LOGS"
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $logPath = Join-Path $logDir "HIA_ROUTER.log"
    $line = "{0} | task_type={1} | provider={2} | target={3} | mode={4} | latency_ms={5} | prompt_len={6}" -f `
        ((Get-Date).ToUniversalTime().ToString("o")),
        $Decision.task_type,
        $Decision.selected_provider,
        $Decision.selected_target,
        $Decision.execution_mode,
        $Result.latency_ms,
        $Prompt.Length

    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

function Invoke-HIARouter {
    param(
        [string]$TaskType,
        [string]$TaskPrompt
    )

    $projectRoot = Get-HIAProjectRoot
    $registryPath = Get-HIAModelRoutingRegistryPath -ProjectRoot $projectRoot
    $registry = Read-HIAModelRoutingRegistry -RegistryPath $registryPath

    $detectedTaskType = Get-HIATaskType -ProvidedTaskType $TaskType -Prompt $TaskPrompt -DefaultTaskType ([string]$registry.defaults.task_type)
    $decision = Select-HIARouteDecision -Registry $registry -DetectedTaskType $detectedTaskType

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $exec = Invoke-HIARouteExecution -Decision $decision -Prompt $TaskPrompt
    $sw.Stop()

    $result = [ordered]@{
        task_type = $decision.task_type
        selected_provider = $decision.selected_provider
        selected_target = $decision.selected_target
        execution_mode = $decision.execution_mode
        rationale = $decision.rationale
        fallback_target = $decision.fallback_target
        generated_at_utc = $decision.generated_at_utc
        response = $exec.response
        tokens_used = $exec.tokens_used
        latency_ms = [int]$sw.ElapsedMilliseconds
    }

    Write-HIARouterLog -ProjectRoot $projectRoot -Decision $decision -Result $result -Prompt $TaskPrompt
    return $result
}

function Show-HIARoutingPolicy {
    $projectRoot = Get-HIAProjectRoot
    $registryPath = Get-HIAModelRoutingRegistryPath -ProjectRoot $projectRoot
    $registry = Read-HIAModelRoutingRegistry -RegistryPath $registryPath

    Write-Host ""
    Write-Host "HIA ROUTING POLICY" -ForegroundColor Cyan
    Write-Host "REGISTRY_PATH: $registryPath"
    Write-Host "VERSION: $($registry.version)"
    Write-Host "UPDATED_UTC: $($registry.updated_utc)"
    Write-Host "PROVIDERS:"
    foreach ($p in $registry.providers.PSObject.Properties) {
        Write-Host "  - $($p.Name) | mode=$($p.Value.execution_mode) | priority=$($p.Value.priority)"
    }
    Write-Host ""

    $registry | ConvertTo-Json -Depth 12
}

switch ($Command) {
    "show-policy" {
        Show-HIARoutingPolicy
        break
    }
    "dispatch" {
        $dispatchPath = Join-Path (Get-HIAProjectRoot) "02_TOOLS\\HIA_AI_DISPATCH_ENGINE.ps1"
        if (-not (Test-Path -LiteralPath $dispatchPath)) {
            throw "AI dispatch engine not found: $dispatchPath"
        }
        . $dispatchPath

        if ([string]::IsNullOrWhiteSpace($TaskType)) {
            throw "TaskType required. Usage: hia ai dispatch -TaskType <tasktype> [-TaskPrompt <risk>]"
        }

        # For MVP: allow passing Risk through TaskPrompt to avoid adding new params.
        $risk = ""
        if (-not [string]::IsNullOrWhiteSpace($TaskPrompt)) { $risk = $TaskPrompt }
        $result = Invoke-HIAAiDispatch -TaskType $TaskType -Risk $risk
        $result | ConvertTo-Json -Depth 10
        break
    }
    "prompt" {
        $promptEnginePath = Join-Path (Get-HIAProjectRoot) "02_TOOLS\\HIA_AI_PROMPT_ENGINE.ps1"
        if (-not (Test-Path -LiteralPath $promptEnginePath)) {
            throw "AI prompt engine not found: $promptEnginePath"
        }
        . $promptEnginePath

        if (-not $RemainingArgs -or $RemainingArgs.Count -lt 2) {
            throw "Usage: hia ai prompt <tool> <tasktype> [risk] [--json]"
        }

        $tool = $RemainingArgs[0]
        $tt = $RemainingArgs[1]
        $risk = ""
        if ($RemainingArgs.Count -ge 3 -and -not ($RemainingArgs[2] -match '^--json$')) {
            $risk = $RemainingArgs[2]
        }

        $wantJson = ($RemainingArgs -contains "--json")
        $res = Invoke-HIAAiPrompt -Tool $tool -TaskType $tt -Risk $risk -Json:([bool]$wantJson)
        $res | ConvertTo-Json -Depth 10
        break
    }
    "route" {
        if ([string]::IsNullOrWhiteSpace($TaskPrompt)) {
            throw "TaskPrompt is required for route command."
        }

        $result = Invoke-HIARouter -TaskType $TaskType -TaskPrompt $TaskPrompt

        Write-Host ""
        Write-Host "HIA AI ROUTER DECISION" -ForegroundColor Cyan
        Write-Host "TASK_TYPE: $($result.task_type)"
        Write-Host "SELECTED_PROVIDER: $($result.selected_provider)"
        Write-Host "SELECTED_TARGET: $($result.selected_target)"
        Write-Host "EXECUTION_MODE: $($result.execution_mode)"
        Write-Host "FALLBACK_TARGET: $($result.fallback_target)"
        Write-Host "LATENCY_MS: $($result.latency_ms)"
        Write-Host "TOKENS_USED: $($result.tokens_used)"
        Write-Host "RATIONALE: $($result.rationale)"
        Write-Host "RESPONSE:"
        Write-Host $result.response
        Write-Host ""

        $result | ConvertTo-Json -Depth 10
        break
    }
    default {
        # Shorthand: `hia ai <tasktype>` => dispatch
        $dispatchPath = Join-Path (Get-HIAProjectRoot) "02_TOOLS\\HIA_AI_DISPATCH_ENGINE.ps1"
        if (-not (Test-Path -LiteralPath $dispatchPath)) {
            throw "AI dispatch engine not found: $dispatchPath"
        }
        . $dispatchPath
        $result = Invoke-HIAAiDispatch -TaskType $Command
        $result | ConvertTo-Json -Depth 10
        break
    }
}
