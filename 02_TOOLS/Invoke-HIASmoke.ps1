<#
===============================================================================
MODULE: Invoke-HIASmoke.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: SMOKE TEST

OBJETIVO
Validar que todos los componentes del sistema HIA están operativos.

VERSION: v2.1
DATE: 2026-03-26
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\.."),

    [Parameter(Mandatory = $false)]
    [switch]$VerboseMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------

function Write-TestResult {
    param(
        [string]$Component,
        [string]$Test,
        [bool]$Passed,
        [string]$Message = ""
    )

    $status = if ($Passed) { "OK" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }

    $line = "[$status] $Component :: $Test"
    if ($Message) {
        $line += " — $Message"
    }

    Write-Host $line -ForegroundColor $color
}

# -----------------------------------------------------------------------------
# TEST FUNCTIONS
# -----------------------------------------------------------------------------

function Test-ToolRegistry {
    param([string]$Root)

    $path = Join-Path $Root "02_TOOLS\TOOL.REGISTRY.json"

    if (-not (Test-Path $path)) {
        Write-TestResult -Component "Registry" -Test "TOOL.REGISTRY.json exists" -Passed $false
        return $false
    }

    Write-TestResult -Component "Registry" -Test "TOOL.REGISTRY.json exists" -Passed $true

    try {
        $registry = Get-Content $path -Raw | ConvertFrom-Json
        $toolCount = ($registry.tools.PSObject.Properties | Measure-Object).Count
        Write-TestResult -Component "Registry" -Test "TOOL.REGISTRY.json valid JSON" -Passed $true -Message "$toolCount tools"
        return $true
    }
    catch {
        Write-TestResult -Component "Registry" -Test "TOOL.REGISTRY.json valid JSON" -Passed $false -Message $_.Exception.Message
        return $false
    }
}

function Test-AgentRegistry {
    param([string]$Root)

    $path = Join-Path $Root "04_AGENTS\AGENT.REGISTRY.json"

    if (-not (Test-Path $path)) {
        Write-TestResult -Component "Registry" -Test "AGENT.REGISTRY.json exists" -Passed $false
        return $false
    }

    Write-TestResult -Component "Registry" -Test "AGENT.REGISTRY.json exists" -Passed $true

    try {
        $registry = Get-Content $path -Raw | ConvertFrom-Json
        $agentCount = ($registry.agents.PSObject.Properties | Measure-Object).Count
        Write-TestResult -Component "Registry" -Test "AGENT.REGISTRY.json valid JSON" -Passed $true -Message "$agentCount agents"
        return $true
    }
    catch {
        Write-TestResult -Component "Registry" -Test "AGENT.REGISTRY.json valid JSON" -Passed $false -Message $_.Exception.Message
        return $false
    }
}

function Test-ToolScriptsExist {
    param([string]$Root)

    $registryPath = Join-Path $Root "02_TOOLS\TOOL.REGISTRY.json"
    $registry = Get-Content $registryPath -Raw | ConvertFrom-Json

    $allPassed = $true

    foreach ($tool in $registry.tools.PSObject.Properties) {
        $scriptName = $tool.Value.script
        $scriptPath = Join-Path $Root "02_TOOLS\$scriptName"

        if (-not (Test-Path $scriptPath)) {
            $scriptPath = Join-Path $Root "02_TOOLS\Maintenance\$scriptName"
        }

        $exists = Test-Path $scriptPath
        Write-TestResult -Component "Tools" -Test "$($tool.Name) script exists" -Passed $exists -Message $scriptName

        if (-not $exists) { $allPassed = $false }
    }

    return $allPassed
}

function Test-AgentScriptsExist {
    param([string]$Root)

    $registryPath = Join-Path $Root "04_AGENTS\AGENT.REGISTRY.json"
    $registry = Get-Content $registryPath -Raw | ConvertFrom-Json

    $allPassed = $true

    foreach ($agent in $registry.agents.PSObject.Properties) {
        $scriptName = $agent.Value.script
        $scriptPath = Join-Path $Root "04_AGENTS\$scriptName"

        $exists = Test-Path $scriptPath
        Write-TestResult -Component "Agents" -Test "$($agent.Name) script exists" -Passed $exists -Message $scriptName

        if (-not $exists) { $allPassed = $false }
    }

    return $allPassed
}

function Test-CoreDirectories {
    param([string]$Root)

    $requiredDirs = @(
        "00_FRAMEWORK",
        "01_UI",
        "02_TOOLS",
        "04_AGENTS",
        "HUMAN.README"
    )

    $allPassed = $true

    foreach ($dir in $requiredDirs) {
        $path = Join-Path $Root $dir
        $exists = Test-Path $path
        Write-TestResult -Component "Structure" -Test "$dir exists" -Passed $exists

        if (-not $exists) { $allPassed = $false }
    }

    return $allPassed
}

function Test-CLIEntrypoint {
    param([string]$Root)

    $cliPath = Join-Path $Root "01_UI\terminal\hia.ps1"
    $routerPath = Join-Path $Root "02_TOOLS\HIA_ROUTER.ps1"

    $cliExists = Test-Path $cliPath
    $routerExists = Test-Path $routerPath

    Write-TestResult -Component "CLI" -Test "hia.ps1 exists" -Passed $cliExists
    Write-TestResult -Component "CLI" -Test "HIA_ROUTER.ps1 exists" -Passed $routerExists

    return ($cliExists -and $routerExists)
}

function Test-RADARExecution {
    param([string]$Root)

    $radarPath = Join-Path $Root "02_TOOLS\RADAR.ps1"

    if (-not (Test-Path $radarPath)) {
        Write-TestResult -Component "RADAR" -Test "RADAR.ps1 execution" -Passed $false -Message "Script not found"
        return $false
    }

    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile($radarPath, [ref]$null, [ref]$null)
        Write-TestResult -Component "RADAR" -Test "RADAR.ps1 syntax valid" -Passed $true
        return $true
    }
    catch {
        Write-TestResult -Component "RADAR" -Test "RADAR.ps1 syntax valid" -Passed $false -Message $_.Exception.Message
        return $false
    }
}

function Test-ArtifactsDirectory {
    param([string]$Root)

    $artifactsPath = Join-Path $Root "03_ARTIFACTS"
    $plansPath = Join-Path $Root "03_ARTIFACTS\plans"

    $artifactsExists = Test-Path $artifactsPath

    if (-not $artifactsExists) {
        New-Item -ItemType Directory -Path $artifactsPath -Force | Out-Null
        New-Item -ItemType Directory -Path $plansPath -Force | Out-Null
        Write-TestResult -Component "Artifacts" -Test "03_ARTIFACTS exists" -Passed $true -Message "Created"
    }
    else {
        Write-TestResult -Component "Artifacts" -Test "03_ARTIFACTS exists" -Passed $true
    }

    return $true
}

function Test-StateEngineFlow {
    param([string]$Root)

    $cliPath = Join-Path $Root "01_UI\terminal\hia.ps1"
    $livePath = Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt"

    if (-not (Test-Path $cliPath)) {
        Write-TestResult -Component "State" -Test "hia state command" -Passed $false -Message "CLI not found"
        return $false
    }

    $allPassed = $true

    $stateOutput = & pwsh -NoProfile -File $cliPath state 2>&1
    $stateOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "State" -Test "hia state command" -Passed $stateOk
    if (-not $stateOk) { $allPassed = $false }

    $syncStart = (Get-Date).ToUniversalTime().AddSeconds(-1)
    $syncOutput = & pwsh -NoProfile -File $cliPath state sync 2>&1
    $syncOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "State" -Test "hia state sync command" -Passed $syncOk
    if (-not $syncOk) { $allPassed = $false }

    $liveExists = Test-Path $livePath
    Write-TestResult -Component "State" -Test "PROJECT.STATE.LIVE exists" -Passed $liveExists -Message $livePath
    if (-not $liveExists) { $allPassed = $false }

    if ($liveExists) {
        $syncTouchedLive = (Get-Item $livePath).LastWriteTimeUtc -ge $syncStart
        Write-TestResult -Component "State" -Test "state sync updates LIVE timestamp" -Passed $syncTouchedLive
        if (-not $syncTouchedLive) { $allPassed = $false }

        $liveContent = Get-Content -Path $livePath -Raw

        $hasMvp = $liveContent -match '(?m)^MVP_ACTIVO\s*$'
        Write-TestResult -Component "State" -Test "LIVE contains MVP_ACTIVO" -Passed $hasMvp
        if (-not $hasMvp) { $allPassed = $false }

        $hasNextStep = $liveContent -match '(?m)^PROXIMO_PASO\s*$'
        Write-TestResult -Component "State" -Test "LIVE contains PROXIMO_PASO" -Passed $hasNextStep
        if (-not $hasNextStep) { $allPassed = $false }
    }

    return $allPassed
}

function Test-SessionEngineFlow {
    param([string]$Root)

    $cliPath = Join-Path $Root "01_UI\terminal\hia.ps1"
    $sessionsDir = Join-Path $Root "03_ARTIFACTS\sessions"
    $activeSessionPath = Join-Path $sessionsDir "ACTIVE_SESSION.json"
    $legacyActiveSessionPath = Join-Path $sessionsDir "SESSION.ACTIVE.json"
    $livePath = Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt"

    if (-not (Test-Path $cliPath)) {
        Write-TestResult -Component "Session" -Test "CLI exists for session flow" -Passed $false
        return $false
    }

    $allPassed = $true

    if ((Test-Path $activeSessionPath) -or (Test-Path $legacyActiveSessionPath)) {
        $null = & pwsh -NoProfile -File $cliPath session close -NoGitCheckpoint -Message "Smoke pre-clean" 2>&1
    }

    $jsonBefore = @(Get-ChildItem -Path $sessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue).Count
    $logBefore = @(Get-ChildItem -Path $sessionsDir -Filter "SESSION_*.log.txt" -File -ErrorAction SilentlyContinue).Count

    $startOutput = & pwsh -NoProfile -File $cliPath session start 2>&1
    $startOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Session" -Test "hia session start" -Passed $startOk
    if (-not $startOk) { $allPassed = $false }

    $activeExists = Test-Path $activeSessionPath
    Write-TestResult -Component "Session" -Test "ACTIVE_SESSION.json created" -Passed $activeExists -Message $activeSessionPath
    if (-not $activeExists) { $allPassed = $false }

    $statusOutput = & pwsh -NoProfile -File $cliPath session status 2>&1
    $statusOk = ($LASTEXITCODE -eq 0) -and (($statusOutput -join "`n") -match "STATUS:\s*active")
    Write-TestResult -Component "Session" -Test "hia session status (active)" -Passed $statusOk
    if (-not $statusOk) { $allPassed = $false }

    $logOutput = & pwsh -NoProfile -File $cliPath session log -Message "Smoke session log" 2>&1
    $logOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Session" -Test "hia session log" -Passed $logOk
    if (-not $logOk) { $allPassed = $false }

    $closeStart = (Get-Date).ToUniversalTime().AddSeconds(-1)
    $closeOutput = & pwsh -NoProfile -File $cliPath session close -NoGitCheckpoint -Message "Smoke session close" 2>&1
    $closeOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Session" -Test "hia session close" -Passed $closeOk
    if (-not $closeOk) { $allPassed = $false }

    $activeCleared = (-not (Test-Path $activeSessionPath)) -and (-not (Test-Path $legacyActiveSessionPath))
    Write-TestResult -Component "Session" -Test "active session cleared" -Passed $activeCleared
    if (-not $activeCleared) { $allPassed = $false }

    $jsonAfter = @(Get-ChildItem -Path $sessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue).Count
    $logAfter = @(Get-ChildItem -Path $sessionsDir -Filter "SESSION_*.log.txt" -File -ErrorAction SilentlyContinue).Count
    $archiveCreated = $jsonAfter -gt $jsonBefore
    $logCreated = $logAfter -gt $logBefore
    Write-TestResult -Component "Session" -Test "session summary artifact created" -Passed $archiveCreated
    Write-TestResult -Component "Session" -Test "session log artifact created" -Passed $logCreated
    if (-not $archiveCreated) { $allPassed = $false }
    if (-not $logCreated) { $allPassed = $false }

    $syncUpdatedLive = $false
    if (Test-Path $livePath) {
        $syncUpdatedLive = (Get-Item $livePath).LastWriteTimeUtc -ge $closeStart
    }
    Write-TestResult -Component "Session" -Test "close triggers state sync" -Passed $syncUpdatedLive
    if (-not $syncUpdatedLive) { $allPassed = $false }

    $statusNoSession = & pwsh -NoProfile -File $cliPath session status 2>&1
    $statusNoSessionOk = ($LASTEXITCODE -eq 0) -and (($statusNoSession -join "`n") -match "STATUS:\s*NONE")
    Write-TestResult -Component "Session" -Test "status without active session (controlled)" -Passed $statusNoSessionOk
    if (-not $statusNoSessionOk) { $allPassed = $false }

    $logNoSession = & pwsh -NoProfile -File $cliPath session log -Message "Should fail" 2>&1
    $logNoSessionExpectedFail = (($LASTEXITCODE -ne 0) -or (($logNoSession -join "`n") -match "No active session"))
    Write-TestResult -Component "Session" -Test "log without active session fails controlled" -Passed $logNoSessionExpectedFail
    if (-not $logNoSessionExpectedFail) { $allPassed = $false }

    $closeNoSession = & pwsh -NoProfile -File $cliPath session close -NoGitCheckpoint -Message "Should fail" 2>&1
    $closeNoSessionExpectedFail = (($LASTEXITCODE -ne 0) -or (($closeNoSession -join "`n") -match "No active session"))
    Write-TestResult -Component "Session" -Test "close without active session fails controlled" -Passed $closeNoSessionExpectedFail
    if (-not $closeNoSessionExpectedFail) { $allPassed = $false }

    if (Test-Path $livePath) {
        $liveContent = Get-Content -Path $livePath -Raw
        $hasMvp = $liveContent -match '(?m)^MVP_ACTIVO\s*$'
        $hasNextStep = $liveContent -match '(?m)^PROXIMO_PASO\s*$'
        Write-TestResult -Component "Session" -Test "LIVE keeps MVP_ACTIVO after close" -Passed $hasMvp
        Write-TestResult -Component "Session" -Test "LIVE keeps PROXIMO_PASO after close" -Passed $hasNextStep
        if (-not $hasMvp) { $allPassed = $false }
        if (-not $hasNextStep) { $allPassed = $false }
    }

    return $allPassed
}

function Test-ContextEngineFlow {
    param([string]$Root)

    $cliPath = Join-Path $Root "01_UI\terminal\hia.ps1"
    $packagePath = Join-Path $Root "03_ARTIFACTS\context\CONTEXT.PACKAGE.ACTIVE.json"
    $manifestPath = Join-Path $Root "03_ARTIFACTS\context\CONTEXT.MANIFEST.ACTIVE.txt"

    if (-not (Test-Path $cliPath)) {
        Write-TestResult -Component "Context" -Test "CLI exists for context flow" -Passed $false
        return $false
    }

    $allPassed = $true

    $packageBefore = $null
    if (Test-Path $packagePath) {
        $packageBefore = (Get-Item $packagePath).LastWriteTimeUtc
    }

    $manifestBefore = $null
    if (Test-Path $manifestPath) {
        $manifestBefore = (Get-Item $manifestPath).LastWriteTimeUtc
    }

    $buildStart = (Get-Date).ToUniversalTime().AddSeconds(-1)
    $buildOutput = & pwsh -NoProfile -File $cliPath context build 2>&1
    $buildOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Context" -Test "hia context build" -Passed $buildOk
    if (-not $buildOk) { $allPassed = $false }

    $packageExists = Test-Path $packagePath
    Write-TestResult -Component "Context" -Test "CONTEXT.PACKAGE.ACTIVE.json exists" -Passed $packageExists -Message $packagePath
    if (-not $packageExists) { $allPassed = $false }

    $manifestExists = Test-Path $manifestPath
    Write-TestResult -Component "Context" -Test "CONTEXT.MANIFEST.ACTIVE.txt exists" -Passed $manifestExists -Message $manifestPath
    if (-not $manifestExists) { $allPassed = $false }

    if ($packageExists) {
        $packageAfter = (Get-Item $packagePath).LastWriteTimeUtc
        $packageUpdated = ($packageAfter -ge $buildStart) -or ($packageBefore -and $packageAfter -gt $packageBefore)
        Write-TestResult -Component "Context" -Test "context build updates package artifact" -Passed $packageUpdated
        if (-not $packageUpdated) { $allPassed = $false }
    }

    if ($manifestExists) {
        $manifestAfter = (Get-Item $manifestPath).LastWriteTimeUtc
        $manifestUpdated = ($manifestAfter -ge $buildStart) -or ($manifestBefore -and $manifestAfter -gt $manifestBefore)
        Write-TestResult -Component "Context" -Test "context build updates manifest artifact" -Passed $manifestUpdated
        if (-not $manifestUpdated) { $allPassed = $false }
    }

    if ($packageExists) {
        try {
            $package = Get-Content -Path $packagePath -Raw | ConvertFrom-Json

            $hasFocus = -not [string]::IsNullOrWhiteSpace([string]$package.focus_actual)
            Write-TestResult -Component "Context" -Test "package contains focus_actual" -Passed $hasFocus
            if (-not $hasFocus) { $allPassed = $false }

            $hasContextLevel = -not [string]::IsNullOrWhiteSpace([string]$package.context_level)
            Write-TestResult -Component "Context" -Test "package contains context_level" -Passed $hasContextLevel
            if (-not $hasContextLevel) { $allPassed = $false }
        }
        catch {
            Write-TestResult -Component "Context" -Test "package is valid JSON" -Passed $false -Message $_.Exception.Message
            $allPassed = $false
        }
    }

    return $allPassed
}

function Test-AIRouterFlow {
    param([string]$Root)

    $cliPath = Join-Path $Root "01_UI\terminal\hia.ps1"
    $logPath = Join-Path $Root "03_ARTIFACTS\LOGS\HIA_ROUTER.log"
    $routingRegistryPath = Join-Path $Root "02_TOOLS\MODEL.ROUTING.REGISTRY.json"

    if (-not (Test-Path $cliPath)) {
        Write-TestResult -Component "AI Router" -Test "CLI exists for router flow" -Passed $false
        return $false
    }

    function Convert-HIAJsonFromOutput {
        param([object[]]$Output)

        $lines = @($Output | ForEach-Object { $_.ToString() })
        $start = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq "{") {
                $start = $i
                break
            }
        }

        if ($start -lt 0) {
            return $null
        }

        $jsonText = ($lines[$start..($lines.Count - 1)] -join "`n").Trim()
        try {
            return ($jsonText | ConvertFrom-Json)
        }
        catch {
            return $null
        }
    }

    $allPassed = $true
    $beforeLogLines = 0
    if (Test-Path $logPath) {
        $beforeLogLines = @(Get-Content -Path $logPath).Count
    }

    $registryExists = Test-Path $routingRegistryPath
    Write-TestResult -Component "AI Router" -Test "MODEL.ROUTING.REGISTRY.json exists" -Passed $registryExists -Message $routingRegistryPath
    if (-not $registryExists) { $allPassed = $false }

    $policyOutput = & pwsh -NoProfile -File $cliPath ai show-policy 2>&1
    $policyOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "AI Router" -Test "hia ai show-policy" -Passed $policyOk
    if (-not $policyOk) { $allPassed = $false }

    $policyJson = Convert-HIAJsonFromOutput -Output $policyOutput
    $policyStructured = ($null -ne $policyJson -and $null -ne $policyJson.providers)
    Write-TestResult -Component "AI Router" -Test "show-policy returns structured registry" -Passed $policyStructured
    if (-not $policyStructured) { $allPassed = $false }

    $reasoningOutput = & pwsh -NoProfile -File $cliPath ai route -TaskType reasoning -TaskPrompt "Explain architecture tradeoffs" 2>&1
    $reasoningOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "AI Router" -Test "hia ai route reasoning" -Passed $reasoningOk
    if (-not $reasoningOk) { $allPassed = $false }

    $reasoningJson = Convert-HIAJsonFromOutput -Output $reasoningOutput
    $reasoningStructured = (
        $null -ne $reasoningJson -and
        -not [string]::IsNullOrWhiteSpace([string]$reasoningJson.selected_provider) -and
        -not [string]::IsNullOrWhiteSpace([string]$reasoningJson.execution_mode)
    )
    Write-TestResult -Component "AI Router" -Test "reasoning route returns provider + execution_mode" -Passed $reasoningStructured
    if (-not $reasoningStructured) { $allPassed = $false }

    $codeOutput = & pwsh -NoProfile -File $cliPath ai route -TaskType code -TaskPrompt "Refactor parser function" 2>&1
    $codeOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "AI Router" -Test "hia ai route code" -Passed $codeOk
    if (-not $codeOk) { $allPassed = $false }

    $codeJson = Convert-HIAJsonFromOutput -Output $codeOutput
    $codeStructured = (
        $null -ne $codeJson -and
        -not [string]::IsNullOrWhiteSpace([string]$codeJson.selected_provider) -and
        -not [string]::IsNullOrWhiteSpace([string]$codeJson.execution_mode)
    )
    Write-TestResult -Component "AI Router" -Test "code route returns provider + execution_mode" -Passed $codeStructured
    if (-not $codeStructured) { $allPassed = $false }

    $localToolOutput = & pwsh -NoProfile -File $cliPath ai route -TaskType local_tool -TaskPrompt "git status" 2>&1
    $localToolOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "AI Router" -Test "hia ai route local_tool" -Passed $localToolOk
    if (-not $localToolOk) { $allPassed = $false }

    $localToolJson = Convert-HIAJsonFromOutput -Output $localToolOutput
    $localToolStructured = (
        $null -ne $localToolJson -and
        -not [string]::IsNullOrWhiteSpace([string]$localToolJson.selected_provider) -and
        -not [string]::IsNullOrWhiteSpace([string]$localToolJson.execution_mode)
    )
    Write-TestResult -Component "AI Router" -Test "local_tool route returns provider + execution_mode" -Passed $localToolStructured
    if (-not $localToolStructured) { $allPassed = $false }

    $logExists = Test-Path $logPath
    Write-TestResult -Component "AI Router" -Test "HIA_ROUTER.log exists" -Passed $logExists -Message $logPath
    if (-not $logExists) { $allPassed = $false }

    if ($logExists) {
        $afterLogLines = @(Get-Content -Path $logPath).Count
        $logGrew = $afterLogLines -gt $beforeLogLines
        Write-TestResult -Component "AI Router" -Test "router appends log entry" -Passed $logGrew
        if (-not $logGrew) { $allPassed = $false }
    }

    return $allPassed
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HIA SMOKE TEST" -ForegroundColor Cyan
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROJECT_ROOT: $ProjectRoot"
Write-Host ""

$precheckResults = @()
$executionResults = @()

Write-Host "PRECHECK (MINIMAL)" -ForegroundColor Yellow
$precheckResults += Test-CLIEntrypoint -Root $ProjectRoot
$precheckResults += Test-ToolRegistry -Root $ProjectRoot
$precheckResults += Test-AgentRegistry -Root $ProjectRoot
Write-Host ""

$canExecute = ($precheckResults[0] -eq $true)

if ($canExecute) {
    Write-Host "EXECUTION SMOKE (SYSTEM BEHAVIOR)" -ForegroundColor Yellow
    $executionResults += Test-StateEngineFlow -Root $ProjectRoot
    $executionResults += Test-SessionEngineFlow -Root $ProjectRoot
    $executionResults += Test-ContextEngineFlow -Root $ProjectRoot
    $executionResults += Test-AIRouterFlow -Root $ProjectRoot
}
else {
    Write-TestResult -Component "Precheck" -Test "execution smoke enabled" -Passed $false -Message "CLI/router unavailable"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

$precheckTotal = @($precheckResults).Count
$precheckPassed = @($precheckResults | Where-Object { $_ -eq $true }).Count
$precheckFailed = $precheckTotal - $precheckPassed

$executionTotal = @($executionResults).Count
$executionPassed = @($executionResults | Where-Object { $_ -eq $true }).Count
$executionFailed = $executionTotal - $executionPassed

$systemStatus = "FAIL"
if ($executionTotal -gt 0 -and $executionFailed -eq 0 -and $precheckFailed -eq 0) {
    $systemStatus = "HEALTHY"
}
elseif ($executionPassed -gt 0) {
    $systemStatus = "DEGRADED"
}

Write-Host "PRECHECK TOTAL:    $precheckTotal"
Write-Host "PRECHECK PASSED:   $precheckPassed"
Write-Host "PRECHECK FAILED:   $precheckFailed"
Write-Host "EXECUTION TOTAL:   $executionTotal"
Write-Host "EXECUTION PASSED:  $executionPassed"
Write-Host "EXECUTION FAILED:  $executionFailed"
Write-Host "SYSTEM STATUS:     $systemStatus" -ForegroundColor $(
    if ($systemStatus -eq "HEALTHY") { "Green" }
    elseif ($systemStatus -eq "DEGRADED") { "Yellow" }
    else { "Red" }
)

if ($systemStatus -eq "HEALTHY") {
    Write-Host " SMOKE TEST: PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}
else {
    Write-Host " SMOKE TEST: FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
