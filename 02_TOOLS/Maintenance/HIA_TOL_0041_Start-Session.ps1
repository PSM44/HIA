<#
===============================================================================
SCRIPT: HIA_TOL_0041_Start-Session.ps1
PURPOSE: Inicia sesión de desarrollo HIA
VERSION: v1.0
===============================================================================
#>

param(
[string]$ProjectRoot = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
)

Set-Location $ProjectRoot

# ------------------------------------------------
# Timestamp
# ------------------------------------------------

$now = Get-Date
$sessionId = $now.ToString("yyyyMMdd-HHmm")

$branch = "h1/session-$sessionId"

Write-Host ""
Write-Host "HIA SESSION START"
Write-Host "Session ID:" $sessionId
Write-Host ""

# ------------------------------------------------
# Crear rama
# ------------------------------------------------

git checkout -b $branch

git push --set-upstream origin $branch

# ------------------------------------------------
# Crear log
# ------------------------------------------------

$logDir = "$ProjectRoot\03_ARTIFACTS\LOGS\SESSIONS"

if (!(Test-Path $logDir)) {

New-Item -ItemType Directory -Path $logDir | Out-Null

}

$logFile = "$logDir\SESSION.$sessionId.txt"

$log = @"
SESSION_ID: $sessionId
DATE: $($now.ToString("yyyy-MM-dd"))
TIME: $($now.ToString("HH:mm"))
CITY: Santiago, Chile

BRANCH
$branch

STATUS
SESSION_STARTED
"@

$log | Out-File $logFile -Encoding utf8

# ------------------------------------------------
# Commit inicial
# ------------------------------------------------

git add -A

git commit -m "SESSION $sessionId START"

git push

Write-Host ""
Write-Host "SESSION STARTED"
Write-Host "Branch:" $branch
Write-Host "Log:" $logFile
Write-Host ""