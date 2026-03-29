<#
===============================================================================
HIA CLI ENTRYPOINT
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RouterArgs
)

# -----------------------------------------------------------------------------
# NORMALIZE COMMAND (ANTI "hia apply" ERROR)
# -----------------------------------------------------------------------------

if ($Command -eq "hia" -and $RouterArgs.Count -gt 0) {
    $Command = $RouterArgs[0]
    if ($RouterArgs.Count -gt 1) {
        $RouterArgs = $RouterArgs[1..($RouterArgs.Count - 1)]
    } else {
        $RouterArgs = @()
    }
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# HEADER
# -----------------------------------------------------------------------------

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " HIA — Human Intelligence Amplifier"
Write-Host " CLI Interface"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# RESOLVE PROJECT ROOT
# -----------------------------------------------------------------------------

$current = $PSScriptRoot

while ($true) {

    if (Test-Path (Join-Path $current "02_TOOLS")) {
        $projectRoot = $current
        break
    }

    $parent = Split-Path $current -Parent

    if ($parent -eq $current) {
        throw "PROJECT_ROOT not found."
    }

    $current = $parent

}

# -----------------------------------------------------------------------------
# LOAD ROUTER
# -----------------------------------------------------------------------------

$routerPath = Join-Path $projectRoot "02_TOOLS\HIA_ROUTER.ps1"
if (-not (Test-Path $routerPath)) {
    throw "Router not found."
}

. $routerPath

# -----------------------------------------------------------------------------
# PARSE COMMAND
# -----------------------------------------------------------------------------

if (-not $Command) {

    Show-HIAHelp
    exit

}

if (-not $RouterArgs) {
    $RouterArgs = @()
}

# -----------------------------------------------------------------------------
# DIRECT HOOKS
# -----------------------------------------------------------------------------

if ($Command.ToLowerInvariant() -eq "agile") {
    $agileEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_AGILE_ENGINE.ps1"
    if (-not (Test-Path $agileEnginePath)) {
        throw "Agile engine not found."
    }

    & $agileEnginePath @RouterArgs
    $engineExitCode = 0
    $lastExit = Get-Variable -Name LASTEXITCODE -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $lastExit) {
        $engineExitCode = [int]$lastExit
    }
    exit $engineExitCode
}

# -----------------------------------------------------------------------------
# EXECUTE
# -----------------------------------------------------------------------------

try {
    Invoke-HIARouter -Command $Command -Args $RouterArgs
    exit 0
}
catch {
    Write-Host ""
    Write-Host "HIA CLI ERROR" -ForegroundColor Red
    Write-Host ("MESSAGE: {0}" -f $_.Exception.Message) -ForegroundColor Red

    if ($_.InvocationInfo) {
        Write-Host ("SCRIPT:  {0}" -f $_.InvocationInfo.ScriptName) -ForegroundColor DarkRed
        Write-Host ("LINE:    {0}" -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor DarkRed
        Write-Host ("COMMAND: {0}" -f $_.InvocationInfo.Line.Trim()) -ForegroundColor DarkRed
    }

    Write-Host ""
    exit 1
}


