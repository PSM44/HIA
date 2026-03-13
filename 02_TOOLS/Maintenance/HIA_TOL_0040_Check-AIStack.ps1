<#
================================================================================
SCRIPT: HIA_TOL_0040_Check-AIStack.ps1
VERSION: v1.0
DATE: 2026-03-12
AUTHOR: HIA

PURPOSE
Detecta:

- hardware
- GPUs
- RAM
- Ollama
- modelos instalados
- Codex Desktop
- Claude Desktop
================================================================================
#>

Write-Host ""
Write-Host "==============================="
Write-Host "HIA AI STACK CHECK"
Write-Host "==============================="
Write-Host ""

# -------------------------------------------------------------------
# CPU
# -------------------------------------------------------------------

Write-Host "CPU:"
Get-CimInstance Win32_Processor | Select Name

# -------------------------------------------------------------------
# RAM
# -------------------------------------------------------------------

Write-Host ""
Write-Host "RAM:"
systeminfo | findstr /C:"Total Physical Memory"

# -------------------------------------------------------------------
# GPU
# -------------------------------------------------------------------

Write-Host ""
Write-Host "GPU:"
Get-CimInstance Win32_VideoController | Select Name

# -------------------------------------------------------------------
# NVIDIA VRAM
# -------------------------------------------------------------------

Write-Host ""
Write-Host "NVIDIA STATUS:"

if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {

    nvidia-smi

} else {

    Write-Host "nvidia-smi not found"

}

# -------------------------------------------------------------------
# OLLAMA
# -------------------------------------------------------------------

Write-Host ""
Write-Host "OLLAMA STATUS:"

if (Get-Command ollama -ErrorAction SilentlyContinue) {

    Write-Host "Ollama installed"

    Write-Host ""
    Write-Host "Installed models:"

    ollama list

} else {

    Write-Host "Ollama not installed"

}

# -------------------------------------------------------------------
# CODEX DESKTOP
# -------------------------------------------------------------------

Write-Host ""
Write-Host "CODEX DESKTOP:"

$codexPath = "C:\Users\$env:USERNAME\AppData\Local\Programs\Codex"

if (Test-Path $codexPath) {

    Write-Host "Codex detected"

} else {

    Write-Host "Codex not detected"

}

# -------------------------------------------------------------------
# CLAUDE DESKTOP
# -------------------------------------------------------------------

Write-Host ""
Write-Host "CLAUDE DESKTOP:"

$claudePath = "C:\Users\$env:USERNAME\AppData\Local\AnthropicClaude"

if (Test-Path $claudePath) {

    Write-Host "Claude Desktop detected"

} else {

    Write-Host "Claude Desktop not detected"

}

Write-Host ""
Write-Host "==============================="
Write-Host "HIA STACK CHECK COMPLETE"
Write-Host "==============================="