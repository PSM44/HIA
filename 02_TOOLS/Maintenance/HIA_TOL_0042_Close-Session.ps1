<#
===============================================================================
SCRIPT: HIA_TOL_0042_Close-Session.ps1
PURPOSE: Cierre automático de sesión HIA
VERSION: v1.0
===============================================================================
#>

param(
[string]$ProjectRoot = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
)

Set-Location $ProjectRoot

$now = Get-Date
$sessionId = $now.ToString("yyyyMMdd-HHmm")

Write-Host ""
Write-Host "HIA SESSION CLOSE"
Write-Host ""

# ------------------------------------------------
# Ejecutar RADAR
# ------------------------------------------------

if (Test-Path ".\02_TOOLS\RADAR.ps1") {

pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1 -ProjectRoot $ProjectRoot

}

# ------------------------------------------------
# Actualizar BATON
# ------------------------------------------------

$baton = "$ProjectRoot\HUMAN.README\04.0_HUMAN.BATON.txt"

if (Test-Path $baton) {

Add-Content $baton "`nSESSION CLOSED $($now.ToString("yyyy-MM-dd HH:mm"))"

}

# ------------------------------------------------
# Commit final
# ------------------------------------------------

git add -A

git commit -m "SESSION CLOSE $sessionId"

git push

Write-Host ""
Write-Host "SESSION CLOSED"
Write-Host ""