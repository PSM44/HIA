<#
===============================================================================
MODULE: HIA_TASK_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: TASK ENGINE (MVP)

OBJETIVO
Implementar tareas simples y deterministas ejecutables desde CLI.

COMMANDS:
- create-file <relative_path>
- create-file-project <project_id> <relative_path>
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TaskCommand,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TaskArgs,

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIARepositoryRoot {
    param([string]$CandidateRoot)

    if (-not [string]::IsNullOrWhiteSpace($CandidateRoot)) {
        $resolved = (Resolve-Path -LiteralPath $CandidateRoot).Path
        if (Test-Path -LiteralPath (Join-Path $resolved "02_TOOLS")) {
            return $resolved
        }
    }

    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) {
            return $current
        }

        $parent = Split-Path -Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }

        $current = $parent
    }
}

function Test-HIAPathInsideRoot {
    param(
        [string]$RootPath,
        [string]$CandidatePath
    )

    $rootFull = [System.IO.Path]::GetFullPath($RootPath).TrimEnd('\', '/')
    $candidateFull = [System.IO.Path]::GetFullPath($CandidatePath)

    $comparison = [System.StringComparison]::OrdinalIgnoreCase
    if ($candidateFull.Equals($rootFull, $comparison)) {
        return $true
    }

    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($rootPrefix, $comparison)
}

function Write-HIATaskEvidence {
    param(
        [string]$LogsDir,
        [string]$TaskName,
        [string]$RelativeFilePath,
        [string]$AbsoluteFilePath,
        [string]$ProjectId,
        [string]$Result = "created",
        [string]$Message = ""
    )

    if (-not (Test-Path -LiteralPath $LogsDir)) {
        New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
    }

    $logPath = Join-Path $LogsDir "TASK.CREATE_FILE.log"
    $projectSegment = if ([string]::IsNullOrWhiteSpace($ProjectId)) { "" } else { (" | PROJECT_ID={0}" -f $ProjectId) }
    $msgSegment = if ([string]::IsNullOrWhiteSpace($Message)) { "" } else { (" | MSG={0}" -f $Message) }
    $line = "{0} | TASK={1} | RESULT={2}{3} | RELATIVE={4} | FILE={5} | OPERATOR={6}{7}" -f `
        (Get-Date).ToUniversalTime().ToString("o"), `
        $TaskName, `
        $Result, `
        $projectSegment, `
        $RelativeFilePath, `
        $AbsoluteFilePath, `
        $env:USERNAME, `
        $msgSegment

    Add-Content -Path $logPath -Value $line -Encoding UTF8
    return $logPath
}

function Write-HIAProjectLastActionSnapshot {
    param(
        [string]$ProjectRootPath,
        [string]$ProjectId,
        [string]$SourceTask,
        [string]$OutputPath,
        [string]$LogPath
    )

    $artifactsDir = Join-Path $ProjectRootPath "ARTIFACTS"
    if (-not (Test-Path -LiteralPath $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }

    $snapshotPath = Join-Path $artifactsDir "LAST.ACTION.json"
    $capturedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $payload = [ordered]@{
        project_id = $ProjectId
        source_task = $SourceTask
        output_path = $OutputPath
        log_path = $LogPath
        status = "created"
        captured_utc = $capturedUtc
    }

    $sessionPath = Join-Path $artifactsDir "SESSION.ACTIVE.json"
    if (Test-Path -LiteralPath $sessionPath -PathType Leaf) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
                $payload.session_id = [string]$session.session_id
            }
        }
        catch {
            # Keep snapshot minimal and deterministic even if session file is invalid.
        }
    }

    ($payload | ConvertTo-Json -Depth 4) | Set-Content -LiteralPath $snapshotPath -Encoding UTF8
    return $snapshotPath
}

function Invoke-HIATaskCreateFile {
    param(
        [string]$RepositoryRootPath,
        [string]$PathArgument
    )

    if ([string]::IsNullOrWhiteSpace($PathArgument)) {
        Write-Host "ERROR: Missing <relative_path>." -ForegroundColor Red
        Write-Host "Usage: hia task create-file <relative_path>" -ForegroundColor Yellow
        return $false
    }

    if ([System.IO.Path]::IsPathRooted($PathArgument)) {
        Write-Host "ERROR: Absolute paths are not allowed." -ForegroundColor Red
        return $false
    }

    if ($PathArgument.EndsWith("\") -or $PathArgument.EndsWith("/")) {
        Write-Host "ERROR: <relative_path> must include a file name." -ForegroundColor Red
        return $false
    }

    $candidatePath = Join-Path $RepositoryRootPath $PathArgument
    $targetPath = [System.IO.Path]::GetFullPath($candidatePath)

    if (-not (Test-HIAPathInsideRoot -RootPath $RepositoryRootPath -CandidatePath $targetPath)) {
        Write-Host "ERROR: Path is outside PROJECT_ROOT." -ForegroundColor Red
        return $false
    }

    $fileName = [System.IO.Path]::GetFileName($targetPath)
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        Write-Host "ERROR: Invalid file path." -ForegroundColor Red
        return $false
    }

    if (Test-Path -LiteralPath $targetPath) {
        Write-Host "ERROR: File already exists (no overwrite by default)." -ForegroundColor Red
        Write-Host ("FILE: {0}" -f $targetPath)
        return $false
    }

    $parentDir = Split-Path -Path $targetPath -Parent
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    $initialContent = @(
        "# HIA TASK OUTPUT"
        "task: create-file"
        ("created_utc: {0}" -f $timestampUtc)
        ("relative_path: {0}" -f $PathArgument)
        ""
    )

    Set-Content -LiteralPath $targetPath -Value $initialContent -Encoding UTF8
    $logsDir = Join-Path $RepositoryRootPath "03_ARTIFACTS\LOGS"
    $logPath = Write-HIATaskEvidence -LogsDir $logsDir -TaskName "create-file" -RelativeFilePath $PathArgument -AbsoluteFilePath $targetPath -ProjectId "" -Result "created"

    Write-Host ""
    Write-Host "HIA TASK EXECUTED" -ForegroundColor Green
    Write-Host "TASK: create-file"
    Write-Host ("RELATIVE_PATH: {0}" -f $PathArgument)
    Write-Host ("FILE_CREATED: {0}" -f $targetPath)
    Write-Host ("EVIDENCE: {0}" -f $logPath)
    Write-Host ""

    return $true
}

function Invoke-HIATaskCreateFileProject {
    param(
        [string]$RepositoryRootPath,
        [string]$ProjectId,
        [string]$PathArgument
    )

    function Resolve-HIAProjectSafeTaskPath {
        param(
            [string]$ProjectRoot,
            [string]$RelativePath
        )

        if ([string]::IsNullOrWhiteSpace($RelativePath)) {
            throw "Missing <relative_path>."
        }

        if ([System.IO.Path]::IsPathRooted($RelativePath)) {
            throw "Absolute paths are not allowed."
        }

        if ($RelativePath -match "(^|[\\/])\.\.(?:[\\/$]|$)") {
            throw "Traversal (.. or variants) is not allowed."
        }

        $trimmed = $RelativePath.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -eq "." -or $trimmed -eq "./" -or $trimmed -eq ".\\" ) {
            throw "Invalid <relative_path> (empty/placeholder)."
        }

        $segments = $RelativePath -split '[\\/]'
        $reserved = @("CON","PRN","AUX","NUL","COM1","COM2","COM3","COM4","COM5","COM6","COM7","COM8","COM9","LPT1","LPT2","LPT3","LPT4","LPT5","LPT6","LPT7","LPT8","LPT9")
        foreach ($seg in $segments) {
            if ([string]::IsNullOrWhiteSpace($seg)) { continue }
            if ($seg -match "[\.\s]$") {
                throw "Path segment ends with dot or space: '$seg'."
            }
            if ($seg.TrimEnd() -ne $seg) {
                throw "Path segment ends with dot or space: '$seg'."
            }
            $lastDot = $seg.LastIndexOf(".")
            $baseName = if ($lastDot -gt 0) { $seg.Substring(0, $lastDot) } else { $seg }
            if ($baseName -match "[\.\s]$") {
                throw "Basename ends with dot or space: '$seg'."
            }
            if ($reserved -contains $baseName.ToUpperInvariant()) {
                throw ("Reserved device name not allowed: '{0}'." -f $seg)
            }
        }

        # normalize target
        $candidatePath = Join-Path $ProjectRoot $RelativePath
        $targetPath = [System.IO.Path]::GetFullPath($candidatePath)

        if (-not (Test-HIAPathInsideRoot -RootPath $ProjectRoot -CandidatePath $targetPath)) {
            throw "Path is outside project root."
        }

        $relativeInside = $targetPath.Substring([System.IO.Path]::GetFullPath($ProjectRoot).Length).TrimStart('\','/')
        $allowedPrefix = "ARTIFACTS{0}TASKS" -f [System.IO.Path]::DirectorySeparatorChar
        $allowedAltPrefix = "ARTIFACTS/TASKS"

        if (-not ($relativeInside.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase) `
                -or $relativeInside.StartsWith($allowedAltPrefix, [System.StringComparison]::OrdinalIgnoreCase))) {
            throw ("Path must reside under ARTIFACTS{0}TASKS inside the project." -f [System.IO.Path]::DirectorySeparatorChar)
        }

        $fileName = [System.IO.Path]::GetFileName($targetPath)
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            throw "Invalid file path (missing file name)."
        }

        return $targetPath
    }

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        Write-Host "ERROR: Missing <project_id>." -ForegroundColor Red
        Write-Host "Usage: hia task create-file-project <project_id> <relative_path>" -ForegroundColor Yellow
        $global:HIA_EXIT_CODE = 2
        return $false
    }

    # entry-boundary hygiene on raw argument
    if ([string]::IsNullOrWhiteSpace($PathArgument)) {
        Write-Host "ERROR: Missing <relative_path>." -ForegroundColor Red
        Write-Host "Usage: hia task create-file-project <project_id> <relative_path>" -ForegroundColor Yellow
        $global:HIA_EXIT_CODE = 2
        return $false
    }
    $trimmedArg = $PathArgument.Trim()
    if (-not $PathArgument.Equals($trimmedArg, [System.StringComparison]::Ordinal)) {
        Write-Host "ERROR: <relative_path> has leading/trailing whitespace; provide a canonical path." -ForegroundColor Red
        $global:HIA_EXIT_CODE = 2
        return $false
    }

    $projectEnginePath = Join-Path $RepositoryRootPath "02_TOOLS\HIA_PROJECT_ENGINE.ps1"
    if (-not (Test-Path -LiteralPath $projectEnginePath)) {
        Write-Host ("ERROR: Project engine not found: {0}" -f $projectEnginePath) -ForegroundColor Red
        $global:HIA_EXIT_CODE = 1
        return $false
    }

    . $projectEnginePath

    if (-not (Get-Command Resolve-HIAProjectRoot -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Resolve-HIAProjectRoot is not available." -ForegroundColor Red
        return $false
    }

    $projectRootPath = $null
    try {
        $projectRootPath = Resolve-HIAProjectRoot -ProjectId $ProjectId
    }
    catch {
        Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        if ($_.Exception.Message -match "not found") { $global:HIA_EXIT_CODE = 3 } else { $global:HIA_EXIT_CODE = 1 }
        return $false
    }

    $targetPath = $null
    try {
        $targetPath = Resolve-HIAProjectSafeTaskPath -ProjectRoot $projectRootPath -RelativePath $PathArgument
    }
    catch {
        Write-Host ("ERROR: {0}" -f $_.Exception.Message) -ForegroundColor Red
        # log rejection for visibility
        $logsDirFail = Join-Path $projectRootPath "ARTIFACTS\LOGS"
        Write-HIATaskEvidence -LogsDir $logsDirFail -TaskName "create-file-project" -RelativeFilePath $PathArgument -AbsoluteFilePath "N/A" -ProjectId $ProjectId -Result "rejected" -Message $_.Exception.Message | Out-Null
        $global:HIA_EXIT_CODE = 1
        return $false
    }

    if (Test-Path -LiteralPath $targetPath) {
        Write-Host "ERROR: File already exists (no overwrite by default)." -ForegroundColor Red
        Write-Host ("FILE: {0}" -f $targetPath)
        $global:HIA_EXIT_CODE = 1
        return $false
    }

    $parentDir = Split-Path -Path $targetPath -Parent
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    $initialContent = @(
        "# HIA PROJECT TASK OUTPUT"
        "task: create-file-project"
        ("project_id: {0}" -f $ProjectId)
        ("created_utc: {0}" -f $timestampUtc)
        ("relative_path: {0}" -f $PathArgument)
        ""
    )

    Set-Content -LiteralPath $targetPath -Value $initialContent -Encoding UTF8

    $logsDir = Join-Path $projectRootPath "ARTIFACTS\LOGS"
    $logPath = Write-HIATaskEvidence -LogsDir $logsDir -TaskName "create-file-project" -RelativeFilePath $PathArgument -AbsoluteFilePath $targetPath -ProjectId $ProjectId -Result "created"
    $lastActionSnapshotPath = Write-HIAProjectLastActionSnapshot -ProjectRootPath $projectRootPath -ProjectId $ProjectId -SourceTask "create-file-project" -OutputPath $targetPath -LogPath $logPath

    Write-Host ""
    Write-Host "HIA TASK EXECUTED" -ForegroundColor Green
    Write-Host "TASK: create-file-project"
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("PROJECT_ROOT: {0}" -f $projectRootPath)
    Write-Host ("RELATIVE_PATH: {0}" -f $PathArgument)
    Write-Host ("FILE_CREATED: {0}" -f $targetPath)
    Write-Host ("EVIDENCE: {0}" -f $logPath)
    Write-Host ("LAST_ACTION_SNAPSHOT: {0}" -f $lastActionSnapshotPath)
    Write-Host ""

    $global:HIA_EXIT_CODE = 0
    return $true
}

$resolvedProjectRoot = Get-HIARepositoryRoot -CandidateRoot $ProjectRoot
$normalizedTask = if ($null -eq $TaskCommand) { "" } else { $TaskCommand.ToLowerInvariant() }

$ok = $false

switch ($normalizedTask) {
    "create-file" {
        $pathArgument = if ($TaskArgs.Count -ge 1) { $TaskArgs[0] } else { "" }
        $ok = Invoke-HIATaskCreateFile -RepositoryRootPath $resolvedProjectRoot -PathArgument $pathArgument
    }
    "create-file-project" {
        $projectId = if ($TaskArgs.Count -ge 1) { $TaskArgs[0] } else { "" }
        $pathArgument = if ($TaskArgs.Count -ge 2) { $TaskArgs[1] } else { "" }
        $ok = Invoke-HIATaskCreateFileProject -RepositoryRootPath $resolvedProjectRoot -ProjectId $projectId -PathArgument $pathArgument
    }
    default {
        Write-Host "ERROR: Unknown task command '$TaskCommand'." -ForegroundColor Red
        Write-Host "Usage: hia task create-file <relative_path>" -ForegroundColor Yellow
        Write-Host "Usage: hia task create-file-project <project_id> <relative_path>" -ForegroundColor Yellow
        $ok = $false
        $global:HIA_EXIT_CODE = 2
    }
}

$hintExit = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
if ($null -eq $hintExit) {
    $global:HIA_EXIT_CODE = if ($ok) { 0 } else { 1 }
}

exit $global:HIA_EXIT_CODE
