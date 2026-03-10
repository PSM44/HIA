<#
========================================================================================
SCRIPT: Invoke-HIAValidators.ps1
ID_UNICO: HIA.TOOL.VALIDATORS.0001
VERSION: v1.1-DRAFT
FECHA: 2026-03-03
HORA: HH:MM (America/Santiago)
CIUDAD: Santiago, Chile

OBJETIVO:
  Runner único y canónico para ejecutar validaciones del repositorio HIA con severidad
  controlada por -Mode.

MODOS:
  -Mode DRAFT:
    - Permite working tree sucio.
    - WARN no rompe (solo FAIL duro rompe).
  -Mode CANON:
    - Exige git limpio (salvo -Force).
    - WARN cuenta como FAIL.

VALIDADORES CANÓNICOS (MVP):
  1) 02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1

SALIDAS:
  - Log: 03_ARTIFACTS\LOGS\VALIDATION.RUNNER.<timestamp>.txt
  - ExitCode: 0 OK / 1 FAIL

EJECUCIÓN:
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -ProjectRoot "<ROOT>" -Mode DRAFT
  pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -ProjectRoot "<ROOT>" -Mode CANON

NOTAS:
  - Este script NO hace Sync (DERIVED). Eso lo hace Invoke-HIASync.ps1.
  - Evita verbos no aprobados: solo Invoke/Test/Repair/etc.
========================================================================================
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $ProjectRoot,

  [Parameter(Mandatory = $false)]
  [ValidateSet("DRAFT","CANON")]
  [string] $Mode = "DRAFT",

  [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-HIALog([string]$Message, [string]$Level = "INFO") {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts][$Level] $Message"
}

# Back-compat / peatón-proof: algunos bloques llaman "Log" por costumbre.
Set-Alias -Name Log -Value Write-HIALog -Scope Script

function New-HIADirectory([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -LiteralPath $Path -Force | Out-Null
  }
}

function Get-Timestamp() {
  return (Get-Date).ToString("yyyyMMdd_HHmmss")
}

function Write-RunLog([string]$LogPath, [string[]]$Lines) {
  $dir = Split-Path -Parent $LogPath
  New-HIADirectory $dir
  $Lines | Set-Content -LiteralPath $LogPath -Encoding UTF8
}

# -------- Normalize inputs --------
$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""

if ($ProjectRoot -match '<PROJECT_ROOT>' -or $ProjectRoot -match '^\s*<.*>\s*$') {
  throw "ProjectRoot contiene placeholder '<PROJECT_ROOT>'. Reemplázalo por ruta real (ej: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA)."
}

if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: $ProjectRoot" }

$ts = Get-Timestamp
$logPath = Join-Path $ProjectRoot ("03_ARTIFACTS\LOGS\VALIDATION.RUNNER.{0}.txt" -f $ts)
$log = New-Object System.Collections.Generic.List[string]

Push-Location $ProjectRoot
try {
  Write-HIALog "RUN_START ProjectRoot=$ProjectRoot Mode=$Mode Force=$Force"
  $log.Add(("[{0}][INFO] RUN_START ProjectRoot={1} Mode={2} Force={3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $ProjectRoot, $Mode, $Force))

  # ---- Guard rails: git cleanliness ----
  $porc = git status --porcelain
  $isDirty = -not [string]::IsNullOrWhiteSpace($porc)

  if ($Mode -eq "CANON" -and $isDirty -and -not $Force) {
    Log "Git status no está limpio (CANON). Haz commit/stash o re-ejecuta con -Force." "ERROR"
    $log.Add(("[{0}][ERROR] Git status no está limpio (CANON). Haz commit/stash o re-ejecuta con -Force." -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
    $log.Add(("[{0}][ERROR] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), ($porc -join " ")))
    Write-RunLog $logPath $log.ToArray()
    exit 1
  }

  if ($Mode -eq "DRAFT" -and $isDirty) {
    Log "Git status dirty (DRAFT): permitido. (Para enforcement usa -Mode CANON)" "WARN"
    $log.Add(("[{0}][WARN] Git status dirty (DRAFT): permitido. (Para enforcement usa -Mode CANON)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
  }

  # ---- Run validators (allowlist) ----
  $warnCount = 0
  $failCount = 0

  # ---- Phase1 Gate: Project Structure Spec (documental, determinista) ----
  # Regla: si existen proyectos reales en 04_PROJECTS, cada uno debe tener 00.0_PROJECT.STRUCTURE.txt
  $projectsRoot = Join-Path $ProjectRoot "04_PROJECTS"

  if (-not (Test-Path -LiteralPath $projectsRoot)) {
    Log "STRUCTURE_GATE: 04_PROJECTS no existe (skip)" "INFO"
$log.Add(("[{0}][INFO] STRUCTURE_GATE: 04_PROJECTS no existe (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
# Nota: no incrementa warnCount (skip no es warning)
    $log.Add(("[{0}][WARN] STRUCTURE_GATE: 04_PROJECTS no existe (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
    $warnCount++
  } else {
    $projDirs = Get-ChildItem -LiteralPath $projectsRoot -Directory -Force -ErrorAction SilentlyContinue
    if (-not $projDirs -or $projDirs.Count -eq 0) {
Log "STRUCTURE_GATE: sin proyectos en 04_PROJECTS (skip)" "INFO"
$log.Add(("[{0}][INFO] STRUCTURE_GATE: sin proyectos en 04_PROJECTS (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
# Nota: skip no incrementa warnCount (en CANON WARN=>FAIL)
    } else {
      foreach($d in $projDirs) {
        $spec = Join-Path $d.FullName "00.0_PROJECT.STRUCTURE.txt"
        if (-not (Test-Path -LiteralPath $spec)) {
          Log ("STRUCTURE_GATE_FAIL: falta 00.0_PROJECT.STRUCTURE.txt project={0}" -f $d.Name) "ERROR"
          $log.Add(("[{0}][ERROR] STRUCTURE_GATE_FAIL: project={1} missing=00.0_PROJECT.STRUCTURE.txt" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name))
          $failCount++
          continue
        }

        $len = (Get-Item -LiteralPath $spec).Length
        if ($len -le 0) {
          Log ("STRUCTURE_GATE_FAIL: spec vacío project={0}" -f $d.Name) "ERROR"
          $log.Add(("[{0}][ERROR] STRUCTURE_GATE_FAIL: project={1} spec_empty" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name))
          $failCount++
          continue
        }

        Log ("STRUCTURE_GATE_OK: project={0} bytes={1}" -f $d.Name,$len)
        $log.Add(("[{0}][INFO] STRUCTURE_GATE_OK: project={1} bytes={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name, $len))
      }
    }
  }

  $validators = @(
    @{ Name="Test-HIAFileContentRecursive"; Path="02_TOOLS\HIA_TOL_0007_Test-HIAFileContentRecursive.ps1" }
  )

  foreach($v in $validators) {
    $name = $v.Name
    $path = $v.Path
    if(-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $path))) {
      Log "VALIDATOR_NOT_FOUND Name=$name Path=$path" "ERROR"
      $log.Add(("[{0}][ERROR] VALIDATOR_NOT_FOUND Name={1} Path={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $name, $path))
      $failCount++
      continue
    }

    Log "RUN_VALIDATOR Name=$name Path=$path"
    $log.Add(("[{0}][INFO] RUN_VALIDATOR Name={1} Path={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $name, $path))

    # Contract: el validator debe retornar exit code 0 ok / 1 fail.
    pwsh -NoProfile -File (Join-Path $ProjectRoot $path) -ProjectRoot $ProjectRoot | Out-Null
    $exit = $LASTEXITCODE

    if($exit -eq 0) {
      Log "VALIDATOR_EXIT_OK Name=$name ExitCode=$exit"
      $log.Add(("[{0}][INFO] VALIDATOR_EXIT_OK Name={1} ExitCode={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $name, $exit))
    } else {
      Log "VALIDATOR_EXIT_FAIL Name=$name ExitCode=$exit" "ERROR"
      $log.Add(("[{0}][ERROR] VALIDATOR_EXIT_FAIL Name={1} ExitCode={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $name, $exit))
      $failCount++
    }
  }

    # ---- Phase1 Gate: Project Structure Spec (documental, determinista) ----
  # Regla: si existen proyectos reales en 04_PROJECTS, cada uno debe tener 00.0_PROJECT.STRUCTURE.txt
  $projectsRoot = Join-Path $ProjectRoot "04_PROJECTS"
  if (-not (Test-Path -LiteralPath $projectsRoot)) {
    Log "STRUCTURE_GATE: 04_PROJECTS no existe (skip)" "INFO"
$log.Add(("[{0}][INFO] STRUCTURE_GATE: 04_PROJECTS no existe (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
# Nota: no incrementa warnCount (skip no es warning)
    $log.Add(("[{0}][WARN] STRUCTURE_GATE: 04_PROJECTS no existe (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
    $warnCount++
  } else {
    $projDirs = Get-ChildItem -LiteralPath $projectsRoot -Directory -Force -ErrorAction SilentlyContinue
    if (-not $projDirs -or $projDirs.Count -eq 0) {
Log "STRUCTURE_GATE: sin proyectos en 04_PROJECTS (skip)" "INFO"
$log.Add(("[{0}][INFO] STRUCTURE_GATE: sin proyectos en 04_PROJECTS (skip)" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")))
# Nota: skip no incrementa warnCount (en CANON WARN=>FAIL)
    } else {
      foreach($d in $projDirs) {
        $spec = Join-Path $d.FullName "00.0_PROJECT.STRUCTURE.txt"
        if (-not (Test-Path -LiteralPath $spec)) {
          Log ("STRUCTURE_GATE_FAIL: falta 00.0_PROJECT.STRUCTURE.txt en proyecto={0}" -f $d.Name) "ERROR"
          $log.Add(("[{0}][ERROR] STRUCTURE_GATE_FAIL: project={1} missing=00.0_PROJECT.STRUCTURE.txt" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name))
          $failCount++
        } else {
          $len = (Get-Item -LiteralPath $spec).Length
          if ($len -le 0) {
            Log ("STRUCTURE_GATE_FAIL: spec vacío project={0}" -f $d.Name) "ERROR"
            $log.Add(("[{0}][ERROR] STRUCTURE_GATE_FAIL: project={1} spec_empty" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name))
            $failCount++
          } else {
            Log ("STRUCTURE_GATE_OK: project={0} bytes={1}" -f $d.Name,$len)
            $log.Add(("[{0}][INFO] STRUCTURE_GATE_OK: project={1} bytes={2}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $d.Name, $len))
          }
        }
      }
    }
  }

  # ---- Mode policy: WARN as FAIL in CANON ----
  if ($Mode -eq "CANON" -and $warnCount -gt 0) {
    $failCount += $warnCount
  }

  if ($failCount -gt 0) {
    Log "RUN_END FAIL warnCount=$warnCount failCount=$failCount Log=$logPath" "ERROR"
    $log.Add(("[{0}][ERROR] RUN_END FAIL warnCount={1} failCount={2} Log={3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $warnCount, $failCount, $logPath))
    Write-RunLog $logPath $log.ToArray()
    exit 1
  }

  Log "RUN_END OK warnCount=$warnCount failCount=$failCount Log=$logPath"
  $log.Add(("[{0}][INFO] RUN_END OK warnCount={1} failCount={2} Log={3}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $warnCount, $failCount, $logPath))
  Write-RunLog $logPath $log.ToArray()
  exit 0

} catch {
  $msg = $_.Exception.Message
  Log "RUN_CRASH $msg" "ERROR"
  $log.Add(("[{0}][ERROR] RUN_CRASH {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $msg))
  Write-RunLog $logPath $log.ToArray()
  exit 1
} finally {
  Pop-Location
}