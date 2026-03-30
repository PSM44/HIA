<#
================================================================================
SCRIPT: HIA_TOL_0043_Check-AIStack.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: AI STACK CHECK (GOVERNANCE MVP)
VERSION: v1.0
DATE: 2026-03-30

OBJETIVO
Verificar disponibilidad técnica del AI stack con output claro OK/WARN/FAIL:
- Codex (CLI/desktop heurística)
- Claude Code (CLI)
- Ollama (CLI) + modelos (si aplica)
- OpenCode (CLI)
- Env vars mínimas (si existen)
- Archivos canónicos de governance (policy/inventario)

NOTAS
- No instala nada.
- No asume hardware real si no se puede verificar.
- No falla el repo por ausencia de vendors; reporta WARN/FAIL por componente.
================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot,

    [Parameter(Mandatory = $false)]
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    param([string]$CandidateRoot)

    if ($CandidateRoot) {
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
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { throw "PROJECT_ROOT not found." }
        $current = $parent
    }
}

function New-HIAResultRow {
    param(
        [string]$Component,
        [ValidateSet("OK", "WARN", "FAIL")]
        [string]$Status,
        [string]$Message,
        [string]$Evidence = "",
        [hashtable]$States = $null
    )
    return [ordered]@{
        component = $Component
        status = $Status
        message = $Message
        evidence = $Evidence
        states = $States
    }
}

function Write-HIAStatusLine {
    param([hashtable]$Row)
    $color = "Gray"
    if ($Row.status -eq "OK") { $color = "Green" }
    elseif ($Row.status -eq "WARN") { $color = "Yellow" }
    elseif ($Row.status -eq "FAIL") { $color = "Red" }

    $e = ""
    if (-not [string]::IsNullOrWhiteSpace([string]$Row.evidence)) {
        $e = (" :: {0}" -f $Row.evidence)
    }
    Write-Host ("[{0}] {1} — {2}{3}" -f $Row.status, $Row.component, $Row.message, $e) -ForegroundColor $color
    if ($Row.states) {
        $s = $Row.states
        Write-Host ("      installed={0} available={1} authenticated={2} ready={3}" -f $s.installed, $s.available, $s.authenticated, $s.ready) -ForegroundColor DarkGray
    }
}

function Test-HIACommand {
    param([string]$Name)
    return ($null -ne (Get-Command $Name -ErrorAction SilentlyContinue))
}

function Try-TestHIAPath {
    param([string]$Path)
    try { return (Test-Path -LiteralPath $Path) } catch { return $false }
}

function Resolve-HIAExecutable {
    param(
        [string]$Name,
        [string[]]$CandidatePaths
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -ne $cmd -and -not [string]::IsNullOrWhiteSpace([string]$cmd.Source)) {
        return [ordered]@{
            found = $true
            via = "path"
            path = [string]$cmd.Source
        }
    }

    foreach ($p in @($CandidatePaths)) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        if (Try-TestHIAPath -Path $p) {
            return [ordered]@{
                found = $true
                via = "probe"
                path = $p
            }
        }
    }

    return [ordered]@{
        found = $false
        via = "none"
        path = "NONE"
    }
}

function Remove-HIAAnsi {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    # ANSI escape sequences
    $clean = [regex]::Replace($Text, "\x1b\[[0-?]*[ -/]*[@-~]", "")
    # Also remove remaining ESC chars if any
    $clean = $clean -replace "\x1b", ""
    return $clean
}

function Invoke-HIACommandVersion {
    param(
        [string]$Name,
        [string[]]$Args
    )

    try {
        $out = & $Name @Args 2>&1 | Out-String
        $text = (Remove-HIAAnsi -Text $out).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { return "UNKNOWN" }
        if ($text.Length -gt 180) { return ($text.Substring(0, 180) + "...") }
        return $text
    }
    catch {
        $msg = [string]$_.Exception.Message
        $short = ($msg -split "At\s+line:", 2)[0].Trim()
        if ($short.Length -gt 180) { $short = ($short.Substring(0, 180) + "...") }
        return ("ERROR: {0}" -f $short)
    }
}

function Invoke-HIAExeVersion {
    param(
        [string]$ExePath,
        [string[]]$Args
    )
    try {
        $out = & $ExePath @Args 2>&1 | Out-String
        $text = (Remove-HIAAnsi -Text $out).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { return "UNKNOWN" }
        if ($text.Length -gt 180) { return ($text.Substring(0, 180) + "...") }
        return $text
    }
    catch {
        $msg = [string]$_.Exception.Message
        $short = ($msg -split "At\s+line:", 2)[0].Trim()
        if ($short.Length -gt 180) { $short = ($short.Substring(0, 180) + "...") }
        return ("ERROR: {0}" -f $short)
    }
}

function Get-HIACommandPath {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return "NONE" }
    return [string]$cmd.Source
}

function Get-HIAOllamaModels {
    param([switch]$Skip)
    if ($Skip) { return @() }
    if (-not (Test-HIACommand -Name "ollama")) { return @() }
    try {
        $out = & ollama list 2>$null | Out-String
        $out = Remove-HIAAnsi -Text $out
        $lines = @($out -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        if ($lines.Count -le 1) { return @() }

        $models = New-Object System.Collections.Generic.List[string]
        for ($i = 1; $i -lt $lines.Count; $i++) {
            $cols = $lines[$i] -split "\s+"
            if ($cols.Count -gt 0 -and $cols[0] -ne "NAME") { $models.Add($cols[0]) }
        }
        return @($models)
    }
    catch {
        return @()
    }
}

function Get-HIAEnvStatus {
    param([string]$VarName)
    $v = [Environment]::GetEnvironmentVariable($VarName)
    if ([string]::IsNullOrWhiteSpace($v)) { return $false }
    return $true
}

$root = Get-HIAProjectRoot -CandidateRoot $ProjectRoot
$rows = New-Object System.Collections.Generic.List[object]

function New-HIAStates {
    param(
        [bool]$Installed,
        [bool]$Available,
        [string]$Authenticated,
        [bool]$Ready
    )
    return [ordered]@{
        installed = $Installed
        available = $Available
        authenticated = $Authenticated
        ready = $Ready
    }
}

$authOpenAI = if (Get-HIAEnvStatus -VarName "OPENAI_API_KEY") { "yes" } else { "no" }
$authAnthropic = if (Get-HIAEnvStatus -VarName "ANTHROPIC_API_KEY") { "yes" } else { "no" }

$policyPath = Join-Path $root "02_TOOLS\\MODEL.ROUTING.REGISTRY.json"
$inventoryPath = Join-Path $root "02_TOOLS\\AI.STACK.INVENTORY.json"
$govDocPath = Join-Path $root "00_FRAMEWORK\\HIA_RTG_0003_AI.STACK.GOVERNANCE.txt"

if (Test-Path -LiteralPath $govDocPath) {
    $rows.Add((New-HIAResultRow -Component "Governance doc" -Status "OK" -Message "Canonical governance doc present" -Evidence $govDocPath -States (New-HIAStates -Installed $true -Available $true -Authenticated "n/a" -Ready $true)))
} else {
    $rows.Add((New-HIAResultRow -Component "Governance doc" -Status "FAIL" -Message "Missing canonical governance doc" -Evidence $govDocPath -States (New-HIAStates -Installed $false -Available $false -Authenticated "n/a" -Ready $false)))
}

if (Test-Path -LiteralPath $inventoryPath) {
    $rows.Add((New-HIAResultRow -Component "Stack inventory" -Status "OK" -Message "AI.STACK.INVENTORY.json present" -Evidence $inventoryPath -States (New-HIAStates -Installed $true -Available $true -Authenticated "n/a" -Ready $true)))
} else {
    $rows.Add((New-HIAResultRow -Component "Stack inventory" -Status "FAIL" -Message "Missing AI.STACK.INVENTORY.json" -Evidence $inventoryPath -States (New-HIAStates -Installed $false -Available $false -Authenticated "n/a" -Ready $false)))
}

if (Test-Path -LiteralPath $policyPath) {
    try {
        $null = (Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json)
        $rows.Add((New-HIAResultRow -Component "Routing registry" -Status "OK" -Message "MODEL.ROUTING.REGISTRY.json valid JSON" -Evidence $policyPath -States (New-HIAStates -Installed $true -Available $true -Authenticated "n/a" -Ready $true)))
    }
    catch {
        $rows.Add((New-HIAResultRow -Component "Routing registry" -Status "FAIL" -Message ("MODEL.ROUTING.REGISTRY.json invalid JSON: {0}" -f $_.Exception.Message) -Evidence $policyPath -States (New-HIAStates -Installed $true -Available $false -Authenticated "n/a" -Ready $false)))
    }
} else {
    $rows.Add((New-HIAResultRow -Component "Routing registry" -Status "FAIL" -Message "Missing MODEL.ROUTING.REGISTRY.json" -Evidence $policyPath -States (New-HIAStates -Installed $false -Available $false -Authenticated "n/a" -Ready $false)))
}

# Codex (distinguish CLI vs Desktop)
$codexDesktopPath = ("C:\\Users\\{0}\\AppData\\Local\\Programs\\Codex" -f $env:USERNAME)
$codexDesktopInstalled = Try-TestHIAPath -Path $codexDesktopPath
$rows.Add((New-HIAResultRow -Component "Codex Desktop" -Status ($(if ($codexDesktopInstalled) { "OK" } else { "WARN" })) -Message ($(if ($codexDesktopInstalled) { "Codex desktop detected (heuristic path)" } else { "Codex desktop not detected (heuristic path)" })) -Evidence ("desktop_path={0}" -f $codexDesktopPath) -States (New-HIAStates -Installed $codexDesktopInstalled -Available $codexDesktopInstalled -Authenticated "n/a" -Ready $codexDesktopInstalled)))

$codexExe = Resolve-HIAExecutable -Name "codex" -CandidatePaths @()
$codexInstalled = [bool]$codexExe.found
$codexVer = if ($codexInstalled) { Invoke-HIAExeVersion -ExePath $codexExe.path -Args @("--version") } else { "NONE" }
$codexAvailable = $codexInstalled -and (-not $codexVer.StartsWith("ERROR:"))
$codexReady = $codexAvailable
$codexMsg = if ($codexReady) { "Codex CLI available" } elseif ($codexInstalled) { "Codex CLI detected but not runnable in this shell" } else { "Codex CLI not detected" }
$codexEvidence = if ($codexInstalled) { ("via={0}; path={1}; version={2}" -f $codexExe.via, $codexExe.path, $codexVer) } else { "cmd=codex" }
$rows.Add((New-HIAResultRow -Component "Codex CLI" -Status ($(if ($codexReady) { "OK" } else { "WARN" })) -Message $codexMsg -Evidence $codexEvidence -States (New-HIAStates -Installed $codexInstalled -Available $codexAvailable -Authenticated $authOpenAI -Ready $codexReady)))

# Claude Code
$claudeCandidates = @(
    (Join-Path $env:LOCALAPPDATA "claude-cli-nodejs\\claude.cmd"),
    (Join-Path $env:LOCALAPPDATA "claude-cli-nodejs\\bin\\claude.cmd"),
    (Join-Path $env:LOCALAPPDATA "Programs\\claude-cli-nodejs\\claude.cmd"),
    (Join-Path $env:LOCALAPPDATA "Programs\\claude-cli-nodejs\\bin\\claude.cmd")
)
$claudeExe = Resolve-HIAExecutable -Name "claude" -CandidatePaths $claudeCandidates
$claudeInstalled = [bool]$claudeExe.found
$claudeVer = if ($claudeInstalled) { Invoke-HIAExeVersion -ExePath $claudeExe.path -Args @("--version") } else { "NONE" }
$claudeAvailable = $claudeInstalled -and (-not $claudeVer.StartsWith("ERROR:"))
$claudeReady = $claudeAvailable
$claudeMsg = if ($claudeReady) { "Claude Code available" } elseif ($claudeInstalled) { "Claude Code detected but not runnable" } else { "Claude Code not detected" }
$claudeEvidence = if ($claudeInstalled) { ("via={0}; path={1}; version={2}" -f $claudeExe.via, $claudeExe.path, $claudeVer) } else { "cmd=claude" }
$rows.Add((New-HIAResultRow -Component "Claude Code" -Status ($(if ($claudeReady) { "OK" } else { "WARN" })) -Message $claudeMsg -Evidence $claudeEvidence -States (New-HIAStates -Installed $claudeInstalled -Available $claudeAvailable -Authenticated $authAnthropic -Ready $claudeReady)))

# Cloud auth signals (do not claim verified login)
$rows.Add((New-HIAResultRow -Component "OpenAI auth" -Status ($(if ($authOpenAI -eq "yes") { "OK" } else { "WARN" })) -Message ($(if ($authOpenAI -eq "yes") { "OPENAI_API_KEY set" } else { "OPENAI_API_KEY not set" })) -Evidence "env:OPENAI_API_KEY" -States (New-HIAStates -Installed $true -Available $true -Authenticated $authOpenAI -Ready ($authOpenAI -eq "yes"))))
$rows.Add((New-HIAResultRow -Component "Anthropic auth" -Status ($(if ($authAnthropic -eq "yes") { "OK" } else { "WARN" })) -Message ($(if ($authAnthropic -eq "yes") { "ANTHROPIC_API_KEY set" } else { "ANTHROPIC_API_KEY not set" })) -Evidence "env:ANTHROPIC_API_KEY" -States (New-HIAStates -Installed $true -Available $true -Authenticated $authAnthropic -Ready ($authAnthropic -eq "yes"))))

# Ollama
$ollamaCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"),
    (Join-Path $env:ProgramFiles "Ollama\ollama.exe")
)
$ollamaExe = Resolve-HIAExecutable -Name "ollama" -CandidatePaths $ollamaCandidates
$ollamaInstalled = [bool]$ollamaExe.found
$ollamaVer = if ($ollamaInstalled) { Invoke-HIAExeVersion -ExePath $ollamaExe.path -Args @("--version") } else { "NONE" }
$ollamaAvailable = $ollamaInstalled -and (-not $ollamaVer.StartsWith("ERROR:"))
$models = if ($ollamaAvailable) { Get-HIAOllamaModels } else { @() }
$ollamaReady = $ollamaAvailable -and ($models.Count -gt 0)
$ollamaMsg = if ($ollamaReady) { ("Ollama available; models={0}" -f $models.Count) } elseif ($ollamaAvailable) { "Ollama available; models=0" } elseif ($ollamaInstalled) { "Ollama detected but not runnable" } else { "Ollama not detected" }
$ollamaEvidence = if ($ollamaInstalled) { ("via={0}; path={1}; version={2}" -f $ollamaExe.via, $ollamaExe.path, $ollamaVer) } else { "cmd=ollama" }
$rows.Add((New-HIAResultRow -Component "Ollama" -Status ($(if ($ollamaReady) { "OK" } else { "WARN" })) -Message $ollamaMsg -Evidence $ollamaEvidence -States (New-HIAStates -Installed $ollamaInstalled -Available $ollamaAvailable -Authenticated "n/a" -Ready $ollamaReady)))
if ($ollamaAvailable) {
    if ($models.Count -gt 0) {
        $rows.Add((New-HIAResultRow -Component "Ollama models" -Status "OK" -Message "Model list captured" -Evidence (($models | Select-Object -First 12) -join ", ") -States (New-HIAStates -Installed $true -Available $true -Authenticated "n/a" -Ready $true)))
    }
    else {
        $rows.Add((New-HIAResultRow -Component "Ollama models" -Status "WARN" -Message "No models detected" -Evidence "ollama list" -States (New-HIAStates -Installed $true -Available $true -Authenticated "n/a" -Ready $false)))
    }
}

# OpenCode
$opencodeCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\OpenCode\opencode.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\opencode\opencode.exe"),
    (Join-Path $env:ProgramFiles "OpenCode\opencode.exe")
)
$opencodeExe = Resolve-HIAExecutable -Name "opencode" -CandidatePaths $opencodeCandidates
$opencodeInstalled = [bool]$opencodeExe.found
$opencodeVer = if ($opencodeInstalled) { Invoke-HIAExeVersion -ExePath $opencodeExe.path -Args @("--version") } else { "NONE" }
$opencodeAvailable = $opencodeInstalled -and (-not $opencodeVer.StartsWith("ERROR:"))
$opencodeReady = $opencodeAvailable
$opencodeMsg = if ($opencodeReady) { "OpenCode available" } elseif ($opencodeInstalled) { "OpenCode detected but not runnable" } else { "OpenCode not detected" }
$opencodeEvidence = if ($opencodeInstalled) { ("via={0}; path={1}; version={2}" -f $opencodeExe.via, $opencodeExe.path, $opencodeVer) } else { "cmd=opencode" }
$rows.Add((New-HIAResultRow -Component "OpenCode" -Status ($(if ($opencodeReady) { "OK" } else { "WARN" })) -Message $opencodeMsg -Evidence $opencodeEvidence -States (New-HIAStates -Installed $opencodeInstalled -Available $opencodeAvailable -Authenticated "n/a" -Ready $opencodeReady)))

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$summary = [ordered]@{
    generated_utc = $nowUtc
    project_root = $root
    ok = @($rows | Where-Object { $_.status -eq "OK" }).Count
    warn = @($rows | Where-Object { $_.status -eq "WARN" }).Count
    fail = @($rows | Where-Object { $_.status -eq "FAIL" }).Count
    rows = $rows
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 10
    exit 0
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HIA AI STACK CHECK (MB-1.2)" -ForegroundColor Cyan
Write-Host (" {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("PROJECT_ROOT: {0}" -f $root)
Write-Host ""

foreach ($r in $rows) { Write-HIAStatusLine -Row $r }

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host ("OK:   {0}" -f $summary.ok)
Write-Host ("WARN: {0}" -f $summary.warn)
Write-Host ("FAIL: {0}" -f $summary.fail)
Write-Host ""

if ($summary.fail -gt 0) { exit 1 }
exit 0
