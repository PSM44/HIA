<#
==========
00.00_METADATOS_DEL_DOCUMENTO
==========

ID_UNICO..........: HIA.TOOL.PS1.0002
NOMBRE_SUGERIDO...: Test-HIAIdsAndNames.ps1
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-26
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Maria Luisa, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.2 Thinking

ALCANCE...........:
Validador mínimo de naming/IDs para archivos .txt en root HIA:
- valida regex de ID_FS: HIA_<TIPO>_<NNNN>_<SUFIJO>.txt
- detecta espacios/tildes/ñ (ASCII-only)
- detecta duplicados funcionales (routing/cost/policy duplicados)
- valida allowlist de scripts en 02_TOOLS
- genera reporte y exit code binario OK/FAIL.
NO_CUBRE..........:
- No valida contenido interno (eso es Test-HIAFileContent).
DEPENDENCIAS......:
HIA_TOO_0001_VALIDATORS_SPEC.txt
06.STANDAR.WBS_ID.txt
08.STANDAR.PROBLEM_TROUBLE_INCIDENTS.txt

==========
00.10_COMO_EJECUTAR
==========

CASO TIPICO:
pwsh -NoProfile -File .\02_TOOLS\Test-HIAIdsAndNames.ps1

MODO CANON (más estricto):
pwsh -NoProfile -File .\02_TOOLS\Test-HIAIdsAndNames.ps1 -Mode CANON

CUSTOM REGEX (si quieres permitir cosas adicionales):
pwsh -NoProfile -File .\02_TOOLS\Test-HIAIdsAndNames.ps1 -RegexNaming '^HIA_[A-Z]{3}_[0-9]{4}_[A-Z0-9_]{2,50}\.txt$'

SALIDA:
- Log:
  C:\...\HIA\03_ARTIFACTS\LOGS\VALIDATION.IDSANDNAMES.YYYYMMDD_HHMMSS.txt

ESTADO FINAL:
- Exit 0 si OK
- Exit 1 si FAIL
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string] $RootPath = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA",

  [Parameter(Mandatory = $false)]
  [ValidateSet("DRAFT","CANON")]
  [string] $Mode = "DRAFT",

  [Parameter(Mandatory = $false)]
  [string] $RegexNaming = '^HIA_[A-Z]{3}_[0-9]{4}_[A-Z0-9_]{2,50}\.txt$'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-EnsureDirectory {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Get-NowStamp {
  return (Get-Date).ToString("yyyyMMdd_HHmmss")
}

function Test-IsAsciiSafe {
  param([Parameter(Mandatory=$true)][string]$Text)
  # ASCII-only + underscore + dot + dash allowed; but your naming pattern already enforces.
  # Here we block obvious non-ASCII (tildes, ñ, etc.)
  foreach ($ch in $Text.ToCharArray()) {
    if ([int][char]$ch -gt 127) { return $false }
  }
  return $true
}

function New-ResultItem {
  param(
    [string]$Path,
    [string]$Status,
    [string[]]$Issues
  )
  return [pscustomobject]@{
    Path   = $Path
    Status = $Status
    Issues = ($Issues -join " | ")
  }
}

try {
  if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Error "FAIL: RootPath no existe: $RootPath"
    exit 1
  }

  $logsDir = Join-Path $RootPath "03_ARTIFACTS\LOGS"
  Test-EnsureDirectory -Path $logsDir
  $stamp = Get-NowStamp
  $logPath = Join-Path $logsDir ("VALIDATION.IDSANDNAMES.$stamp.txt")

  $txtFiles = Get-ChildItem -LiteralPath $RootPath -File -Filter "*.txt" -ErrorAction Stop
  $toolsDir = Join-Path $RootPath "02_TOOLS"

  # Allowlist de scripts en 02_TOOLS (ajústalo si agregas más)
  $allowedScripts = @(
    "RADAR.ps1",
    "Invoke-HIAValidators.ps1",
    "Test-HIAFileContent.ps1",
    "Test-HIAIdsAndNames.ps1"
  )

  $results = New-Object System.Collections.Generic.List[object]
  $failCount = 0
  $warnCount = 0

  # 01) Validar naming + ASCII
  foreach ($f in $txtFiles) {
    $issues = New-Object System.Collections.Generic.List[string]
    $status = "OK"

    if (-not (Test-IsAsciiSafe -Text $f.Name)) {
      $status = "FAIL"
      $issues.Add("NON_ASCII_FILENAME") | Out-Null
    }

    if ($f.Name -notmatch $RegexNaming) {
      if ($Mode -eq "CANON") { $status = "FAIL" } else { if ($status -ne "FAIL") { $status = "WARN" } }
      $issues.Add(("NAMING_MISMATCH: expected {0}" -f $RegexNaming)) | Out-Null
    }

    if ($status -eq "FAIL") { $failCount++ }
    elseif ($status -eq "WARN") { $warnCount++ }

    $results.Add((New-ResultItem -Path $f.Name -Status $status -Issues $issues)) | Out-Null
  }

  # 02) Duplicados funcionales (mínimo viable por TIPO+NNNN)
  # Regla: no debe existir más de 1 archivo por (TIPO, NNNN) en root.
  $keyMap = @{}
  foreach ($f in $txtFiles) {
    if ($f.Name -match '^HIA_([A-Z]{3})_([0-9]{4})_') {
      $tipo = $Matches[1]
      $nnnn = $Matches[2]
      $key = "$tipo|$nnnn"
      if (-not $keyMap.ContainsKey($key)) { $keyMap[$key] = @() }
      $keyMap[$key] += $f.Name
    }
  }

  foreach ($k in $keyMap.Keys) {
    $names = $keyMap[$k]
    if ($names.Count -gt 1) {
      # En DRAFT lo marcamos WARN; en CANON es FAIL.
      $msg = "DUPLICATE_KEY($k): " + ($names -join ", ")
      if ($Mode -eq "CANON") { $failCount++; $results.Add((New-ResultItem -Path "<ROOT>" -Status "FAIL" -Issues @($msg))) | Out-Null }
      else { $warnCount++; $results.Add((New-ResultItem -Path "<ROOT>" -Status "WARN" -Issues @($msg))) | Out-Null }
    }
  }

  # 03) Validar allowlist scripts en 02_TOOLS
  if (Test-Path -LiteralPath $toolsDir) {
    $scripts = Get-ChildItem -LiteralPath $toolsDir -File -Filter "*.ps1" -ErrorAction SilentlyContinue
    foreach ($s in $scripts) {
      if ($allowedScripts -notcontains $s.Name) {
        $msg = "UNALLOWLISTED_SCRIPT: $($s.Name)"
        if ($Mode -eq "CANON") { $failCount++; $results.Add((New-ResultItem -Path $s.FullName -Status "FAIL" -Issues @($msg))) | Out-Null }
        else { $warnCount++; $results.Add((New-ResultItem -Path $s.FullName -Status "WARN" -Issues @($msg))) | Out-Null }
      }
    }
  } else {
    # Si no existe 02_TOOLS, es WARN en DRAFT; FAIL en CANON.
    $msg = "MISSING_DIR: 02_TOOLS"
    if ($Mode -eq "CANON") { $failCount++; $results.Add((New-ResultItem -Path "<ROOT>" -Status "FAIL" -Issues @($msg))) | Out-Null }
    else { $warnCount++; $results.Add((New-ResultItem -Path "<ROOT>" -Status "WARN" -Issues @($msg))) | Out-Null }
  }

  # 04) Output log
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("==========") | Out-Null
  $lines.Add("VALIDATION.IDSANDNAMES") | Out-Null
  $lines.Add("==========") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add(("ROOT..............: {0}" -f $RootPath)) | Out-Null
  $lines.Add(("MODE..............: {0}" -f $Mode)) | Out-Null
  $lines.Add(("REGEX.............: {0}" -f $RegexNaming)) | Out-Null
  $lines.Add(("TOTAL_TXT.........: {0}" -f $txtFiles.Count)) | Out-Null
  $lines.Add(("FAIL_COUNT........: {0}" -f $failCount)) | Out-Null
  $lines.Add(("WARN_COUNT........: {0}" -f $warnCount)) | Out-Null
  $lines.Add(("TIMESTAMP.........: {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))) | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("----------") | Out-Null
  $lines.Add("DETAIL") | Out-Null
  $lines.Add("----------") | Out-Null

  foreach ($r in $results) {
    $lines.Add(("ITEM..............: {0}" -f $r.Path)) | Out-Null
    $lines.Add(("STATUS............: {0}" -f $r.Status)) | Out-Null
    $lines.Add(("ISSUES............: {0}" -f $r.Issues)) | Out-Null
    $lines.Add("") | Out-Null
  }

  [System.IO.File]::WriteAllLines($logPath, $lines, [System.Text.Encoding]::UTF8)

  if ($failCount -gt 0) {
    Write-Error "FAIL: IDs/Names validation failed. See: $logPath"
    exit 1
  }

  Write-Output "OK: IDs/Names validation passed. WARN=$warnCount. Log: $logPath"
  exit 0

} catch {
  Write-Error ("FAIL: " + $_.Exception.Message)
  exit 1
}