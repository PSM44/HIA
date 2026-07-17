#requires -Version 5.1
<#
===============================================================================
SCRIPT: HIA_TOL_0041_Start-Session.ps1
SYSTEM: HIA — Human Intelligence Amplifier
TYPE: LEGACY COMPATIBILITY ADAPTER
PURPOSE: Delegate project-scoped session start to HIA_PROJECT_ENGINE.
VERSION: v2.0-B3-B2B1
===============================================================================

This wrapper is retained for compatibility only.

It does not:
- create or switch Git branches;
- stage files;
- commit;
- push;
- execute RADAR;
- create a global session.

The authoritative runtime owner is HIA_PROJECT_ENGINE.ps1.
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = 'C:\01. GitHub\Wings3.0\01_PROJECTS\HIA',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-HIARepositoryRoot {
    param([string]$CandidateRoot)

    if ([string]::IsNullOrWhiteSpace($CandidateRoot)) {
        throw 'ProjectRoot is required.'
    }

    $resolved = (Resolve-Path -LiteralPath $CandidateRoot -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath (Join-Path $resolved '02_TOOLS') -PathType Container)) {
        throw "INVALID_PROJECT_ROOT | $resolved"
    }

    return $resolved
}

$repositoryRoot = Resolve-HIARepositoryRoot -CandidateRoot $ProjectRoot
$enginePath = Join-Path $repositoryRoot '02_TOOLS\HIA_PROJECT_ENGINE.ps1'

if (-not (Test-Path -LiteralPath $enginePath -PathType Leaf)) {
    throw "PROJECT_ENGINE_NOT_FOUND | $enginePath"
}

. $enginePath

if (-not (Get-Command Start-HIAProjectSession -CommandType Function -ErrorAction SilentlyContinue)) {
    throw 'PROJECT_SESSION_START_FUNCTION_NOT_AVAILABLE'
}

Write-Host ''
Write-Host 'HIA PROJECT SESSION START — COMPATIBILITY ADAPTER'
Write-Host "PROJECT_ID=$ProjectId"
Write-Host 'MODE=PROJECT_SCOPED'
Write-Host 'GIT_MUTATION=NO'
Write-Host 'RADAR_EXECUTED=NO'
Write-Host 'PUSH_EXECUTED=NO'

Start-HIAProjectSession -ProjectId $ProjectId

Write-Host 'FINAL_STATUS=PASS_DELEGATED_PROJECT_SESSION_START'
$global:HIA_EXIT_CODE = 0
