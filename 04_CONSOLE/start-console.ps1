<#
HIA Console Launcher
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $scriptDir "backend"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " HIA Console" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "ERROR: Python not found" -ForegroundColor Red
    exit 1
}

Write-Host "Checking dependencies..." -ForegroundColor Yellow
Push-Location $backendDir
pip install -r requirements.txt -q
Pop-Location

Write-Host "Starting server on http://localhost:8000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

Push-Location $backendDir
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Pop-Location
