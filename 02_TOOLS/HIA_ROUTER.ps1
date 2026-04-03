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
    Write-Host "TASKS:" -ForegroundColor Yellow
    Write-Host "  task create-file <relative_path> Crea archivo dentro de PROJECT_ROOT"
    Write-Host "  task create-file-project <project_id> <relative_path> Crea archivo dentro de 04_PROJECTS\\<project_id>"
    Write-Host "  projects status Resumen operativo mínimo del portfolio por proyecto"
    Write-Host "  project review <project_id> Revisión mínima de output/log recientes del proyecto"

    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  hia <command> [args]"
    Write-Host "  hia agent <name> [args]"
    Write-Host ""
    Write-Host "QUICKSTART:" -ForegroundColor Yellow
    Write-Host "  hia project new SAMPLE_HELLO"
    Write-Host "  hia project status SAMPLE_HELLO"
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
        $global:HIA_EXIT_CODE = 2
        Write-Host "ERROR: Tool '$ToolName' not found in registry." -ForegroundColor Red
        return
    }

    $script = $toolEntry.Value.script
    $scriptPath = Join-Path $ProjectRoot "02_TOOLS\$script"

    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path $ProjectRoot "02_TOOLS\Maintenance\$script"
    }

    if (-not (Test-Path $scriptPath)) {
        $global:HIA_EXIT_CODE = 1
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

    $agentExists = $false
    if ($agentReg -and $agentReg.agents) {
        $agentExists = $agentReg.agents.PSObject.Properties.Name -contains $AgentName
    }

    if (-not $agentExists) {
        $global:HIA_EXIT_CODE = 3
        Write-Host "ERROR: Agent '$AgentName' not found in registry." -ForegroundColor Red
        return
    }

    $agent = $agentReg.agents.$AgentName
    $script = $agent.script
    $scriptPath = Join-Path $ProjectRoot "04_AGENTS\$script"

    if (-not (Test-Path $scriptPath)) {
        $global:HIA_EXIT_CODE = 1
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

function Invoke-HIAPreflightCheck {
    param([string]$ProjectRoot)

    $pathsStatus = "OK"
    $writeStatus = "OK"
    $stackStatus = "N/A"
    $notes = New-Object System.Collections.Generic.List[string]

    $enginePath = Join-Path $ProjectRoot "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
    $projectsPath = Join-Path $ProjectRoot "04_PROJECTS"
    $toolsPath = Join-Path $ProjectRoot "02_TOOLS"
    if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) { $pathsStatus = "FAIL"; $notes.Add("Missing project engine") }
    if (-not (Test-Path -LiteralPath $projectsPath -PathType Container)) { $pathsStatus = "FAIL"; $notes.Add("Missing 04_PROJECTS") }
    if (-not (Test-Path -LiteralPath $toolsPath -PathType Container)) { $pathsStatus = "FAIL"; $notes.Add("Missing 02_TOOLS") }

    $writeTestDir = Join-Path $ProjectRoot "99_TEMP"
    $writeTestFile = Join-Path $writeTestDir "preflight.tmp"
    try {
        if (-not (Test-Path -LiteralPath $writeTestDir)) { New-Item -ItemType Directory -Path $writeTestDir -Force | Out-Null }
        "ok" | Set-Content -LiteralPath $writeTestFile -Encoding UTF8 -ErrorAction Stop
        Remove-Item -LiteralPath $writeTestFile -ErrorAction SilentlyContinue
    }
    catch {
        $writeStatus = "FAIL"
        $notes.Add("Write test failed in 99_TEMP")
    }

    $stackHelper = Join-Path $ProjectRoot "02_TOOLS\\Maintenance\\HIA_TOL_0040_Check-AIStack.ps1"
    if (Test-Path -LiteralPath $stackHelper -PathType Leaf) {
        $stackStatus = "OK"
    }
    else {
        $stackStatus = "N/A"
        $notes.Add("AI stack helper not found; skipping stack check")
    }

    $preflightStatus = if ($pathsStatus -eq "OK" -and $writeStatus -eq "OK" -and $stackStatus -ne "FAIL") { "OK" } else { "FAIL" }
    $nextAction = if ($preflightStatus -eq "OK") { "Proceed with hia projects status or project status" } else { "Fix FAIL items then rerun hia preflight" }

    return [ordered]@{
        STATUS = $preflightStatus
        PATHS_STATUS = $pathsStatus
        WRITE_STATUS = $writeStatus
        STACK_STATUS = $stackStatus
        NOTES = $notes
        NEXT_ACTION = $nextAction
        EXIT_CODE = if ($preflightStatus -eq "OK") { 0 } else { 1 }
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
                $global:HIA_EXIT_CODE = 2
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
                "task" {
                    $taskEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_TASK_ENGINE.ps1"
                    if (-not (Test-Path $taskEnginePath)) {
                        throw "Task engine not found: $taskEnginePath"
                    }

                    & $taskEnginePath @Args -ProjectRoot $projectRoot
                }
                "projects" {
                    if (-not (Get-Command Get-HIAProjects -ErrorAction SilentlyContinue)) {
                        $projectEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
                        if (-not (Test-Path $projectEnginePath)) {
                            $global:HIA_EXIT_CODE = 1
                            Write-Host "ERROR: Project engine not found: $projectEnginePath" -ForegroundColor Red
                            return
                        }
                        . $projectEnginePath
                    }

                    if (-not $Args -or $Args.Count -eq 0) {
                        Get-HIAProjects
                        return
                    }

                    $projectsAction = $Args[0].ToLowerInvariant()

                    switch ($projectsAction) {
                        "status" { Get-HIAProjects -Mode status }
                        "pick" {
                            if ($Args.Count -lt 2) { $global:HIA_EXIT_CODE = 2; throw "Usage: hia projects pick <INDEX> [status|review|continue|sessionstatus]" }
                            $pickIndex = [int]$Args[1]
                            $pickAction = if ($Args.Count -ge 3) { $Args[2].ToLowerInvariant() } else { "status" }
                            $validPickActions = @("status","review","continue","sessionstatus","session-status")
                            if ($pickAction -notin $validPickActions) { $global:HIA_EXIT_CODE = 2; throw "Usage: hia projects pick <INDEX> [status|review|continue|sessionstatus]" }
                            $projectsRoot = Join-Path $projectRoot "04_PROJECTS"
                            $projList = @(Get-ChildItem -LiteralPath $projectsRoot -Directory -Force -ErrorAction Stop | Sort-Object Name)
                            if ($projList.Count -lt $pickIndex -or $pickIndex -le 0) { $global:HIA_EXIT_CODE = 3; throw "Project index not found." }
                            $projId = [string]$projList[$pickIndex-1].Name
                            if (-not (Get-Command Show-HIAProjectStatus -ErrorAction SilentlyContinue)) {
                                $projectEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
                                if (-not (Test-Path $projectEnginePath)) { $global:HIA_EXIT_CODE = 1; throw "Project engine not found: $projectEnginePath" }
                                . $projectEnginePath
                            }
                            switch ($pickAction) {
                                "status" { Show-HIAProjectStatus -ProjectId $projId }
                                "review" { Review-HIAProject -ProjectId $projId }
                                "continue" { Continue-HIAProject -ProjectId $projId }
                                default { Get-HIAProjectSessionStatus -ProjectId $projId }
                            }
                        }
                        default { $global:HIA_EXIT_CODE = 2; throw "Usage: hia projects OR hia projects status" }
                    }
                }
                "preflight" {
                    if ($Args.Count -gt 0) { $global:HIA_EXIT_CODE = 2; throw "Usage: hia preflight" }

                    $pre = Invoke-HIAPreflightCheck -ProjectRoot $projectRoot

                    Write-Host ""
                    Write-Host "HIA PREFLIGHT" -ForegroundColor Green
                    Write-Host ("PREFLIGHT_STATUS: {0}" -f $pre.STATUS)
                    Write-Host ("PATHS_STATUS: {0}" -f $pre.PATHS_STATUS)
                    Write-Host ("WRITE_STATUS: {0}" -f $pre.WRITE_STATUS)
                    Write-Host ("STACK_STATUS: {0}" -f $pre.STACK_STATUS)
                    Write-Host ("PREFLIGHT_NOTES: {0}" -f ($pre.NOTES -join " | "))
                    Write-Host ("NEXT_ACTION: {0}" -f $pre.NEXT_ACTION)
                    Write-Host ""

                    $global:HIA_EXIT_CODE = $pre.EXIT_CODE
                    return
                }
                "deploy" {
                    $deployUsage = "Usage: hia deploy gate"
                    if (-not $Args -or $Args.Count -lt 1) { $global:HIA_EXIT_CODE = 2; throw $deployUsage }
                    $deployAction = $Args[0].ToLowerInvariant()
                    if ($Args.Count -gt 1) { $global:HIA_EXIT_CODE = 2; throw $deployUsage }
                    if ($deployAction -ne "gate") { $global:HIA_EXIT_CODE = 2; throw $deployUsage }

                    $pre = Invoke-HIAPreflightCheck -ProjectRoot $projectRoot
                    $preStatus = $pre.STATUS
                    $preExit = $pre.EXIT_CODE

                    $smokeStatus = "SKIPPED"
                    $smokeExit = 1
                    $smokeNotes = ""

                    if ($preExit -eq 0) {
                        $smokePath = Join-Path $projectRoot "02_TOOLS\Invoke-HIASmoke.ps1"
                        if (Test-Path -LiteralPath $smokePath -PathType Leaf) {
                            & $smokePath
                            $smokeExit = [int]$LASTEXITCODE
                            $smokeStatus = if ($smokeExit -eq 0) { "OK" } else { "FAIL" }
                        }
                        else {
                            $smokeStatus = "FAIL"
                            $smokeNotes = "Invoke-HIASmoke.ps1 missing"
                            $smokeExit = 1
                        }
                    }
                    else {
                        $smokeStatus = "SKIPPED"
                        $smokeExit = 1
                        $smokeNotes = "Preflight failed; smoke skipped"
                    }

                    $gateExit = if ($preExit -eq 0 -and $smokeExit -eq 0) { 0 } else { 1 }
                    $gateStatus = if ($gateExit -eq 0) { "OK" } else { "FAIL" }

                    Write-Host ""
                    Write-Host "HIA DEPLOY GATE" -ForegroundColor Cyan
                    Write-Host ("PREFLIGHT_STATUS: {0}" -f $preStatus)
                    Write-Host ("SMOKE_STATUS: {0}" -f $smokeStatus)
                    if ($smokeNotes) { Write-Host ("SMOKE_NOTES: {0}" -f $smokeNotes) }
                    Write-Host ("GATE_STATUS: {0}" -f $gateStatus)
                    Write-Host ""

                    $global:HIA_EXIT_CODE = $gateExit
                    return
                }
                "project" {
                    if (
                        -not (Get-Command New-HIAProject -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Open-HIAProject -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Continue-HIAProject -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Review-HIAProject -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Show-HIAProjectStatus -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Start-HIAProjectSession -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Get-HIAProjectSessionStatus -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Close-HIAProjectSession -ErrorAction SilentlyContinue) -or
                        -not (Get-Command Remove-HIAProjectSafe -ErrorAction SilentlyContinue)
                    ) {
                        $projectEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
                        if (-not (Test-Path $projectEnginePath)) {
                            $global:HIA_EXIT_CODE = 1
                            throw "Project engine not found: $projectEnginePath"
                        }
                        . $projectEnginePath
                    }

                    $projectUsage = "Usage: hia project new|open|continue|status|review|delete <PROJECT_ID>"
                    $projectSessionUsage = "Usage: hia project session start <PROJECT_ID> OR hia project session status <PROJECT_ID> OR hia project session close <PROJECT_ID>"

                    if (-not $Args -or $Args.Count -lt 1) {
                        $global:HIA_EXIT_CODE = 2
                        throw $projectUsage
                    }

                    $projectAction = $Args[0].ToLowerInvariant()

                    if ($projectAction -eq "session") {
                        if (-not $Args -or $Args.Count -lt 3) {
                            $global:HIA_EXIT_CODE = 2
                            throw $projectSessionUsage
                        }

                        $sessionAction = $Args[1].ToLowerInvariant()
                        $projectId = $Args[2]

                        switch ($sessionAction) {
                            "start" { Start-HIAProjectSession -ProjectId $projectId }
                            "status" { Get-HIAProjectSessionStatus -ProjectId $projectId }
                            "close" { Close-HIAProjectSession -ProjectId $projectId }
                            default { $global:HIA_EXIT_CODE = 2; throw $projectSessionUsage }
                        }
                        return
                    }

                        if (-not $Args -or $Args.Count -lt 2) {
                            $global:HIA_EXIT_CODE = 2
                            throw $projectUsage
                        }

                    $projectId = $Args[1]
                    switch ($projectAction) {
                        "new" { New-HIAProject -ProjectId $projectId }
                        "open" { Open-HIAProject -ProjectId $projectId }
                        "continue" { Continue-HIAProject -ProjectId $projectId }
                        "status" { Show-HIAProjectStatus -ProjectId $projectId }
                        "review" { Review-HIAProject -ProjectId $projectId }
                        "delete" {
                            $forceConfirm = $false
                            $confirmToken = $null
                            if ($Args.Count -ge 3) {
                                $flag = $Args[2]
                                if ($flag -eq "--confirm" -or $flag -eq "-y") {
                                    $forceConfirm = $true
                                    if ($Args.Count -ge 4) { $confirmToken = $Args[3] }
                                }
                                else {
                                    $confirmToken = $flag
                                }
                            }
                            Remove-HIAProjectSafe -ProjectId $projectId -ForceConfirm:$forceConfirm -ConfirmToken $confirmToken
                        }
                        default { $global:HIA_EXIT_CODE = 2; throw $projectUsage }
                    }
                }
                default {
                    $global:HIA_EXIT_CODE = 2
                    Write-Host "ERROR: Unknown command '$Command'. Use 'hia help' for available commands." -ForegroundColor Red
                }
            }
        }
    }
}
