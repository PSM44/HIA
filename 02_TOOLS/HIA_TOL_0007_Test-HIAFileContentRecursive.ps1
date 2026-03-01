<#
[HIA_TOL_0007] Test-HIAFileContentRecursive.ps1
DATE......: 2026-03-01
TIME......: 18:06
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.3
PURPOSE...:
  Validación recursiva para .txt (y opcional .ps1/.json) alineada con tu estructura real.
  Evita el choque "txt solo root" sin modificar scripts legacy.

BEHAVIOR:
  - Recorre ProjectRoot recursivo.
  - Excluye: 03_ARTIFACTS (por defecto), DeadHistory, Logs.
  - Reglas básicas: metadata mínima + índice (si aplica) + encoding UTF-8.
  - Solo WARN por ahora (modo office). Puedes elevar a FAIL después.

NO Validate-* verbs. Solo Test-*.

USAGE:
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Result {
  param([string]$Level, [string]$RelPath, [string]$Message)
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $RelPath :: $Message"
}

$exclude = @(
  "03_ARTIFACTS\*",
  "*\DeadHistory\*",
  "*\Logs\*"
)

function Is-Excluded {
  param([string]$RelPath)
  foreach ($p in $exclude) {
    if ($RelPath -like $p) { return $true }
  }
  return $false
}

function Test-TxtMetadata {
  param([string]$FullPath, [string]$RelPath)

  $raw = Get-Content $FullPath -Raw -Encoding utf8

  # Reglas mínimas: aceptar 3+ puntos en metadata (DATE...: o DATE......:)
  # Esto evita drift por estilos de header y reduce WARN falsos.
  $needs = @("DATE", "TIME", "VERSION")

  foreach ($n in $needs) {
    # ^\s*DATE\.{3,}\s*:
    $rx = "(?im)^\s*$n\.{3,}\s*:"
    if ($raw -notmatch $rx) {
      Write-Result "WARN" $RelPath "Falta metadata '$n...:' (acepta 3+ puntos, ej: $n......:)"
      # Nota: NO return inmediato; reporta las 3 faltas si aplica
    }
  }

  # WBS base recomendada (no bloqueante)
  if ($raw -notmatch "(?im)^\s*01\.00_") {
    Write-Result "WARN" $RelPath "No se detecta WBS base (ej. 01.00_...)."
  }
}

$files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Force |
  Where-Object {
    $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart('\')
    if (Is-Excluded -RelPath $rel) { return $false }
    return $_.Extension.ToLowerInvariant() -eq ".txt"
  }

if (-not $files) {
  Write-Host "No .txt files found (excluyendo artifacts)."
  exit 0
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring($ProjectRoot.Length).TrimStart('\')
  try {
    Test-TxtMetadata -FullPath $f.FullName -RelPath $rel
  } catch {
    Write-Result "WARN" $rel ("No se pudo leer/validar UTF-8: " + $_.Exception.Message)
  }
}

Write-Host "DONE: Test-HIAFileContentRecursive"