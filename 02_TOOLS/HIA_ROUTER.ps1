<#
===============================================================================
MODULE: HIA_ROUTER.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: COMMAND ROUTER

OBJETIVO
Enrutar comandos del CLI a tools y agents registrados.

VERSION: v2.0
DATE: 2026-03-16
===============================================================================
#>

function Get-ToolRegistry {
    param([string]$ProjectRoot)

    $path = Join-Path $ProjectRoot "02_TOOLS\TOOL.REGISTRY.json"
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    return $null
}

function Get-AgentRegistry {
    param([string]$ProjectRoot)

    $path = Join-Path $ProjectRoot "04_AGENTS\AGENT.REGISTRY.json"
    if (Test-Path $path) {
        return Get-Content $path -Raw | ConvertFrom-Json
    }
    return $null
}

function Show-HIAHelp {
    param(
        [string]$ProjectRoot
    )

    $toolReg = Get-ToolRegistry -ProjectRoot $ProjectRoot
    $agentReg = Get-AgentRegistry -ProjectRoot $ProjectRoot

    Write-Host ""
    Write-Host "HIA CLI — Available Commands" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "TOOLS:" -ForegroundColor Yellow
    if ($toolReg -and $toolReg.tools) {
        foreach ($tool in $toolReg.tools.PSObject.Properties) {
            $name = $tool.Name.PadRight(15)
            $desc = $tool.Value.description
            Write-Host "  $name $desc"
        }
    }

    Write-Host ""
    Write-Host "AGENTS:" -ForegroundColor Yellow
    if ($agentReg -and $agentReg.agents) {
        foreach ($agent in $agentReg.agents.PSObject.Properties) {
            $name = ("agent " + $agent.Name).PadRight(15)
            $desc = $agent.Value.description
            Write-Host "  $name $desc"
        }
    }

    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  hia <command> [args]"
    Write-Host "  hia agent <name> [args]"
    Write-Host ""
}

function Invoke-HIATool {
    param(
        [string]$ProjectRoot,
        [string]$ToolName,
        [string[]]$ToolArgs
    )

    $toolReg = Get-ToolRegistry -ProjectRoot $ProjectRoot

    $toolEntry = $null
    if ($toolReg -and $toolReg.tools) {
        $toolEntry = $toolReg.tools.PSObject.Properties[$ToolName]
    }

    if (-not $toolEntry) {
        Write-Host "ERROR: Tool '$ToolName' not found in registry." -ForegroundColor Red
        return
    }

    $script = $toolEntry.Value.script
    $scriptPath = Join-Path $ProjectRoot "02_TOOLS\$script"

    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path $ProjectRoot "02_TOOLS\Maintenance\$script"
    }

    if (-not (Test-Path $scriptPath)) {
        Write-Host "ERROR: Script not found: $script" -ForegroundColor Red
        return
    }

    Write-Host "EXECUTING: $ToolName" -ForegroundColor Green
    Write-Host "SCRIPT: $script" -ForegroundColor DarkGray
    Write-Host ""

    $positional = @()
    $paramTable = @{}

    for ($i = 0; $i -lt $ToolArgs.Count; $i++) {
        $token = $ToolArgs[$i]
        if ($token -like "-*") {
            $name = $token.TrimStart("-")
            if (($i + 1) -lt $ToolArgs.Count -and -not ($ToolArgs[$i + 1] -like "-*")) {
                $paramTable[$name] = $ToolArgs[$i + 1]
                $i++
            }
            else {
                $paramTable[$name] = $true
            }
        }
        else {
            $positional += $token
        }
    }

    if ($paramTable.Count -gt 0) {
        & $scriptPath @positional @paramTable
    }
    else {
        & $scriptPath @positional
    }
}

function Invoke-HIAAgent {
    param(
        [string]$ProjectRoot,
        [string]$AgentName,
        [string[]]$AgentArgs
    )

    $agentReg = Get-AgentRegistry -ProjectRoot $ProjectRoot

    if (-not $agentReg -or -not $agentReg.agents.$AgentName) {
        Write-Host "ERROR: Agent '$AgentName' not found in registry." -ForegroundColor Red
        return
    }

    $agent = $agentReg.agents.$AgentName
    $script = $agent.script
    $scriptPath = Join-Path $ProjectRoot "04_AGENTS\$script"

    if (-not (Test-Path $scriptPath)) {
        Write-Host "ERROR: Agent script not found: $script" -ForegroundColor Red
        return
    }

    if ($agent.requires_approval) {
        Write-Host "AGENT: $AgentName (requires approval)" -ForegroundColor Yellow
    }
    else {
        Write-Host "AGENT: $AgentName" -ForegroundColor Green
    }

    Write-Host "MODE: $($agent.mode)" -ForegroundColor DarkGray
    Write-Host ""

    if ($AgentName -eq "planner") {
        if ($AgentArgs -and $AgentArgs.Count -gt 0) {
            & $scriptPath -Request ($AgentArgs -join " ")
        }
        else {
            & $scriptPath
        }
        return
    }

    if ($AgentName -eq "executor") {
        if (-not $AgentArgs -or $AgentArgs.Count -eq 0) {
            & $scriptPath
            return
        }

        $paramTable = @{}

        for ($i = 0; $i -lt $AgentArgs.Count; $i++) {
            $token = $AgentArgs[$i]
            if ($token -like "-*") {
                $name = $token.TrimStart("-")
                if (($i + 1) -lt $AgentArgs.Count -and -not ($AgentArgs[$i + 1] -like "-*")) {
                    $paramTable[$name] = $AgentArgs[$i + 1]
                    $i++
                }
                else {
                    $paramTable[$name] = $true
                }
            }
            else {
                if (-not $paramTable.ContainsKey("Request")) {
                    $paramTable["Request"] = $token
                }
                else {
                    $paramTable["Request"] = ($paramTable["Request"] + " " + $token).Trim()
                }
            }
        }

        & $scriptPath @paramTable
        return
    }

    if ($AgentArgs -and $AgentArgs.Count -gt 0) {
        & $scriptPath @AgentArgs
    }
    else {
        & $scriptPath
    }
}

function Invoke-HIARouter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $projectRoot = Resolve-Path "$PSScriptRoot\.."
    $normalizedCommand = $Command.ToLowerInvariant()

    switch ($normalizedCommand) {
        "help" {
            Show-HIAHelp -ProjectRoot $projectRoot
        }
        "agent" {
            if ($Args -and $Args.Count -ge 1) {
                $agentName = $Args[0]
                $agentArgs = @()
                if ($Args.Count -gt 1) {
                    $agentArgs = $Args[1..($Args.Count - 1)]
                }
                Invoke-HIAAgent -ProjectRoot $projectRoot -AgentName $agentName -AgentArgs $agentArgs
            }
            else {
                Write-Host "ERROR: Specify agent name. Usage: hia agent <name>" -ForegroundColor Red
            }
        }
        default {
            $toolReg = Get-ToolRegistry -ProjectRoot $projectRoot
            $toolEntry = $null
            if ($toolReg -and $toolReg.tools) {
                $toolEntry = $toolReg.tools.PSObject.Properties[$normalizedCommand]
            }

            if ($toolEntry) {
                Invoke-HIATool -ProjectRoot $projectRoot -ToolName $normalizedCommand -ToolArgs $Args
                return
            }

            switch ($normalizedCommand) {
                "plan" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "plan" -ToolArgs $Args }
                "apply" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "apply" -ToolArgs $Args }
                "run" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "run" -ToolArgs $Args }
                "validate" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "validate" -ToolArgs $Args }
                "radar" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "radar" -ToolArgs $Args }
                "state" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "state" -ToolArgs $Args }
                "session" { Invoke-HIATool -ProjectRoot $projectRoot -ToolName "session" -ToolArgs $Args }
                "projects" {
                    if (-not (Get-Command Get-HIAProjects -ErrorAction SilentlyContinue)) {
                        $projectEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
                        if (-not (Test-Path $projectEnginePath)) {
                            Write-Host "ERROR: Project engine not found: $projectEnginePath" -ForegroundColor Red
                            return
                        }
                        . $projectEnginePath
                    }
                    Get-HIAProjects
                }
                default {
                    Write-Host "ERROR: Unknown command '$Command'. Use 'hia help' for available commands." -ForegroundColor Red
                }
            }
        }
    }
}
