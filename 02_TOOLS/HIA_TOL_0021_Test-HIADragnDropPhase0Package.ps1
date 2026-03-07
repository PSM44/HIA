<#
ID_UNICO..........: HIA.TOL.0021
NOMBRE_SUGERIDO...: HIA_TOL_0021_Test-HIADragnDropPhase0Package.ps1
VERSION...........: v0.1-DRAFT
FECHA.............: 2026-03-03
TZ.................: America/Santiago
OBJETIVO...........: Smoke test del paquete <PROJECT_ROOT>\DragnDrop\Phase0\
EJECUCION..........:
pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0021_Test-HIADragnDropPhase0Package.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Level,[string]$Msg)
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[HIA_TOL_0021][$ts][$Level] $Msg"
}

# Normalización defensiva de ProjectRoot (evita fallos por comillas, CR/LF o espacios)
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""

try {
  if (Test-Path -LiteralPath $ProjectRoot) {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
  }
} catch { }

Write-Log "INFO" "RUN_START ProjectRoot=$ProjectRoot"

$ddRoot = Join-Path $ProjectRoot "DragnDrop\Phase0"
if (-not (Test-Path -LiteralPath $ddRoot)) {
  throw "FAIL: No existe carpeta Phase0: $ddRoot"
}

$must = @(
  "00.0_HUMAN.GENERAL.txt",
  "01.0_HUMAN.USER.txt",
  "04.0_HUMAN.BATON.txt",
  "07.0_HUMAN.MASTER.txt",
  "08.0_HUMAN.SYNC.MANIFEST.txt",
  "09.0_HUMAN.START.RITUAL.txt",
  "README.txt"
)

# BATON opcional para Phase0
$batonPath = Join-Path $ddRoot "04.0_HUMAN.BATON.txt"
if (Test-Path -LiteralPath $batonPath) {
  $batonLen = (Get-Item -LiteralPath $batonPath).Length
  if ($batonLen -le 0) {
    throw "FAIL: BATON opcional presente pero vacío: $batonPath"
  }
  Write-Log "INFO" "OK optional BATON: 04.0_HUMAN.BATON.txt ($batonLen bytes)"
} else {
  Write-Log "WARN" "Phase0 sin BATON (aceptable si no existe continuidad)"
}

# README coherence check (estricto, excluye README.txt)
$readmePath = Join-Path $ddRoot "README.txt"
$readme = Get-Content -LiteralPath $readmePath -Raw

# README no debe listarse a sí mismo
$mustInReadme = $must | Where-Object { $_ -ne "README.txt" }

foreach ($requiredName in $mustInReadme) {
  if ($readme -notmatch [regex]::Escape($requiredName)) {
    throw "FAIL: README no menciona archivo requerido '$requiredName'"
  }
}

Write-Log "INFO" "OK README coherence: all required HUMAN files listed"

Write-Log "INFO" "PASS: Phase0 smoke test OK"