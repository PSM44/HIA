<#
===============================================================================
MODULE: HIA_AGENT_002_Executor.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: AGENT — EXECUTOR

OBJETIVO
Agente que ejecuta tareas de forma controlada dentro del PROJECT_ROOT.

MODES:
- plan_only: Genera plan de ejecucion sin ejecutar (default)
- execute: Ejecuta plan aprobado

SECURITY:
- Solo opera dentro de PROJECT_ROOT
- Requiere aprobacion humana para mode=execute
- Genera logs de toda ejecucion

VERSION: v1.0
DATE: 2026-03-16
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Request,

    [Parameter(Mandatory = $false)]
    [string]$PlanId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("plan_only", "execute")]
    [string]$Mode = "plan_only",

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $false)]
    [switch]$AutoApprove
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

$artifactsDir = Join-Path $ProjectRoot "03_ARTIFACTS"
$plansDir = Join-Path $artifactsDir "plans"
$logsDir = Join-Path $artifactsDir "logs"
$executionLogsDir = Join-Path $logsDir "executions"

foreach ($dir in @($artifactsDir, $plansDir, $logsDir, $executionLogsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

function Write-ExecutorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"
    Write-Host $line -ForegroundColor $(
        switch ($Level) {
            "INFO" { "White" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )

    return $line
}

function Get-StepValue {
    param(
        [object]$Step,
        [string]$Key
    )

    if ($Step -is [hashtable]) {
        return $Step[$Key]
    }

    return $Step.$Key
}

function Set-StepValue {
    param(
        [object]$Step,
        [string]$Key,
        [object]$Value
    )

    if ($Step -is [hashtable]) {
        $Step[$Key] = $Value
        return
    }

    $Step.$Key = $Value
}

function Set-PlanValue {
    param(
        [object]$Plan,
        [string]$Key,
        [object]$Value
    )

    if ($Plan -is [hashtable]) {
        $Plan[$Key] = $Value
        return
    }

    if ($null -eq ($Plan.PSObject.Properties[$Key])) {
        Add-Member -InputObject $Plan -NotePropertyName $Key -NotePropertyValue $Value -Force
        return
    }

    $Plan.$Key = $Value
}

function Test-PathInProjectRoot {
    param(
        [string]$Path,
        [string]$Root
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $resolvedRoot = [System.IO.Path]::GetFullPath($Root)

    return $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function New-ExecutionPlan {
    param(
        [string]$Request,
        [string]$Root
    )

    $planId = "EXEC_" + (Get-Date -Format "yyyyMMdd_HHmmss")
    $planPath = Join-Path $plansDir "$planId.json"

    $steps = @()

    if ($Request -match "crear?\s+archivo|create\s+file|new\s+file") {
        $steps += @{
            action = "create_file"
            description = "Create new file"
            status = "pending"
        }
    }
    elseif ($Request -match "ejecutar?\s+radar|run\s+radar") {
        $steps += @{
            action = "run_tool"
            tool = "radar"
            description = "Execute RADAR tool"
            status = "pending"
        }
    }
    elseif ($Request -match "ejecutar?\s+validat|run\s+validat") {
        $steps += @{
            action = "run_tool"
            tool = "validate"
            description = "Execute validators"
            status = "pending"
        }
    }
    elseif ($Request -match "ejecutar?\s+smoke|run\s+smoke") {
        $steps += @{
            action = "run_tool"
            tool = "smoke"
            description = "Execute smoke test"
            status = "pending"
        }
    }
    elseif ($Request -match "git\s+status") {
        $steps += @{
            action = "run_command"
            command = "git status"
            description = "Check git status"
            status = "pending"
        }
    }
    elseif ($Request -match "git\s+checkpoint|checkpoint") {
        $steps += @{
            action = "run_tool"
            tool = "checkpoint"
            description = "Create git checkpoint"
            status = "pending"
        }
    }
    else {
        $steps += @{
            action = "analyze"
            description = "Analyze request: $Request"
            status = "pending"
        }
    }

    $plan = @{
        id = $planId
        request = $Request
        created_utc = (Get-Date).ToUniversalTime().ToString("o")
        status = "planned"
        mode = "plan_only"
        project_root = $Root
        steps = $steps
    }

    $plan | ConvertTo-Json -Depth 10 | Set-Content -Path $planPath -Encoding UTF8

    return $plan
}

function Invoke-ExecutionPlan {
    param(
        [object]$Plan,
        [string]$Root
    )

    $logLines = @()
    $logLines += Write-ExecutorLog "EXECUTION START: $($Plan.id)"
    $logLines += Write-ExecutorLog "REQUEST: $($Plan.request)"

    $allSuccess = $true
    $toolsDir = Join-Path $Root "02_TOOLS"

    foreach ($step in $Plan.steps) {
        $logLines += Write-ExecutorLog ("STEP: " + (Get-StepValue -Step $step -Key "description"))

        try {
            switch ($step.action) {
                "run_tool" {
                    $toolRegistry = Get-Content (Join-Path $toolsDir "TOOL.REGISTRY.json") -Raw | ConvertFrom-Json
                    $toolInfo = $toolRegistry.tools.(Get-StepValue -Step $step -Key "tool")

                    if (-not $toolInfo) {
                        throw ("Tool not found: " + (Get-StepValue -Step $step -Key "tool"))
                    }

                    $scriptPath = Join-Path $toolsDir $toolInfo.script
                    if (-not (Test-Path $scriptPath)) {
                        $scriptPath = Join-Path $toolsDir "Maintenance\$($toolInfo.script)"
                    }

                    if (-not (Test-Path $scriptPath)) {
                        throw "Script not found: $($toolInfo.script)"
                    }

                    $logLines += Write-ExecutorLog "Running: $($toolInfo.script)" "INFO"

                    $output = & $scriptPath 2>&1
                    $logLines += "OUTPUT: $output"

                    Set-StepValue -Step $step -Key "status" -Value "completed"
                    $logLines += Write-ExecutorLog "STEP COMPLETED" "SUCCESS"
                }

                "run_command" {
                    $safeCommands = @("git status", "git log", "git branch", "Get-Date", "Get-Location")
                    $isSafe = $false

                    $stepCommand = Get-StepValue -Step $step -Key "command"
                    foreach ($safe in $safeCommands) {
                        if ($stepCommand -like "$safe*") {
                            $isSafe = $true
                            break
                        }
                    }

                    if (-not $isSafe) {
                        throw ("Command not in allowlist: " + $stepCommand)
                    }

                    $logLines += Write-ExecutorLog ("Running command: " + $stepCommand) "INFO"

                    Push-Location $Root
                    try {
                        $output = Invoke-Expression $stepCommand 2>&1
                        $logLines += "OUTPUT: $output"
                    }
                    finally {
                        Pop-Location
                    }

                    Set-StepValue -Step $step -Key "status" -Value "completed"
                    $logLines += Write-ExecutorLog "STEP COMPLETED" "SUCCESS"
                }

                "analyze" {
                    $logLines += Write-ExecutorLog "Analysis task - no execution required" "INFO"
                    Set-StepValue -Step $step -Key "status" -Value "completed"
                }

                default {
                    $logLines += Write-ExecutorLog ("Unknown action: " + (Get-StepValue -Step $step -Key "action")) "WARN"
                    Set-StepValue -Step $step -Key "status" -Value "skipped"
                }
            }
        }
        catch {
            $logLines += Write-ExecutorLog "STEP FAILED: $($_.Exception.Message)" "ERROR"
            Set-StepValue -Step $step -Key "status" -Value "failed"
            Set-StepValue -Step $step -Key "error" -Value $_.Exception.Message
            $allSuccess = $false
        }
    }

    $finalStatus = if ($allSuccess) { "completed" } else { "failed" }
    Set-PlanValue -Plan $Plan -Key "status" -Value $finalStatus
    Set-PlanValue -Plan $Plan -Key "completed_utc" -Value (Get-Date).ToUniversalTime().ToString("o")

    $planPath = Join-Path $plansDir "$($Plan.id).json"
    $Plan | ConvertTo-Json -Depth 10 | Set-Content -Path $planPath -Encoding UTF8

    $logPath = Join-Path $executionLogsDir "$($Plan.id).log"
    $logLines -join "`n" | Set-Content -Path $logPath -Encoding UTF8

    $logLines += Write-ExecutorLog "EXECUTION END: $($Plan.status)" $(if ($allSuccess) { "SUCCESS" } else { "ERROR" })
    $logLines += Write-ExecutorLog "LOG: $logPath"

    return $allSuccess
}

function Request-HumanApproval {
    param(
        [object]$Plan
    )

    if ($AutoApprove) {
        Write-Host ""
        Write-Host "AUTO-APPROVE: enabled" -ForegroundColor Yellow
        return $true
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host " EXECUTION APPROVAL REQUIRED" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PLAN ID: $($Plan.id)"
    Write-Host "REQUEST: $($Plan.request)"
    Write-Host ""
    Write-Host "STEPS TO EXECUTE:" -ForegroundColor Cyan

    foreach ($step in $Plan.steps) {
        $desc = Get-StepValue -Step $step -Key "description"
        Write-Host "  - $desc"

        $cmd = Get-StepValue -Step $step -Key "command"
        if ($cmd) {
            Write-Host "    Command: $cmd" -ForegroundColor DarkGray
        }

        $tool = Get-StepValue -Step $step -Key "tool"
        if ($tool) {
            Write-Host "    Tool: $tool" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "CONTEXT:" -ForegroundColor Cyan
    Write-Host "  DATE: $(Get-Date -Format 'yyyy-MM-dd')"
    Write-Host "  TIME: $(Get-Date -Format 'HH:mm')"
    Write-Host "  ROOT: $($Plan.project_root)"
    Write-Host ""

    $response = Read-Host "Approve execution? (y/n)"

    return ($response -eq "y" -or $response -eq "Y")
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host " HIA AGENT: EXECUTOR" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

if ($PlanId) {
    $planPath = Join-Path $plansDir "$PlanId.json"

    if (-not (Test-Path $planPath)) {
        [void](Write-ExecutorLog "Plan not found: $PlanId" "ERROR")
        exit 1
    }

    $plan = Get-Content $planPath -Raw | ConvertFrom-Json

    [void](Write-ExecutorLog "Loaded plan: $PlanId")
    [void](Write-ExecutorLog "Status: $($plan.status)")

    if ($plan.status -ne "planned" -and $plan.status -ne "approved") {
        [void](Write-ExecutorLog "Plan is not in executable state: $($plan.status)" "ERROR")
        exit 1
    }

    if ($Mode -eq "execute") {
        $approved = Request-HumanApproval -Plan $plan

        if (-not $approved) {
            [void](Write-ExecutorLog "Execution cancelled by user" "WARN")
            exit 0
        }

        Set-PlanValue -Plan $plan -Key "status" -Value "executing"
        $success = Invoke-ExecutionPlan -Plan $plan -Root $ProjectRoot

        exit $(if ($success) { 0 } else { 1 })
    }
    else {
        Write-Host "Plan loaded. Use -Mode execute to run."
        Write-Host ""
        Write-Host "STEPS:" -ForegroundColor Cyan
        foreach ($step in $plan.steps) {
            Write-Host "  - $($step.description)"
        }
    }
}
elseif ($Request) {
    [void](Write-ExecutorLog "Creating execution plan...")
    [void](Write-ExecutorLog "Request: $Request")

    $plan = New-ExecutionPlan -Request $Request -Root $ProjectRoot

    Write-Host ""
    Write-Host "PLAN CREATED" -ForegroundColor Green
    Write-Host "ID: $($plan.id)"
    Write-Host "PATH: $(Join-Path $plansDir "$($plan.id).json")"
    Write-Host ""
    Write-Host "STEPS:" -ForegroundColor Cyan
    foreach ($step in $plan.steps) {
        Write-Host "  - $($step.description)"
    }
    Write-Host ""

    if ($Mode -eq "execute") {
        $approved = Request-HumanApproval -Plan $plan

        if (-not $approved) {
            [void](Write-ExecutorLog "Execution cancelled by user" "WARN")
            exit 0
        }

        Set-PlanValue -Plan $plan -Key "status" -Value "executing"
        $success = Invoke-ExecutionPlan -Plan $plan -Root $ProjectRoot

        exit $(if ($success) { 0 } else { 1 })
    }
    else {
        Write-Host "To execute, run:"
        Write-Host "  hia agent executor -PlanId $($plan.id) -Mode execute" -ForegroundColor Yellow
    }
}
else {
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  Create plan:  hia agent executor -Request `"run smoke test`""
    Write-Host "  Execute plan: hia agent executor -PlanId EXEC_XXXX -Mode execute"
    Write-Host ""
    Write-Host "SUPPORTED TASKS:" -ForegroundColor Cyan
    Write-Host "  - run radar / ejecutar radar"
    Write-Host "  - run validate / ejecutar validadores"
    Write-Host "  - run smoke / ejecutar smoke"
    Write-Host "  - git status"
    Write-Host "  - checkpoint"
}

Write-Host ""
