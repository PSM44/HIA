<#
===============================================================================
FILE: Run-PRJPB-008H.ps1
PROJECT: PRJ_0001_HIA.PRODUCT
TYPE: MINIBATTLE RUNNER / VERSION MARKER
MINIBATTLE: PRJPB_008H
PURPOSE: Crear protocolo de screenshots UX/UI y evidencia visual.
NOTE: La ejecución operativa fue realizada por one-shot bash desde WSL2.
===============================================================================
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "PRJPB_008H — Screenshot UX/UI protocol"
Write-Host "Version marker only. See:"
Write-Host "04_PROJECTS\PRJ_0001_HIA.PRODUCT\UX_EVAL\UX_UI.SCREENSHOT.PROTOCOL.txt"
Write-Host "04_PROJECTS\PRJ_0001_HIA.PRODUCT\UX_EVAL\UX_UI.EVALUATION.LOG.txt"
Write-Host "04_PROJECTS\PRJ_0001_HIA.PRODUCT\UX_EVAL\UX_UI.DECISIONS.LOG.txt"
