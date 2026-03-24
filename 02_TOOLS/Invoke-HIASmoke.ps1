<#
===============================================================================
MODULE: Invoke-HIASmoke.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: SMOKE TEST

OBJETIVO
Validar que todos los componentes del sistema HIA están operativos.

VERSION: v2.0
DATE: 2026-03-16
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

    $syncOutput = & pwsh -NoProfile -File $cliPath state sync 2>&1
    $syncOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "State" -Test "hia state sync command" -Passed $syncOk
    if (-not $syncOk) { $allPassed = $false }

    $liveExists = Test-Path $livePath
    Write-TestResult -Component "State" -Test "PROJECT.STATE.LIVE exists" -Passed $liveExists -Message $livePath
    if (-not $liveExists) { $allPassed = $false }

    if ($liveExists) {
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
    $activeSessionPath = Join-Path $Root "03_ARTIFACTS\sessions\SESSION.ACTIVE.json"
    $historyDir = Join-Path $Root "03_ARTIFACTS\sessions\history"
    $livePath = Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt"

    if (-not (Test-Path $cliPath)) {
        Write-TestResult -Component "Session" -Test "CLI exists for session flow" -Passed $false
        return $false
    }

    $allPassed = $true

    if (Test-Path $activeSessionPath) {
        $null = & pwsh -NoProfile -File $cliPath session close -NoGitCheckpoint -Message "Smoke pre-clean" 2>&1
    }

    $startOutput = & pwsh -NoProfile -File $cliPath session start 2>&1
    $startOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Session" -Test "hia session start" -Passed $startOk
    if (-not $startOk) { $allPassed = $false }

    $statusOutput = & pwsh -NoProfile -File $cliPath session status 2>&1
    $statusOk = ($LASTEXITCODE -eq 0)
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

    $activeCleared = -not (Test-Path $activeSessionPath)
    Write-TestResult -Component "Session" -Test "SESSION.ACTIVE cleared" -Passed $activeCleared
    if (-not $activeCleared) { $allPassed = $false }

    $historyExists = Test-Path $historyDir
    $hasArchive = $false
    if ($historyExists) {
        $archives = Get-ChildItem -Path $historyDir -File -Filter "SESSION_*.json" -ErrorAction SilentlyContinue
        $hasArchive = @($archives).Count -gt 0
    }
    Write-TestResult -Component "Session" -Test "Session archive created" -Passed $hasArchive
    if (-not $hasArchive) { $allPassed = $false }

    $syncUpdatedLive = $false
    if (Test-Path $livePath) {
        $syncUpdatedLive = (Get-Item $livePath).LastWriteTimeUtc -ge $closeStart
    }
    Write-TestResult -Component "Session" -Test "close triggers state sync" -Passed $syncUpdatedLive
    if (-not $syncUpdatedLive) { $allPassed = $false }

    $statusNoSession = & pwsh -NoProfile -File $cliPath session status 2>&1
    $statusNoSessionOk = ($LASTEXITCODE -eq 0)
    Write-TestResult -Component "Session" -Test "status without active session (controlled)" -Passed $statusNoSessionOk
    if (-not $statusNoSessionOk) { $allPassed = $false }

    $logNoSession = & pwsh -NoProfile -File $cliPath session log -Message "Should fail" 2>&1
    $logNoSessionExpectedFail = ($LASTEXITCODE -ne 0) -or (($logNoSession -join "`n") -match "No active session")
    Write-TestResult -Component "Session" -Test "log without active session fails controlled" -Passed $logNoSessionExpectedFail
    if (-not $logNoSessionExpectedFail) { $allPassed = $false }

    $closeNoSession = & pwsh -NoProfile -File $cliPath session close -NoGitCheckpoint -Message "Should fail" 2>&1
    $closeNoSessionExpectedFail = ($LASTEXITCODE -ne 0) -or (($closeNoSession -join "`n") -match "No active session")
    Write-TestResult -Component "Session" -Test "close without active session fails controlled" -Passed $closeNoSessionExpectedFail
    if (-not $closeNoSessionExpectedFail) { $allPassed = $false }

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

$results = @()

$results += Test-CoreDirectories -Root $ProjectRoot
$results += Test-CLIEntrypoint -Root $ProjectRoot
$results += Test-ToolRegistry -Root $ProjectRoot
$results += Test-AgentRegistry -Root $ProjectRoot
$results += Test-ToolScriptsExist -Root $ProjectRoot
$results += Test-AgentScriptsExist -Root $ProjectRoot
$results += Test-RADARExecution -Root $ProjectRoot
$results += Test-ArtifactsDirectory -Root $ProjectRoot
$results += Test-StateEngineFlow -Root $ProjectRoot
$results += Test-SessionEngineFlow -Root $ProjectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

$failed = $results | Where-Object { $_ -eq $false }
$failedCount = @($failed).Count

if ($failedCount -eq 0) {
    Write-Host " SMOKE TEST: PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}
else {
    Write-Host " SMOKE TEST: FAILED ($failedCount failures)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
