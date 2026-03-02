<#
[HIA_TOL_0017] Invoke-HumanReadmeRename.ps1
DATE......: 2026-03-02
TIME......: 01:30
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

PURPOSE...
  Normaliza HUMAN.README según correlativo canónico:
    00.0 General
    01.0 User
    02.0 Use.Case (canónico)
    03.0 Radar
    04.0 BATON
    05.0 CIS
    06.0 PF0
    07.0 MASTER
    08.0 Sync Manifest

  - Canon: renombra/mueve dentro de HUMAN.README\
  - Casebook: mueve HIA_HUM_* a HUMAN.README\CASEBOOK\
  - Legacy: mueve HumanR*.txt y otros legacy a 03_ARTIFACTS\DeadHistory\HUMAN.README\LEGACY\
  - Actualiza referencias en .ps1 y .txt (excluye .git, 03_ARTIFACTS, Raw)
  - Backups (snapshots) de archivos críticos antes de modificar

SAFETY...
  - No Validate-*.
  - Git gate: aborta si working tree no está limpio salvo -Force.
  - Dry-run por defecto: -Apply para ejecutar.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0017_Invoke-HumanReadmeRename.ps1 -ProjectRoot "C:\...\HIA"
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0017_Invoke-HumanReadmeRename.ps1 -ProjectRoot "C:\...\HIA" -Apply
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0017_Invoke-HumanReadmeRename.ps1 -ProjectRoot "C:\...\HIA" -Apply -Force

#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot,

  [switch]$Apply,
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$Msg, [ValidateSet("INFO","WARN","ERROR")] [string]$Level="INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Msg"
}

function Norm([string]$p) {
  return (($p -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]","")
}

function EnsureDir([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) {
    if ($Apply) { New-Item -ItemType Directory -Path $p | Out-Null }
    Log "CREATE_DIR: $p"
  }
}

function TestGitClean([string]$root, [switch]$forceLocal) {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) { Log "Git no encontrado. Continuo sin gate." "WARN"; return $true }

  Push-Location $root
  try {
    $s = git status --porcelain
    if ($s -and -not $forceLocal) {
      Log "Git status no está limpio. Haz commit/stash o re-ejecuta con -Force." "ERROR"
      Write-Host $s
      return $false
    }
    if ($s -and $forceLocal) { Log "Git no está limpio, pero -Force activo." "WARN" }
    return $true
  } finally { Pop-Location }
}

function BackupFile([string]$path, [string]$snapDir) {
  if (-not (Test-Path -LiteralPath $path)) { return }
  EnsureDir $snapDir
  $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
  $name = Split-Path $path -Leaf
  $dst = Join-Path $snapDir ($name + ".SNAP." + $stamp)
  if ($Apply) { Copy-Item -LiteralPath $path -Destination $dst -Force }
  Log "SNAPSHOT: $path -> $dst"
}

function MoveItem([string]$src, [string]$dst) {
  if (-not (Test-Path -LiteralPath $src)) { return }
  $dstDir = Split-Path $dst -Parent
  EnsureDir $dstDir

  if ((Test-Path -LiteralPath $dst)) {
    Log "COLLISION: destino existe, no sobreescribo -> $dst" "ERROR"
    throw "Collision: $dst"
  }

  if ($Apply) { Move-Item -LiteralPath $src -Destination $dst }
  Log "MOVE: $src -> $dst"
}


function ReplaceRefs([string]$root, [hashtable]$map) {
  $files = Get-ChildItem -Path $root -Recurse -Force -File |
    Where-Object {
      ($_.FullName -notmatch "\\\.git\\") -and
      ($_.FullName -notmatch "\\03_ARTIFACTS\\") -and
      ($_.FullName -notmatch "\\Raw\\") -and
      ($_.Extension -in @(".ps1",".txt"))
    }

  foreach ($f in $files) {
    $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    $new = $raw
    foreach ($k in $map.Keys) { $new = $new -replace [regex]::Escape($k), $map[$k] }
    if ($new -ne $raw) {
      if ($Apply) {
        $new | Out-File -FilePath $f.FullName -Encoding utf8
      }
      Log "UPDATED_REFS: $($f.FullName.Substring($root.Length).TrimStart('\'))"
    }
  }
}


# ---------------- MAIN ----------------
$ProjectRoot = Norm $ProjectRoot
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

Log "RUN_START Apply=$Apply Force=$Force Root=$ProjectRoot"
if (-not (TestGitClean -root $ProjectRoot -forceLocal:$Force)) { exit 2 }

$human = Join-Path $ProjectRoot "HUMAN.README"
$dead  = Join-Path $ProjectRoot "03_ARTIFACTS\DeadHistory\HUMAN.README"
$snap  = Join-Path $ProjectRoot "03_ARTIFACTS\History\Snapshots\HUMAN.README"
$casebook = Join-Path $human "CASEBOOK"
$legacyDir = Join-Path $dead "LEGACY"
$deadCasebook = Join-Path $dead "CASEBOOK"

EnsureDir $human
EnsureDir $dead
EnsureDir $snap
EnsureDir $casebook
EnsureDir $legacyDir
EnsureDir $deadCasebook

# 1) Mapping canon renames (old -> new)
$canonMap = @(
  @{ old="HUMAN.README\00.0_HUMAN.GENERAL.txt";         new="HUMAN.README\00.0_HUMAN.GENERAL.txt" },
  @{ old="HUMAN.README\01.0_HUMAN.USER.txt";      new="HUMAN.README\01.0_HUMAN.USER.txt" },
  @{ old="HUMAN.README\03.0_HUMAN.RADAR.txt";    new="HUMAN.README\03.0_HUMAN.RADAR.txt" },
  @{ old="HUMAN.README\04.0_HUMAN.BATON.txt";    new="HUMAN.README\04.0_HUMAN.BATON.txt" },
  @{ old="HUMAN.README\05.0_HUMAN.CIS.txt";            new="HUMAN.README\05.0_HUMAN.CIS.txt" },
  @{ old="HUMAN.README\06.0_HUMAN.PF0.txt";       new="HUMAN.README\06.0_HUMAN.PF0.txt" },
  @{ old="HUMAN.README\07.0_HUMAN.MASTER.txt";         new="HUMAN.README\07.0_HUMAN.MASTER.txt" },
  @{ old="HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt"; new="HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt" }
)

# 2) Ensure canonical UseCase file exists
$useCaseCanon = Join-Path $human "02.0_HUMAN.USE.CASE.txt"
if (-not (Test-Path -LiteralPath $useCaseCanon)) {
  if ($Apply) {
@"
02.0_HUMAN.USE.CASE.txt
DATE......: $(Get-Date -Format "yyyy-MM-dd")
TIME......: $(Get-Date -Format "HH:mm")
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION......: 0.1

01.00_PURPOSE
Cadena de mando: Use Cases canónicos.
Los casos detallados se guardan en HUMAN.README\CASEBOOK\ (HIA_HUM_00xx*).

02.00_INDEX
- (pendiente) Caso real: Precio x Absorción -> TIR
"@ | Out-File -FilePath $useCaseCanon -Encoding utf8
  }
  Log "CREATE_FILE: HUMAN.README\02.0_HUMAN.USE.CASE.txt"
}

# 3) Snap critical files before edits/moves
$syncRunner = Join-Path $ProjectRoot "02_TOOLS\Invoke-HIASync.ps1"
BackupFile -path $syncRunner -snapDir $snap
BackupFile -path (Join-Path $ProjectRoot "HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt") -snapDir $snap
BackupFile -path (Join-Path $ProjectRoot "HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt") -snapDir $snap

# 4) Apply canonical renames
$repl = @{}
foreach ($m in $canonMap) {
  $oldAbs = Join-Path $ProjectRoot $m.old
  $newAbs = Join-Path $ProjectRoot $m.new
  if (Test-Path -LiteralPath $oldAbs) {
    MoveItem -src $oldAbs -dst $newAbs
    $repl[$m.old] = $m.new
  } else {
    Log "SKIP (no existe): $($m.old)" "WARN"
  }
}

# 5) Move legacy HumanR*.txt (except HumanRGeneral already handled)
$legacyCandidates = Get-ChildItem -LiteralPath $human -File -Force -Filter "HumanR*.txt" -ErrorAction SilentlyContinue
foreach ($f in $legacyCandidates) {
  if ($f.Name -ieq "HumanRGeneral.txt") { continue }
  $src = $f.FullName
  $dst = Join-Path $legacyDir $f.Name
  MoveItem -src $src -dst $dst
  $repl["HUMAN.README\$($f.Name)"] = ("03_ARTIFACTS\DeadHistory\HUMAN.README\LEGACY\$($f.Name)")
}

# 6) Move Casebook files (HIA_HUM_*.txt) into HUMAN.README\CASEBOOK\
$caseFiles = Get-ChildItem -LiteralPath $human -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '^HIA_HUM_\d{4}\.' -or $_.Name -match '^HIA_HUM_\d{4}_' }

foreach ($f in $caseFiles) {
  $src = $f.FullName
  $dst = Join-Path $casebook $f.Name
  MoveItem -src $src -dst $dst
  $repl["HUMAN.README\$($f.Name)"] = ("HUMAN.README\CASEBOOK\$($f.Name)")
}

# 7) Update references across repo
# Update runner sync manifest reference specifically if present
$repl["HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt"] = "HUMAN.README\08.0_HUMAN.SYNC.MANIFEST.txt"
ReplaceRefs -root $ProjectRoot -map $repl

Log "RUN_END OK"
