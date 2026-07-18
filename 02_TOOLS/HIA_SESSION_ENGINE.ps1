#requires -Version 7.0
<#
MODULE: HIA_SESSION_ENGINE.ps1
ROLE: LEGACY_COMPATIBILITY_ADAPTER
STATUS: DEPRECATED_GLOBAL_RUNTIME

This adapter preserves the legacy entry point while delegating supported
session lifecycle commands to the project-scoped HIA_PROJECT_ENGINE.ps1.

Prohibited behavior:
- no global session state writes;
- no writes under 03_ARTIFACTS\sessions;
- no Git add/commit/push;
- no state sync;
- no RADAR;
- no BATON mutation.
#>

[CmdletBinding()]
param(
    [ValidateSet('start','status','log','close')]
    [string]$Command = 'status',

    [string]$ProjectRoot,

    [string]$ProjectId,

    [string]$Operator,

    [string]$Message,

    [switch]$GitCheckpoint,

    [switch]$NoGitCheckpoint
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HIARepositoryRoot {
    param([string]$CandidateRoot)

    if (-not [string]::IsNullOrWhiteSpace($CandidateRoot)) {
        $resolved = (Resolve-Path -LiteralPath $CandidateRoot).Path
        if (Test-Path -LiteralPath (Join-Path $resolved '02_TOOLS') -PathType Container) {
            return $resolved
        }
    }

    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current '02_TOOLS') -PathType Container) {
            return $current
        }

        $parent = Split-Path -Path $current -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current) {
            throw 'PROJECT_ROOT not found.'
        }

        $current = $parent
    }
}

function Assert-HIAProjectId {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "ProjectId is mandatory for legacy session command '$Command'."
    }
}

function ConvertTo-HIACommandSuccess {
    param([object]$Result)

    if ($Result -is [bool]) {
        return [bool]$Result
    }

    return $true
}

$script:RepositoryRoot = Get-HIARepositoryRoot -CandidateRoot $ProjectRoot
$script:ProjectEnginePath = Join-Path $script:RepositoryRoot '02_TOOLS\HIA_PROJECT_ENGINE.ps1'

if (-not (Test-Path -LiteralPath $script:ProjectEnginePath -PathType Leaf)) {
    throw "HIA_PROJECT_ENGINE.ps1 not found: $script:ProjectEnginePath"
}

. $script:ProjectEnginePath

if ($GitCheckpoint -or $NoGitCheckpoint) {
    Write-Warning 'Git checkpoint flags are deprecated and ignored. Session lifecycle no longer performs Git mutations.'
}

Write-Warning 'HIA_SESSION_ENGINE.ps1 is a deprecated compatibility adapter. Use the project-scoped HIA project engine directly.'

$commandResult = $false

switch ($Command) {
    'start' {
        Assert-HIAProjectId -Value $ProjectId

        $invoke = @{ ProjectId = $ProjectId }
        $startCommand = Get-Command -Name Start-HIAProjectSession -CommandType Function -ErrorAction Stop

        if (-not [string]::IsNullOrWhiteSpace($Operator)) {
            if ($startCommand.Parameters.ContainsKey('OperatorName')) {
                $invoke['OperatorName'] = $Operator
            }
            elseif ($startCommand.Parameters.ContainsKey('Operator')) {
                $invoke['Operator'] = $Operator
            }
        }

        $result = Start-HIAProjectSession @invoke
        $commandResult = ConvertTo-HIACommandSuccess -Result $result
    }

    'status' {
        Assert-HIAProjectId -Value $ProjectId
        $result = Get-HIAProjectSessionStatus -ProjectId $ProjectId
        $commandResult = ConvertTo-HIACommandSuccess -Result $result
    }

    'close' {
        Assert-HIAProjectId -Value $ProjectId

        $invoke = @{ ProjectId = $ProjectId }
        $closeCommand = Get-Command -Name Close-HIAProjectSession -CommandType Function -ErrorAction Stop

        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            if ($closeCommand.Parameters.ContainsKey('Summary')) {
                $invoke['Summary'] = $Message
            }
            elseif ($closeCommand.Parameters.ContainsKey('SummaryMessage')) {
                $invoke['SummaryMessage'] = $Message
            }
        }

        $result = Close-HIAProjectSession @invoke
        $commandResult = ConvertTo-HIACommandSuccess -Result $result
    }

    'log' {
        Assert-HIAProjectId -Value $ProjectId
        Write-Error 'Legacy global session log is deprecated. Use project-scoped task, evidence, or memory artifacts.'
        $commandResult = $false
    }
}

$global:HIA_EXIT_CODE = if ($commandResult) { 0 } else { 1 }
exit $global:HIA_EXIT_CODE