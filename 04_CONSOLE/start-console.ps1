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

$py = Get-Command py -ErrorAction SilentlyContinue
if (-not $py) {
    Write-Host "ERROR: py not found" -ForegroundColor Red
    exit 1
}

Write-Host "Checking dependencies..." -ForegroundColor Yellow
Push-Location $backendDir
py -m pip install -q -r requirements.txt
Pop-Location

Write-Host "Starting server on http://localhost:8000  (Ctrl+C to stop)" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

Push-Location $backendDir
py -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
Pop-Location

