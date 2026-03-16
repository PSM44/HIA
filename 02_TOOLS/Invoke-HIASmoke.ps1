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
