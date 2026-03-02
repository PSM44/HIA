<#
[HIA_TOL_0020] Purge-OneShotsAndDeadTools.ps1

DATE.............: 2026-03-02
TIME.............: 01:50
TZ...............: America/Santiago
CITY.............: Santiago, Chile
VERSION..........: 0.1

PURPOSE.
  Elimina permanentemente (git rm) scripts "one-shot" y herramientas muertas que ya cumplieron,
  sin romper el runner canónico (RADAR / Sync / Validators).

  Nota: "permanente" = removido del working tree y del repo. Igual queda recuperable vía Git history.

SAFETY.
  - Soporta -WhatIf.
  - Bloquea si git status no está limpio, salvo -Force.
  - Nunca toca: RADAR.ps1, Invoke-HIASync.ps1, Invoke-HIAValidators.ps1, HIA_TOL_0008 (checkpoint).

USAGE.
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0020_Purge-OneShotsAndDeadTools.ps1 -ProjectRoot "C:\...\HIA" -WhatIf
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0020_Purge-OneShotsAndDeadTools.ps1 -ProjectRoot "C:\...\HIA" -Force

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string] $ProjectRoot,

  [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$m,[string]$lvl="INFO"){
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$lvl] $m"
}

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: $ProjectRoot" }

Push-Location $ProjectRoot
try {
  # 1) Guard: git limpio
  $porc = git status --porcelain
  if (-not $Force -and $porc) {
    throw "Git status no está limpio. Haz commit/stash o re-ejecuta con -Force.`n$porc"
  }

  $toolsDir = Join-Path $ProjectRoot "02_TOOLS"
  if (-not (Test-Path -LiteralPath $toolsDir)) { throw "No existe 02_TOOLS en: $ProjectRoot" }

  # 2) Lista declarativa de candidatos (AJUSTABLE)
  #    - One-shot fixers ya usados
  #    - Tests sueltos si ya no forman parte del pipeline
  $candidates = @(
    "02_TOOLS\HIA_TOL_0018_Fix-HUMAN_ID_UNICO.ps1",
    "02_TOOLS\HIA_TOL_0019_Normalize-HUMAN_ID_UNICO_Format.ps1",
    "02_TOOLS\Test-HIAIdsAndNames.ps1",
    "02_TOOLS\Test-HIAFileContent.ps1"
  )

  # 3) Allowlist de intocables
  $protected = @(
    "02_TOOLS\RADAR.ps1",
    "02_TOOLS\Invoke-HIASync.ps1",
    "02_TOOLS\Invoke-HIAValidators.ps1",
    "02_TOOLS\HIA_TOL_0008_Invoke-HIAGitCheckpoint.ps1"
  )

  # 4) Filtrar
  $toDelete = @()
  foreach($rel in $candidates){
    $relNorm = $rel -replace '/','\'
    if($protected -contains $relNorm){
      Log "SKIP_PROTECTED: $relNorm" "WARN"
      continue
    }
    $abs = Join-Path $ProjectRoot $relNorm
    if(Test-Path -LiteralPath $abs){
      $toDelete += $relNorm
    } else {
      Log "SKIP_NOT_FOUND: $relNorm" "WARN"
    }
  }

  if($toDelete.Count -eq 0){
    Log "Nada que borrar."
    exit 0
  }

  Log "Candidatos a borrar (git rm): $($toDelete.Count)"
  $toDelete | ForEach-Object { Log "  - $_" }

  # 5) Ejecutar borrado
  foreach($rel in $toDelete){
    if ($PSCmdlet.ShouldProcess($rel, "git rm")) {
      git rm -f -- $rel | Out-Null
      Log "DELETED: $rel"
    } else {
      Log "WHATIF_DELETE: $rel"
    }
  }

  Log "DONE. Recomendado: correr Validators + RADAR y luego commit checkpoint."
}
finally {
  Pop-Location
}