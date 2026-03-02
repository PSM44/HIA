<#
[HIA_TOL_0013] Refactor-RADARProfiles.ps1

DATE......: 2026-03-01
TIME......: 19:xx
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.1

PURPOSE.
  Opción B (agresiva): Dejar RADAR en un único comando (RADAR.ps1) y un set único de outputs:
    - HIA_RAD_INDEX.ALL.ACTIVE.txt
    - HIA_RAD_INDEX.REPO.ACTIVE.txt
    - HIA_RAD_0003_CORE.ACTIVE.txt
    - HIA_RAD_0004_FULL.FULL.ACTIVE.txt
    - HIA_RAD_0001_LITE.ACTIVE.txt
  Elimina el perfil muerto:
    - [REMOVED:USE_INDEX.REPO+CORE+FULL.FULL]
  Limpia outputs legacy y actualiza referencias en texto.

SAFETY.
  - No Validate-* verbs.
  - Backup .bak de RADAR.ps1 antes de editar.
  - -WhatIf soportado.

USAGE.
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0013_Refactor-RADARProfiles.ps1 -ProjectRoot "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0013_Refactor-RADARProfiles.ps1 -ProjectRoot "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA" -WhatIf

#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string] $ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log([string]$Msg, [string]$Level="INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Msg"
}

function Backup-File([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
  $bak = "$Path.bak.$stamp"
  Copy-Item -LiteralPath $Path -Destination $bak -Force
  return $bak
}

function Remove-IfExists([string]$Path) {
  if (Test-Path -LiteralPath $Path) {
    if ($PSCmdlet.ShouldProcess($Path, "Remove file")) {
      Remove-Item -LiteralPath $Path -Force
      Write-Log "REMOVED: $Path"
    } else {
      Write-Log "WHATIF_REMOVE: $Path"
    }
  }
}

function Update-TextFilesReferences([string]$Root, [hashtable]$Map) {
  $targets = Get-ChildItem -Path $Root -Recurse -Force -File -ErrorAction Stop |
    Where-Object { $_.Extension -in @(".txt",".ps1",".md") }

  foreach ($f in $targets) {
    $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
    $new = $raw
    foreach ($k in $Map.Keys) {
      $new = $new -replace [regex]::Escape($k), $Map[$k]
    }
    if ($new -ne $raw) {
      if ($PSCmdlet.ShouldProcess($f.FullName, "Replace legacy references")) {
        Backup-File $f.FullName | Out-Null
        Set-Content -LiteralPath $f.FullName -Value $new -NoNewline -Encoding UTF8
        Write-Log "UPDATED_REFS: $($f.FullName)"
      } else {
        Write-Log "WHATIF_UPDATED_REFS: $($f.FullName)"
      }
    }
  }
}

# -------------------- MAIN --------------------
$ProjectRoot = $ProjectRoot.Trim().Trim('"').Trim("'")
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$radarDir = Join-Path $ProjectRoot "03_ARTIFACTS\RADAR"
$radarPs1 = Join-Path $ProjectRoot "02_TOOLS\RADAR.ps1"

Write-Log "RUN_START ProjectRoot=$ProjectRoot"
if (-not (Test-Path -LiteralPath $radarDir)) { Write-Log "RADAR dir no existe aún: $radarDir" "WARN" }

# 1) Remove dead/legacy ACTIVE outputs (solo activos, no old/)
if (Test-Path -LiteralPath $radarDir) {
  Remove-IfExists (Join-Path $radarDir "[REMOVED:USE_INDEX.REPO+CORE+FULL.FULL]")
  Remove-IfExists (Join-Path $radarDir "HIA_RAD_INDEX.REPO.N.CORE.ACTIVE.seg.001.txt") # por si quedó segmentado
  # Si existieron otras variantes previas, bórralas también (mantén lo esencial)
  Remove-IfExists (Join-Path $radarDir "HIA_RAD_INDEX.REPO.ACTIVE.txt") # legacy nombre anterior
  Remove-IfExists (Join-Path $radarDir "HIA_RAD_INDEX.ALL.ACTIVE.txt")  # si tu estándar final cambia, ajusta aquí
  Remove-IfExists (Join-Path $radarDir "HIA_RAD_0004_FULL.FULL.ACTIVE.txt")  # legacy nombre intermedio
}

# 2) Patch RADAR.ps1: forzar nombres y bloquear generación RepoNCore
if (-not (Test-Path -LiteralPath $radarPs1)) { throw "No existe: $radarPs1" }

$bak = Backup-File $radarPs1
Write-Log "BACKUP: $bak"

$src = Get-Content -LiteralPath $radarPs1 -Raw -ErrorAction Stop
$dst = $src

# 2.1 Forzar path names (manteniendo tu set actual observado en outputs FULL.FULL)
# Nota: tu script ya usa estos nombres en una versión (se ve en FULL.FULL). Ajusto con regex conservador.
$dst = $dst -replace '(\$LiteActive\s*=\s*Join-Path\s+\$RadarDir\s+")([^"]+)(")',
                    '$1HIA_RAD_0001_LITE.ACTIVE.txt$3'
$dst = $dst -replace '(\$IndexActive\s*=\s*Join-Path\s+\$RadarDir\s+")([^"]+)(")',
                    '$1HIA_RAD_INDEX.REPO.ACTIVE.txt$3'
$dst = $dst -replace '(\$CoreActive\s*=\s*Join-Path\s+\$RadarDir\s+")([^"]+)(")',
                    '$1HIA_RAD_0003_CORE.ACTIVE.txt$3'
$dst = $dst -replace '(\$FullActive\s*=\s*Join-Path\s+\$RadarDir\s+")([^"]+)(")',
                    '$1HIA_RAD_0004_FULL.FULL.ACTIVE.txt$3'

# 2.2 Eliminar cualquier bloque que genere INDEX.REPO.N.CORE (si existe)
# Heurística: líneas que contengan "INDEX.REPO.N.CORE" o "HIA_RAD_INDEX.REPO.N.CORE"
$dst = ($dst -split "`r?`n") | Where-Object {
  ($_ -notmatch 'INDEX\.REPO\.N\.CORE') -and ($_ -notmatch 'HIA_RAD_INDEX\.REPO\.N\.CORE')
} | ForEach-Object { $_ } | Out-String
$dst = $dst.TrimEnd()

# 2.3 Asegurar que INDEX.ALL exista: si tu RADAR.ps1 no lo genera, esto NO puede inventarse acá sin ver tu implementación.
# Por eso: solo dejamos el contrato y no "alucinamos" lógica nueva.
# Recomendación: si hoy IndexAll lo genera otro script, muévelo dentro de RADAR.ps1 en un refactor posterior controlado.

if ($dst -ne $src) {
  if ($PSCmdlet.ShouldProcess($radarPs1, "Write patched RADAR.ps1")) {
    Set-Content -LiteralPath $radarPs1 -Value $dst -NoNewline -Encoding UTF8
    Write-Log "PATCHED: $radarPs1"
  } else {
    Write-Log "WHATIF_PATCHED: $radarPs1"
  }
} else {
  Write-Log "NOCHANGE: RADAR.ps1 (no se detectaron patrones a cambiar)" "WARN"
}

# 3) Update references in text (si hay docs apuntando a nombres antiguos)
$map = @{
  "[REMOVED:USE_INDEX.REPO+CORE+FULL.FULL]" = "[REMOVED:USE_INDEX.REPO+CORE+FULL.FULL]"
  "HIA_RAD_INDEX.REPO.ACTIVE.txt"        = "HIA_RAD_INDEX.REPO.ACTIVE.txt"
  "HIA_RAD_0004_FULL.FULL.ACTIVE.txt"         = "HIA_RAD_0004_FULL.FULL.ACTIVE.txt"
  "HIA_RAD_0004_FULL.FULL.ACTIVE.txt"         = "HIA_RAD_0004_FULL.FULL.ACTIVE.txt"
}
Update-TextFilesReferences -Root $ProjectRoot -Map $map

Write-Log "RUN_END OK"