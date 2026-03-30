<#
===============================================================================
MODULE: HIA_OLLAMA_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: OLLAMA OPERATIONAL WRAPPER (MB-1.3)
===============================================================================

OBJETIVO
Hacer operativo Ollama como base local dentro de HIA cuando el comando `ollama`
existe y responde.

COMANDOS
- status: valida presencia + version
- models: lista modelos (si existen)
- run: ollama run <model> <prompt> (o passthrough args restantes)

NOTA
No instala modelos. No asume GPU. Reporta realidad.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("status", "models", "run")]
    [string]$Command = "status",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-OllamaCommand {
    return ($null -ne (Get-Command ollama -ErrorAction SilentlyContinue))
}

function Get-OllamaPath {
    $cmd = Get-Command ollama -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return "NONE" }
    return [string]$cmd.Source
}

function Get-OllamaVersion {
    try {
        $out = & ollama --version 2>&1 | Out-String
        $t = $out.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) { return "UNKNOWN" }
        if ($t.Length -gt 200) { return ($t.Substring(0, 200) + "...") }
        return $t
    }
    catch {
        return ("ERROR: {0}" -f $_.Exception.Message)
    }
}

function Get-OllamaModels {
    try {
        $out = & ollama list 2>&1 | Out-String
        return $out.Trim()
    }
    catch {
        return ("ERROR: {0}" -f $_.Exception.Message)
    }
}

switch ($Command) {
    "status" {
        Write-Host ""
        Write-Host "HIA OLLAMA STATUS" -ForegroundColor Cyan
        Write-Host ""

        if (-not (Test-OllamaCommand)) {
            Write-Host "[WARN] Ollama CLI not detected (expected 'ollama' command)." -ForegroundColor Yellow
            Write-Host "Action: Install Ollama and ensure PATH provides 'ollama'." -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }

        Write-Host "[OK] Ollama CLI detected" -ForegroundColor Green
        Write-Host ("PATH:    {0}" -f (Get-OllamaPath))
        Write-Host ("VERSION: {0}" -f (Get-OllamaVersion))
        Write-Host ""
        exit 0
    }
    "models" {
        if (-not (Test-OllamaCommand)) {
            Write-Host ""
            Write-Host "[FAIL] Cannot list models: 'ollama' command not found." -ForegroundColor Red
            Write-Host "Install Ollama and re-run: hia ollama status" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }

        Write-Host ""
        Write-Host "OLLAMA MODELS" -ForegroundColor Cyan
        Write-Host ""
        Write-Host (Get-OllamaModels)
        Write-Host ""
        exit 0
    }
    "run" {
        if (-not (Test-OllamaCommand)) {
            Write-Host ""
            Write-Host "[FAIL] Cannot run Ollama: 'ollama' command not found." -ForegroundColor Red
            Write-Host "Install Ollama and re-run: hia ollama status" -ForegroundColor Yellow
            Write-Host ""
            exit 1
        }

        Write-Host ""
        Write-Host "EXECUTING: ollama $($Args -join ' ')" -ForegroundColor Cyan
        Write-Host ""

        & ollama @Args
        $exitCode = 0
        $lastExit = Get-Variable -Name LASTEXITCODE -ValueOnly -ErrorAction SilentlyContinue
        if ($null -ne $lastExit) { $exitCode = [int]$lastExit }
        exit $exitCode
    }
}

