<#
[HIA_TOL_0008] Invoke-HIAGitCheckpoint.ps1
DATE......: 2026-03-01
TIME......: 18:34
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.3
PURPOSE...:
  Crea un checkpoint auditable antes de refactors:
   - Verifica git
   - Ejecuta RADAR pre (si existe)
   - git add -A
   - git commit con mensaje estándar + evidencia
   - (opcional) crea tag

SAFETY:
  - No usa Validate-*.
  - No reescribe HUMAN: solo commitea lo que ya está modificado.
  - Si no hay cambios, no comitea.

USAGE:
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0008_Invoke-HIAGitCheckpoint.ps1 -ProjectRoot "C:\...\HIA" -Message "CHKPT: pre-office refactor"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0008_Invoke-HIAGitCheckpoint.ps1 -ProjectRoot "..." -Message "..." -Tag "HIA_CHKPT_20260301_1835"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$false)]
  [string]$Message = "",

  [string]$Tag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Message, [ValidateSet("INFO","WARN","ERROR")] [string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Message"
}

# Normalize root defensively
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

# Normalize Message (peatón-proof: evita fallo por string vacío)
$Message = ($Message -as [string])
if ($null -eq $Message) { $Message = "" }
$Message = $Message.Trim()
if ([string]::IsNullOrWhiteSpace($Message)) {
  $Message = "CHKPT: AUTO " + (Get-Date).ToString("yyyyMMdd_HHmmss")
}

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw "Git no encontrado en PATH." }

Push-Location $ProjectRoot
try {
  Write-Log "RUN_START ProjectRoot=$ProjectRoot"

  # Pre-evidence RADAR (si existe)
  $radar = Join-Path $ProjectRoot "02_TOOLS\RADAR.ps1"
  if (Test-Path -LiteralPath $radar) {
    Write-Log "EVIDENCE_PRE: Ejecutando RADAR.ps1"
    try {
      pwsh -NoProfile -File $radar | Out-Null
      Write-Log "EVIDENCE_PRE: RADAR ejecutado OK"
    } catch {
      Write-Log "EVIDENCE_PRE: RADAR falló (continuo igual). $($_.Exception.Message)" "WARN"
    }
  } else {
    Write-Log "EVIDENCE_PRE: RADAR.ps1 no existe (skip)" "WARN"
  }

  $status = git status --porcelain
  if (-not $status) {
    Write-Log "No hay cambios para commitear. RUN_END"
    exit 0
  }

  Write-Log "git add -A"
  git add -A | Out-Null

  $stamp = (Get-Date).ToString("yyyyMMdd_HHmm")
  $finalMsg = "$Message | TS=$stamp | ROOT=$ProjectRoot"
  Write-Log "git commit: $finalMsg"
  git commit -m $finalMsg

  if ($Tag -and $Tag.Trim().Length -gt 0) {
    $t = $Tag.Trim()

    # Si el tag ya existe, no fallar: WARN y continuar.
    $exists = $false
    try {
      git rev-parse -q --verify ("refs/tags/{0}" -f $t) | Out-Null
      if ($LASTEXITCODE -eq 0) { $exists = $true }
    } catch {
      $exists = $false
    }

    if ($exists) {
      Write-Log "git tag: $t (ya existe) -> SKIP" "WARN"
    } else {
      Write-Log "git tag: $t"
      try {
        git tag $t
      } catch {
        Write-Log "git tag falló (continuo igual): $($_.Exception.Message)" "WARN"
      }
    }
  }

  Write-Log "RUN_END OK"
} finally {
  Pop-Location
}