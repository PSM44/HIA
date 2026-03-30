<#
===============================================================================
MODULE: HIA_CLAUDE_CODE_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: CLAUDE CODE OPERATIONAL WRAPPER (MB-1.3)
===============================================================================

OBJETIVO
Hacer operativa la herramienta Claude Code en HIA cuando el comando `claude`
existe. Si no existe, reportar claramente sin vender humo.

COMANDOS
- status: valida presencia + version
- run: passthrough a `claude` (args restantes)

NOTA
No implementa routing multiagente. Solo encapsula una tool local.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("status", "run")]
    [string]$Command = "status",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-ClaudeCommand {
    return ($null -ne (Get-Command claude -ErrorAction SilentlyContinue))
}

function Get-ClaudePath {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return "NONE" }
    return [string]$cmd.Source
}

function Get-ClaudeVersion {
    try {
        $out = & claude --version 2>&1 | Out-String
        $t = $out.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) { return "UNKNOWN" }
        if ($t.Length -gt 200) { return ($t.Substring(0, 200) + "...") }
        return $t
    }
    catch {
        return ("ERROR: {0}" -f $_.Exception.Message)
    }
}

switch ($Command) {
    "status" {
        Write-Host ""
        Write-Host "HIA CLAUDE CODE STATUS" -ForegroundColor Cyan
        Write-Host ""

        if (-not (Test-ClaudeCommand)) {
            Write-Host "[WARN] Claude Code CLI not detected (expected 'claude' command)." -ForegroundColor Yellow
            Write-Host "Action: Install Claude Code and ensure PATH provides 'claude'." -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }

        Write-Host "[OK] Claude Code CLI detected" -ForegroundColor Green
        Write-Host ("PATH:    {0}" -f (Get-ClaudePath))
        Write-Host ("VERSION: {0}" -f (Get-ClaudeVersion))
        Write-Host ""
        exit 0
    }
    "run" {
        if (-not (Test-ClaudeCommand)) {
            Write-Host ""
            Write-Host "[FAIL] Cannot run Claude Code: 'claude' command not found." -ForegroundColor Red
            Write-Host "Install Claude Code and re-run: hia claude status" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }

        Write-Host ""
        Write-Host "EXECUTING: claude $($Args -join ' ')" -ForegroundColor Cyan
        Write-Host ""

        & claude @Args
        $exitCode = 0
        $lastExit = Get-Variable -Name LASTEXITCODE -ValueOnly -ErrorAction SilentlyContinue
        if ($null -ne $lastExit) { $exitCode = [int]$lastExit }
        exit $exitCode
    }
}

