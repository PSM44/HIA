<#
==========
00.00_METADATOS_DEL_DOCUMENTO
==========

ID_UNICO..........: HIA.TOOL.PS1.0001
NOMBRE_SUGERIDO...: Test-HIAFileContent.ps1
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-26
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Maria Luisa, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.2 Thinking

ALCANCE...........:
Validador mínimo de formato interno FILE_CONTENT para archivos .txt del root HIA:
- detecta bloque de metadatos, índice WBS, changelog (si CANON),
- detecta formato de títulos 10x (= - + *),
- genera reporte y exit code binario OK/FAIL.
NO_CUBRE..........:
- No valida coherencia semántica.
- No valida IDs del filesystem (eso es Test-HIAIdsAndNames).
DEPENDENCIAS......:
HIA_TOO_0001_VALIDATORS_SPEC.txt
07.STANDAR.FILE_CONTENT.txt
08.STANDAR.PROBLEM_TROUBLE_INCIDENTS.txt

==========
00.10_COMO_EJECUTAR
==========

CASO TIPICO:
pwsh -NoProfile -File .\02_TOOLS\Test-HIAFileContent.ps1

MODO CANON (más estricto):
pwsh -NoProfile -File .\02_TOOLS\Test-HIAFileContent.ps1 -Mode CANON

ESPECIFICAR ROOT:
pwsh -NoProfile -File .\02_TOOLS\Test-HIAFileContent.ps1 -RootPath "C:\...\HIA"

SALIDA:
- Consola: resumen OK/FAIL
- Archivo log:
  C:\...\HIA\03_ARTIFACTS\LOGS\VALIDATION.FILECONTENT.YYYYMMDD_HHMMSS.txt

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
  [string] $Mode = "DRAFT"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================
# 01.00_HELPERS (verbos aprobados)
# ============================

function Test-EnsureDirectory {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Get-NowStamp {
  return (Get-Date).ToString("yyyyMMdd_HHmmss")
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

function Test-HasTenCharsLine {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][char]$Char
  )
  $line = ($Char.ToString() * 10)
  return ($Text -match [regex]::Escape($line))
}

function Test-ContainsAllFields {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string[]]$Fields
  )
  foreach ($f in $Fields) {
    if ($Text -notmatch [regex]::Escape($f)) { return $false }
  }
  return $true
}

# ============================
# 02.00_INIT
# ============================

try {
  if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Error "FAIL: RootPath no existe: $RootPath"
    exit 1
  }

  $logsDir = Join-Path $RootPath "03_ARTIFACTS\LOGS"
  Test-EnsureDirectory -Path $logsDir
  $stamp = Get-NowStamp
  $logPath = Join-Path $logsDir ("VALIDATION.FILECONTENT.$stamp.txt")

  # Archivos .txt solo en ROOT (tu preferencia: muchos archivos grandes en root)
  $txtFiles = Get-ChildItem -LiteralPath $RootPath -File -Filter "*.txt" -ErrorAction Stop

  $requiredFields = @(
    "ID_UNICO", "NOMBRE_SUGERIDO", "VERSION", "FECHA", "CIUDAD", "UBICACION_SISTEMA", "ALCANCE", "NO_CUBRE", "DEPENDENCIAS"
  )

  $results = New-Object System.Collections.Generic.List[object]
  $failCount = 0
  $warnCount = 0

  foreach ($f in $txtFiles) {
    $issues = New-Object System.Collections.Generic.List[string]
    $status = "OK"

    $content = ""
    try {
      $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
    } catch {
      $status = "FAIL"
      $issues.Add("READ_ERROR: $($_.Exception.Message)") | Out-Null
      $results.Add((New-ResultItem -Path $f.Name -Status $status -Issues $issues)) | Out-Null
      $failCount++
      continue
    }

    # 03.00 Checks mínimos
    if ($content -notmatch "00\.00_METADATOS_DEL_DOCUMENTO") {
      $status = "FAIL"
      $issues.Add("MISSING: 00.00_METADATOS_DEL_DOCUMENTO") | Out-Null
    }

    if ($content -notmatch "00\.10_INDICE_GENERAL_WBS") {
      if ($Mode -eq "CANON") { $status = "FAIL" } else { if ($status -ne "FAIL") { $status = "WARN" } }
      $issues.Add("MISSING: 00.10_INDICE_GENERAL_WBS") | Out-Null
    }

    if (-not (Test-ContainsAllFields -Text $content -Fields $requiredFields)) {
      $status = "FAIL"
      $issues.Add("MISSING: one or more required metadata fields") | Out-Null
    }

    # 10x título formatting (mínimo)
    if (-not (Test-HasTenCharsLine -Text $content -Char '=')) {
      if ($Mode -eq "CANON") { $status = "FAIL" } else { if ($status -ne "FAIL") { $status = "WARN" } }
      $issues.Add("MISSING: 10x '=' title lines") | Out-Null
    }
    if (-not (Test-HasTenCharsLine -Text $content -Char '-')) {
      if ($Mode -eq "CANON") { $status = "FAIL" } else { if ($status -ne "FAIL") { $status = "WARN" } }
      $issues.Add("MISSING: 10x '-' subtitle lines") | Out-Null
    }
    if (-not (Test-HasTenCharsLine -Text $content -Char '+')) {
      if ($Mode -eq "CANON") { $status = "FAIL" } else { if ($status -ne "FAIL") { $status = "WARN" } }
      $issues.Add("MISSING: 10x '+' sub-subtitle lines") | Out-Null
    }

    # CHANGELOG si CANON
    $isCanon = ($content -match "VERSION\.\.\.\.\.\.\.\.\.\.\.:.*-CANON")
    if ($isCanon -and ($content -notmatch "CHANGELOG")) {
      $status = "FAIL"
      $issues.Add("MISSING: CHANGELOG for CANON file") | Out-Null
    }

    if ($status -eq "FAIL") { $failCount++ }
    elseif ($status -eq "WARN") { $warnCount++ }

    $results.Add((New-ResultItem -Path $f.Name -Status $status -Issues $issues)) | Out-Null
  }

  # ============================
  # 04.00 Output report
  # ============================

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("==========") | Out-Null
  $lines.Add("VALIDATION.FILECONTENT") | Out-Null
  $lines.Add("==========") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add(("ROOT..............: {0}" -f $RootPath)) | Out-Null
  $lines.Add(("MODE..............: {0}" -f $Mode)) | Out-Null
  $lines.Add(("TOTAL_FILES.......: {0}" -f $txtFiles.Count)) | Out-Null
  $lines.Add(("FAIL_COUNT........: {0}" -f $failCount)) | Out-Null
  $lines.Add(("WARN_COUNT........: {0}" -f $warnCount)) | Out-Null
  $lines.Add(("TIMESTAMP.........: {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))) | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("----------") | Out-Null
  $lines.Add("DETAIL") | Out-Null
  $lines.Add("----------") | Out-Null

  foreach ($r in $results) {
    $lines.Add(("FILE..............: {0}" -f $r.Path)) | Out-Null
    $lines.Add(("STATUS............: {0}" -f $r.Status)) | Out-Null
    $lines.Add(("ISSUES............: {0}" -f $r.Issues)) | Out-Null
    $lines.Add("") | Out-Null
  }

  [System.IO.File]::WriteAllLines($logPath, $lines, [System.Text.Encoding]::UTF8)

  if ($failCount -gt 0) {
    Write-Error "FAIL: FileContent validation failed. See: $logPath"
    exit 1
  }

  Write-Output "OK: FileContent validation passed. WARN=$warnCount. Log: $logPath"
  exit 0

} catch {
  Write-Error ("FAIL: " + $_.Exception.Message)
  exit 1
}