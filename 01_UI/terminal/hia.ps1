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

if (-not $RouterArgs) { $RouterArgs = @() }

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
# LIGHTWEIGHT MENU INPUT (for MB-2.36)
# -----------------------------------------------------------------------------
function Get-HIAMenuQueue {
    $path = $env:HIA_MENU_REPLAY
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $lines = @(Get-Content -LiteralPath $path | ForEach-Object { $_.Trim() }) | Where-Object { $_ -ne "" }
    if ($lines.Count -eq 0) { return $null }
    $q = [System.Collections.Generic.Queue[string]]::new()
    foreach ($l in $lines) { $q.Enqueue($l) }
    return $q
}

function Read-HIAMenuInput {
    param(
        [string]$Prompt,
        [System.Collections.Generic.Queue[string]]$Queue
    )
    if ($Queue -and $Queue.Count -gt 0) {
        $val = $Queue.Dequeue()
        Write-Host ("{0}{1}" -f $Prompt, $val) -ForegroundColor DarkGray
        return $val
    }
    return (Read-Host -Prompt $Prompt)
}

function Invoke-HIAMenuCommand {
    param(
        [string]$Cmd,
        [string[]]$CmdArgs
    )

    $cmdText = ("hia {0} {1}" -f $Cmd, ($CmdArgs -join " ")).Trim()
    Write-Host ("Running: {0}" -f $cmdText) -ForegroundColor DarkGray
    Remove-Variable -Name HIA_EXIT_CODE -Scope Global -ErrorAction SilentlyContinue
    $global:LASTEXITCODE = $null

    try {
        Invoke-HIARouter -Command $Cmd -Args $CmdArgs
    }
    catch {
        $msg = $_.Exception.Message
        $code = 4
        if ($msg -match 'Project not found') { $code = 3 }
        elseif ($msg -match 'Usage:') { $code = 2 }
        elseif ($msg -match 'already exists') { $code = 1 }
        else {
            $hint = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
            if ($null -ne $hint) { $code = [int]$hint }
        }
        Write-Host "COMMAND FAILED (pedestrian-friendly):" -ForegroundColor Red
        Write-Host ("  CMD: {0}" -f $cmdText) -ForegroundColor Red
        Write-Host ("  MESSAGE: {0}" -f $msg) -ForegroundColor Red
        $global:HIA_EXIT_CODE = $code
        $global:LASTEXITCODE = $code
        return $code
    }

    $codeOut = 0
    $hintOut = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $hintOut) { $codeOut = [int]$hintOut }
    elseif ($null -ne $LASTEXITCODE) { $codeOut = [int]$LASTEXITCODE }
    $global:HIA_EXIT_CODE = $codeOut
    $global:LASTEXITCODE = $codeOut
    return $codeOut
}

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
    $portfolioEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_PORTFOLIO_ENGINE.ps1"
    if (-not (Test-Path $portfolioEnginePath)) {
        Write-Host "Portfolio engine not found. Falling back to project shell." -ForegroundColor Yellow
        $interactiveEnginePath = Join-Path $projectRoot "02_TOOLS\HIA_INTERACTIVE_ENGINE.ps1"
        if (-not (Test-Path $interactiveEnginePath)) {
            Write-Host "Interactive engine not found. Falling back to help." -ForegroundColor Yellow
            Show-HIAHelp -ProjectRoot $projectRoot
            exit 0
        }
        . $interactiveEnginePath
        Invoke-HIAInteractiveEntrypoint -ProjectRoot $projectRoot
        exit 0
    }

    . $portfolioEnginePath
    Invoke-HIAPortfolioShell -ProjectRoot $projectRoot
    exit 0

}

if (-not $RouterArgs) {
    $RouterArgs = @()
}

# -----------------------------------------------------------------------------
# MENU (LEGACY/INTERACTIVE SURFACE - bounded; keep logic here, do not expand)
# -----------------------------------------------------------------------------
function Invoke-HIAMenu {
    param([string]$ProjectRoot)

    Write-Host "HIA — Quick Menu" -ForegroundColor Yellow
    Write-Host "1) projects status"
    Write-Host "2) project status <PROJECT_ID>"
    Write-Host "3) project review <PROJECT_ID>"
    Write-Host "4) project continue <PROJECT_ID>"
    Write-Host "5) project session status <PROJECT_ID>"
    Write-Host "6) project new <PROJECT_ID>"
    Write-Host "7) project review -> continue (same <PROJECT_ID>)"
    Write-Host "8) projects pick <INDEX> -> project action"
    Write-Host "9) portfolio assist (show indexed list -> pick -> action)"
    Write-Host "10) project delete (safe confirm)"
    Write-Host "11) ai plan (preset/free-text, optional remember)"
    Write-Host "0) exit" -ForegroundColor DarkGray
    Write-Host ""

    $queue = Get-HIAMenuQueue
    $choice = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_CHOICE)) { $env:HIA_MENU_CHOICE } else { Read-HIAMenuInput -Prompt "Select option: " -Queue $queue }
    if ([string]::IsNullOrWhiteSpace($choice)) { exit 2 }

    switch ($choice.Trim()) {
        "1" {
            $null = Invoke-HIAMenuCommand -Cmd "projects" -CmdArgs @("status")
            return
        }
        "2" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("status", $projId)
            return
        }
        "3" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("review", $projId)
            return
        }
        "4" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("continue", $projId)
            return
        }
        "5" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("session", "status", $projId)
            return
        }
        "6" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID to create: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            Write-Host ("Running: hia project new {0}" -f $projId) -ForegroundColor DarkGray
            $createExit = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("new", $projId)
            if ($createExit -ne 0) { exit $createExit }

            Write-Host ("Next: hia project status {0}" -f $projId) -ForegroundColor DarkGray
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("status", $projId)
            return
        }
        "7" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            Write-Host ("Running: hia project review {0}" -f $projId) -ForegroundColor DarkGray
            Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("review", $projId)
            Write-Host ("Next: hia project continue {0}" -f $projId) -ForegroundColor DarkGray
            Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("continue", $projId)
            return
        }
        "8" {
            $idxInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_INDEX)) { $env:HIA_MENU_INDEX } else { Read-HIAMenuInput -Prompt "Project index: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($idxInput)) { exit 2 }

            $actionInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PICK_ACTION)) { $env:HIA_MENU_PICK_ACTION } else { Read-HIAMenuInput -Prompt "Action (status/review/continue/sessionstatus) [status]: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($actionInput)) { $actionInput = "status" }
            $actionNorm = $actionInput.Trim().ToLowerInvariant()
            $allowed = @("status", "review", "continue", "sessionstatus")
            if ($allowed -notcontains $actionNorm) { exit 2 }

            $null = Invoke-HIAMenuCommand -Cmd "projects" -CmdArgs @("pick", $idxInput.Trim(), $actionNorm)
            return
        }
        "9" {
            Write-Host "Showing portfolio with indexes..." -ForegroundColor DarkGray
            $statusExit = Invoke-HIAMenuCommand -Cmd "projects" -CmdArgs @("status")
            if ($statusExit -ne 0) { exit $statusExit }

            $idxInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_INDEX)) { $env:HIA_MENU_INDEX } else { Read-HIAMenuInput -Prompt "Project index: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($idxInput)) { exit 2 }

            $actionInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PICK_ACTION)) { $env:HIA_MENU_PICK_ACTION } else { Read-HIAMenuInput -Prompt "Action (status/review/continue/sessionstatus) [status]: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($actionInput)) { $actionInput = "status" }
            $actionNorm = $actionInput.Trim().ToLowerInvariant()
            $allowed = @("status", "review", "continue", "sessionstatus")
            if ($allowed -notcontains $actionNorm) { exit 2 }

            Write-Host ("Running: hia projects pick {0} {1}" -f $idxInput.Trim(), $actionNorm) -ForegroundColor DarkGray
            $null = Invoke-HIAMenuCommand -Cmd "projects" -CmdArgs @("pick", $idxInput.Trim(), $actionNorm)
            return
        }
        "10" {
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID to delete: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }
            $expected = "DELETE $projId"
            $token = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_DELETE_CONFIRM)) { $env:HIA_MENU_DELETE_CONFIRM } else { Read-HIAMenuInput -Prompt ("Type '{0}' to confirm (or anything else to cancel): " -f $expected) -Queue $queue }
            if ($token -ne $expected) {
                Write-Host "Delete cancelled (confirmation mismatch)." -ForegroundColor Yellow
                exit 1
            }
            $null = Invoke-HIAMenuCommand -Cmd "project" -CmdArgs @("delete", $projId, "--confirm", $token)
            return
        }
        "11" {
            # AI menu legacy surface (internal/testing aids: HIA_MENU_FOLLOW, __free__ sentinel)
            $projId = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PROJECT)) { $env:HIA_MENU_PROJECT } else { Read-HIAMenuInput -Prompt "Project ID: " -Queue $queue }
            if ([string]::IsNullOrWhiteSpace($projId)) { exit 2 }

            $presetPrompt = "Preset (readiness/next-step/risk-scan) or leave blank for free-text: "
            $presetInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_PRESET)) { $env:HIA_MENU_PRESET } else { Read-HIAMenuInput -Prompt $presetPrompt -Queue $queue }
            if ($null -eq $presetInput) { $presetInput = "" }
            if ($presetInput.Trim().ToLowerInvariant() -eq "__free__") { $presetInput = "" }
            $presetNorm = $presetInput.Trim().ToLowerInvariant()
            $allowedPresets = @("readiness","next-step","risk-scan")

            $request = ""
            $cmdArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($presetNorm)) {
                if ($allowedPresets -notcontains $presetNorm) { exit 2 }
                $cmdArgs = @("plan", $projId, "--preset", $presetNorm)
            }
            else {
                $request = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_REQUEST)) { $env:HIA_MENU_REQUEST } else { Read-HIAMenuInput -Prompt "Free-text request: " -Queue $queue }
                if ([string]::IsNullOrWhiteSpace($request)) { exit 2 }
                $cmdArgs = @("plan", $projId, $request)
            }

            $rememberInput = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_REMEMBER)) { $env:HIA_MENU_REMEMBER } else { Read-HIAMenuInput -Prompt "Remember? (y/N): " -Queue $queue }
            if ($rememberInput.Trim().ToLowerInvariant() -in @("y","yes")) {
                $cmdArgs += "--remember"
            }

            $aiExit = Invoke-HIAMenuCommand -Cmd "ai" -CmdArgs $cmdArgs
            if ($aiExit -is [array]) { $aiExit = $aiExit[-1] }
            if ($null -ne $aiExit) {
                $global:HIA_EXIT_CODE = [int]$aiExit
                $global:LASTEXITCODE = [int]$aiExit
            }
            if ($aiExit -ne 0) { return }

            # Suggested next command (deterministic mapping)
            $suggested = "hia project review {0}" -f $projId
            switch ($presetNorm) {
                "readiness" { $suggested = "hia project review {0}" -f $projId }
                "risk-scan" { $suggested = "hia project review {0}" -f $projId }
                "next-step" { $suggested = "hia project continue {0}" -f $projId }
                default { $suggested = "hia project review {0}" -f $projId }
            }

            Write-Host ("Suggested next: {0}" -f $suggested) -ForegroundColor DarkGray
            $follow = if (-not [string]::IsNullOrWhiteSpace($env:HIA_MENU_FOLLOW)) { $env:HIA_MENU_FOLLOW } else { Read-HIAMenuInput -Prompt "Run suggested command now? (y/N): " -Queue $queue }
            if ($follow.Trim().ToLowerInvariant() -notin @("y","yes")) { return }

            $tokens = $suggested.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($tokens.Count -lt 2) { return }
            $runCmd = $tokens[1]
            $runArgs = $tokens[2..($tokens.Count-1)]
            Write-Host ("Running: {0}" -f $suggested) -ForegroundColor DarkGray
            $followExit = Invoke-HIAMenuCommand -Cmd $runCmd -CmdArgs $runArgs
            if ($followExit -is [array]) { $followExit = $followExit[-1] }
            if ($null -ne $followExit) {
                $global:HIA_EXIT_CODE = [int]$followExit
                $global:LASTEXITCODE = [int]$followExit
            }
            return
        }
        "0" { exit 0 }
        default { exit 2 }
    }
}

# -----------------------------------------------------------------------------
# DIRECT HOOKS
# -----------------------------------------------------------------------------

if ($Command.ToLowerInvariant() -in @("help", "-h", "--help", "/?")) {
    Show-HIAHelp -ProjectRoot $projectRoot
    exit 0
}

if ($Command.ToLowerInvariant() -eq "menu") {
    Invoke-HIAMenu -ProjectRoot $projectRoot
    $routerExitCode = 0
    $lastExit = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $lastExit) { $routerExitCode = [int]$lastExit }
    $hintExit = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $hintExit) { $routerExitCode = [int]$hintExit }
    exit $routerExitCode
}

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
    Remove-Variable -Name HIA_EXIT_CODE -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    Invoke-HIARouter -Command $Command -Args $RouterArgs

    $routerExitCode = 0
    $lastExit = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $lastExit) { $routerExitCode = [int]$lastExit }
    $hintExit = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
    if ($null -ne $hintExit) { $routerExitCode = [int]$hintExit }
    $global:LASTEXITCODE = $routerExitCode
    exit $routerExitCode
}
catch {
    $exitCode = 4
    $msg = $_.Exception.Message
    if ($msg -match 'Project not found') { $exitCode = 3 }
    elseif ($msg -match 'already exists') { $exitCode = 1 }
    elseif ($msg -match 'positional parameter cannot be found') { $exitCode = 2 }
    elseif ($msg -match '^Usage:') { $exitCode = 2 }
    else {
        $hint = Get-Variable -Name HIA_EXIT_CODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        if ($null -ne $hint) { $exitCode = [int]$hint }
    }

    Write-Host ""
    Write-Host "HIA CLI ERROR" -ForegroundColor Red
    Write-Host ("MESSAGE: {0}" -f $msg) -ForegroundColor Red

    if ($_.InvocationInfo) {
        Write-Host ("SCRIPT:  {0}" -f $_.InvocationInfo.ScriptName) -ForegroundColor DarkRed
        Write-Host ("LINE:    {0}" -f $_.InvocationInfo.ScriptLineNumber) -ForegroundColor DarkRed
        Write-Host ("COMMAND: {0}" -f $_.InvocationInfo.Line.Trim()) -ForegroundColor DarkRed
    }

    Write-Host ""
    exit $exitCode
}


