<#
ID_UNICO..........: HIA.TOL.0022
NOMBRE_SUGERIDO...: HIA_TOL_0022_Test-HIADragnDropPackage.ps1
VERSION...........: v1.1-DRAFT
FECHA.............: 2026-03-04
TZ................: America/Santiago
CIUDAD............: Santiago, Chile

OBJETIVO...........:
  Validar DragnDrop\PhaseX\ de forma determinista:
  - existencia de carpeta
  - required files existen + tamaño > 0
  - README.txt existe + contiene strings literales base
  - radar toggle coherente con IncludeRadar

USO................:
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0022_Test-HIADragnDropPackage.ps1 -ProjectRoot "." -Phase "Phase1"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0022_Test-HIADragnDropPackage.ps1 -ProjectRoot "." -Phase "Phase1" -IncludeRadar "Index"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [Parameter(Mandatory=$true)]
  [ValidateSet("Phase0","Phase1","Phase2","Phase3.1","Phase3.2")]
  [string]$Phase,

  [Parameter(Mandatory=$false)]
  [ValidateSet("None","Index","IndexLite")]
  [string]$IncludeRadar = "None"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log {
  param([string]$Message,[ValidateSet("INFO","WARN","ERROR")] [string]$Level="INFO")
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[HIA_TOL_0022][$ts][$Level] $Message"
}

function Resolve-Root {
  param([string]$Root)
  $r = ($Root -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]", ""
  if (-not (Test-Path -LiteralPath $r)) { throw "ProjectRoot no existe: [$r]" }
  try { $r = (Resolve-Path -LiteralPath $r).Path } catch {}
  return $r
}

function Get-RequiredLeaf {
  param([string]$Phase)
  switch ($Phase) {
    "Phase0" { return @("00.0_HUMAN.GENERAL.txt","01.0_HUMAN.USER.txt","04.0_HUMAN.BATON.txt","07.0_HUMAN.MASTER.txt","08.0_HUMAN.SYNC.MANIFEST.txt","09.0_HUMAN.START.RITUAL.txt","README.txt") }
    "Phase1" { return @("04.0_HUMAN.BATON.txt","05.0_HUMAN.CIS.txt","06.0_HUMAN.PF0.txt","08.0_HUMAN.SYNC.MANIFEST.txt","README.txt") }
    "Phase2" { return @("04.0_HUMAN.BATON.txt","05.0_HUMAN.CIS.txt","06.0_HUMAN.PF0.txt","HIA_COR_0001_HIA.CORE.txt","HIA_RTG_0001_ROUTING_POLICY.txt","README.txt") }
    "Phase3.1" { return @("04.0_HUMAN.BATON.txt","06.0_HUMAN.PF0.txt","HIA_MTH_0001_WORKFLOW.txt","README.txt") }
    "Phase3.2" { return @("04.0_HUMAN.BATON.txt","05.0_HUMAN.CIS.txt","06.0_HUMAN.PF0.txt","HIA_POL_0001_AI_EXECUTION.txt","README.txt") }
    default { throw "Phase no soportada: $Phase" }
  }
}

$ProjectRoot = Resolve-Root $ProjectRoot
Write-Log "RUN_START ProjectRoot=$ProjectRoot Phase=$Phase IncludeRadar=$IncludeRadar"

$dir = Join-Path $ProjectRoot ("DragnDrop\" + $Phase)
if (-not (Test-Path -LiteralPath $dir)) { throw "FAIL: No existe carpeta: $dir" }

$must = Get-RequiredLeaf -Phase $Phase
# Phase0 mantiene BATON como requerido (se valida en foreach($f in $must)).
if ($Phase -eq "Phase0") {
  Write-Log "INFO: Phase0 exige 04.0_HUMAN.BATON.txt (no opcional)."
}

foreach($f in $must){
  $p = Join-Path $dir $f
  if (-not (Test-Path -LiteralPath $p)) {
    throw "FAIL: falta requerido: $f"
  }
  $len = (Get-Item -LiteralPath $p).Length
  if ($len -le 0) {
    throw "FAIL: requerido vacío: $f"
  }
  Write-Log "OK_REQUIRED: $f ($len bytes)"
}

# README checks
$readmePath = Join-Path $dir "README.txt"
$readme = Get-Content -LiteralPath $readmePath -Raw -Encoding utf8

$mustInReadme = $must | Where-Object { $_ -ne "README.txt" }
foreach($requiredName in $mustInReadme){
  if ($readme -notmatch [regex]::Escape($requiredName)) {
    throw "FAIL: README no menciona archivo requerido: $requiredName"
  }
}

# README literal checks (mínimos, deterministas)
foreach($needle in @("GENERATED-ONLY","PROHIBIDO EDITAR A MANO","PHASE: $Phase","INCLUDE_RADAR: $IncludeRadar","CLOUD_CONTRACT:")){
  if ($readme -notmatch [regex]::Escape($needle)) {
    throw "FAIL: README no contiene string literal requerido: [$needle]"
  }
}

# Radar toggle checks
$idx = Join-Path $dir "Radar.Index.ACTIVE.txt"
$lite = Join-Path $dir "Radar.Lite.ACTIVE.txt"

if ($IncludeRadar -eq "None") {
  if (Test-Path -LiteralPath $idx) { throw "FAIL: IncludeRadar=None pero existe Index en paquete" }
  if (Test-Path -LiteralPath $lite) { throw "FAIL: IncludeRadar=None pero existe Lite en paquete" }
} elseif ($IncludeRadar -eq "Index") {
  if (-not (Test-Path -LiteralPath $idx)) { throw "FAIL: IncludeRadar=Index pero falta Index" }
  if (Test-Path -LiteralPath $lite) { throw "FAIL: IncludeRadar=Index pero existe Lite (debe ser IndexLite)" }
} elseif ($IncludeRadar -eq "IndexLite") {
  if (-not (Test-Path -LiteralPath $idx)) { throw "FAIL: IncludeRadar=IndexLite pero falta Index" }
  if (-not (Test-Path -LiteralPath $lite)) { throw "FAIL: IncludeRadar=IndexLite pero falta Lite" }
}

Write-Log "PASS: $Phase package OK"
