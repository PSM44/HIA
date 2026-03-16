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
# EXECUTE
# -----------------------------------------------------------------------------

Invoke-HIARouter -Command $Command -Args $RouterArgs


