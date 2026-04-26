[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-HIABanner {
    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host " HIA EXECUTION ENGINE" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-HIAProjectRoot {
    $toolsRoot = Split-Path -Path $PSCommandPath -Parent
    return [System.IO.Path]::GetFullPath((Join-Path $toolsRoot ".."))
}

function Write-HIAResult {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "FAIL")]
        [string]$Result,
        [Parameter(Mandatory = $true)]
        [int]$ExitCode
    )

    Write-Host ""
    Write-Host ("RESULT: {0}" -f $Result)
    Write-Host ("EXIT_CODE: {0}" -f $ExitCode)
}

function Test-HIACommandAvailable {
    param([Parameter(Mandatory = $true)][string]$CommandName)
    return $null -ne (Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}

function Invoke-HIAPreflight {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $ok = $true

    if (Test-Path -LiteralPath $ProjectRoot -PathType Container) {
        Write-Host ("OK: project root found -> {0}" -f $ProjectRoot)
    }
    else {
        Write-Host ("FAIL: project root missing -> {0}" -f $ProjectRoot) -ForegroundColor Red
        $ok = $false
    }

    $cliPath = Join-Path $ProjectRoot "01_UI\terminal\hia.ps1"
    if (Test-Path -LiteralPath $cliPath -PathType Leaf) {
        Write-Host ("OK: CLI found -> {0}" -f $cliPath)
    }
    else {
        Write-Host ("FAIL: CLI missing -> {0}" -f $cliPath) -ForegroundColor Red
        $ok = $false
    }

    $toolsPath = Join-Path $ProjectRoot "02_TOOLS"
    if (Test-Path -LiteralPath $toolsPath -PathType Container) {
        Write-Host ("OK: tools folder found -> {0}" -f $toolsPath)
    }
    else {
        Write-Host ("FAIL: tools folder missing -> {0}" -f $toolsPath) -ForegroundColor Red
        $ok = $false
    }

    $radarPath = Join-Path $ProjectRoot "02_TOOLS\RADAR.ps1"
    if (Test-Path -LiteralPath $radarPath -PathType Leaf) {
        Write-Host ("OK: RADAR found -> {0}" -f $radarPath)
    }
    else {
        Write-Host ("FAIL: RADAR missing -> {0}" -f $radarPath) -ForegroundColor Red
        $ok = $false
    }

    if (Test-HIACommandAvailable -CommandName "git") {
        Write-Host "OK: git command available"
    }
    else {
        Write-Host "FAIL: git command not available" -ForegroundColor Red
        $ok = $false
    }

    if ($ok) { return 0 }
    return 1
}

function Invoke-HIARadar {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $radarPath = Join-Path $ProjectRoot "02_TOOLS\RADAR.ps1"
    if (-not (Test-Path -LiteralPath $radarPath -PathType Leaf)) {
        Write-Host "FAIL: RADAR.ps1 not found" -ForegroundColor Red
        return 1
    }

    Write-Host "Running RADAR..."
    $radarLines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $radarPath -RootPath $ProjectRoot); foreach ($line in $radarLines) { if ($null -ne $line) { Write-Host ([string]$line) } }
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("FAIL: radar exited with code {0}" -f $LASTEXITCODE) -ForegroundColor Red
        return 1
    }

    Write-Host "OK: radar completed"
    return 0
}

function Invoke-HIAValidate {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $validatorPath = Join-Path $ProjectRoot "02_TOOLS\Invoke-HIAValidators.ps1"
    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
        Write-Host "SKIPPED: Invoke-HIAValidators.ps1 not found" -ForegroundColor Yellow
        return 0
    }

    Write-Host "Running validators..."
    $validateLines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $validatorPath -ProjectRoot $ProjectRoot -Mode DRAFT); foreach ($line in $validateLines) { if ($null -ne $line) { Write-Host ([string]$line) } }
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("FAIL: validate exited with code {0}" -f $LASTEXITCODE) -ForegroundColor Red
        return 1
    }

    Write-Host "OK: validate completed"
    return 0
}

function Invoke-HIASync {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $syncPath = Join-Path $ProjectRoot "02_TOOLS\Invoke-HIASync.ps1"
    if (-not (Test-Path -LiteralPath $syncPath -PathType Leaf)) {
        Write-Host "SKIPPED: Invoke-HIASync.ps1 not found" -ForegroundColor Yellow
        return 0
    }

    Write-Host "Running sync..."
    $syncLines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $syncPath -ProjectRoot $ProjectRoot -Action Apply); foreach ($line in $syncLines) { if ($null -ne $line) { Write-Host ([string]$line) } }
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("FAIL: sync exited with code {0}" -f $LASTEXITCODE) -ForegroundColor Red
        return 1
    }

    Write-Host "OK: sync completed"
    return 0
}

function Invoke-HIASyncCheck {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $syncPath = Join-Path $ProjectRoot "02_TOOLS\Invoke-HIASync.ps1"
    if (-not (Test-Path -LiteralPath $syncPath -PathType Leaf)) {
        Write-Host "SKIPPED: Invoke-HIASync.ps1 not found" -ForegroundColor Yellow
        return 0
    }

    Write-Host "Running sync integrity check (markers + source docs)..."
    $syncCheckLines = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $syncPath -ProjectRoot $ProjectRoot -Action Check); foreach ($line in $syncCheckLines) { if ($null -ne $line) { Write-Host ([string]$line) } }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FAIL: sync integrity check failed" -ForegroundColor Red
        return 1
    }

    Write-Host "OK: sync integrity check passed"
    return 0
}

function Invoke-HIAGitStatus {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    if (-not (Test-HIACommandAvailable -CommandName "git")) {
        Write-Host "FAIL: git command not available" -ForegroundColor Red
        return 1
    }

    Write-Host "Running git status..."

    $gitLines = @()
    $gitExit = 1

    $hasNativePref = Test-Path -LiteralPath "Variable:PSNativeCommandUseErrorActionPreference"
    if ($hasNativePref) {
        $previousNativePref = $PSNativeCommandUseErrorActionPreference
        $PSNativeCommandUseErrorActionPreference = $false
    }

    Push-Location $ProjectRoot
    try {
        try {
            $gitLines = @(git status --short 2>&1)
            $gitExit = $LASTEXITCODE
        }
        catch {
            $gitLines = @($_.Exception.Message)
            $gitExit = 1
        }
    }
    finally {
        Pop-Location
        if ($hasNativePref) {
            $PSNativeCommandUseErrorActionPreference = $previousNativePref
        }
    }

    foreach ($line in $gitLines) {
        if ($null -ne $line) {
            Write-Host ([string]$line)
        }
    }

    if ($gitExit -ne 0) {
        Write-Host ("FAIL: git-status exited with code {0}" -f $gitExit) -ForegroundColor Red
        foreach ($line in $gitLines) {
            $txt = [string]$line
            if ($txt -match 'unable to access ''([^'']+)''') {
                Write-Host ("FAIL DETAIL: git cannot access path -> {0}" -f $Matches[1]) -ForegroundColor Red
                Write-Host "MANUAL FIX: check permissions or adjust global excludesfile. Example:" -ForegroundColor Yellow
                Write-Host "  git config --global --get core.excludesfile" -ForegroundColor Yellow
            }
        }
        return 1
    }

    foreach ($line in $gitLines) {
        $txt = [string]$line
        if ($txt -match '^warning:') {
            Write-Host ("WARNING: {0}" -f $txt) -ForegroundColor Yellow
        }
    }

    Write-Host "OK: git-status completed"
    return 0
}

function Get-HIAStatusSummary {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    Write-Host ("ProjectRoot: {0}" -f $ProjectRoot)
    Write-Host ("CLI:         {0}" -f (Join-Path $ProjectRoot "01_UI\terminal\hia.ps1"))
    Write-Host ("RADAR:       {0}" -f (Join-Path $ProjectRoot "02_TOOLS\RADAR.ps1"))
    Write-Host ("Sync:        {0}" -f (Join-Path $ProjectRoot "02_TOOLS\Invoke-HIASync.ps1"))
    Write-Host ("Validators:  {0}" -f (Join-Path $ProjectRoot "02_TOOLS\Invoke-HIAValidators.ps1"))
    return 0
}

function Invoke-HIARunAll {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    Write-Host "run-all sequence: preflight -> sync-check -> validate -> radar -> git-status"

    $preflightCode = Invoke-HIAPreflight -ProjectRoot $ProjectRoot
    if ($preflightCode -ne 0) {
        Write-Host "FAIL: run-all stopped (preflight hard fail)" -ForegroundColor Red
        return 1
    }

    $steps = @(
        @{ Name = "sync-check"; Invoke = { Invoke-HIASyncCheck -ProjectRoot $ProjectRoot } },
        @{ Name = "validate"; Invoke = { Invoke-HIAValidate -ProjectRoot $ProjectRoot } },
        @{ Name = "radar"; Invoke = { Invoke-HIARadar -ProjectRoot $ProjectRoot } },
        @{ Name = "git-status"; Invoke = { Invoke-HIAGitStatus -ProjectRoot $ProjectRoot } }
    )

    foreach ($step in $steps) {
        $code = & $step.Invoke
        if ($code -ne 0) {
            Write-Host ("FAIL: run-all stopped at {0}" -f $step.Name) -ForegroundColor Red
            return 1
        }
    }

    return 0
}

function Invoke-HIAAction {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ActionName
    )

    $normalized = $ActionName.Trim().ToLowerInvariant()
    switch ($normalized) {
        "status" { return (Get-HIAStatusSummary -ProjectRoot $ProjectRoot) }
        "preflight" { return (Invoke-HIAPreflight -ProjectRoot $ProjectRoot) }
        "radar" { return (Invoke-HIARadar -ProjectRoot $ProjectRoot) }
        "validate" { return (Invoke-HIAValidate -ProjectRoot $ProjectRoot) }
        "sync" { return (Invoke-HIASync -ProjectRoot $ProjectRoot) }
        "git-status" { return (Invoke-HIAGitStatus -ProjectRoot $ProjectRoot) }
        "run-all" { return (Invoke-HIARunAll -ProjectRoot $ProjectRoot) }
        default {
            Write-Host ("FAIL: unknown action '{0}'" -f $ActionName) -ForegroundColor Red
            Write-Host "Allowed actions: status, preflight, radar, validate, sync, git-status, run-all"
            return 2
        }
    }
}

Write-HIABanner

try {
    $root = Get-HIAProjectRoot
    $exitCode = Invoke-HIAAction -ProjectRoot $root -ActionName $Action

    if ($exitCode -eq 0) {
        Write-HIAResult -Result "OK" -ExitCode 0
        exit 0
    }

    if ($exitCode -eq 2) {
        Write-HIAResult -Result "FAIL" -ExitCode 2
        exit 2
    }

    Write-HIAResult -Result "FAIL" -ExitCode 1
    exit 1
}
catch {
    Write-Host ""
    Write-Host "FAIL: internal/unhandled error" -ForegroundColor Red
    Write-Host ("DETAIL: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-HIAResult -Result "FAIL" -ExitCode 4
    exit 4
}






