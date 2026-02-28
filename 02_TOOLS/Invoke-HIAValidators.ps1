<#
==========
00.00_METADATOS_DEL_DOCUMENTO
==========

ID_UNICO..........: HIA.TOOL.PS1.0003
NOMBRE_SUGERIDO...: Invoke-HIAValidators.ps1
VERSION...........: v1.0-DRAFT
FECHA.............: 2026-02-26
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Maria Luisa, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.2 Thinking

ALCANCE...........:
Runner único para ejecutar validadores allowlisted:
- Test-HIAIdsAndNames
- Test-HIAFileContent
Consolidando salida y entregando OK/FAIL binario real.

NO_CUBRE..........:
- No modifica archivos del proyecto.
- No ejecuta herramientas externas fuera de allowlist.

DEPENDENCIAS......:
02_TOOLS\Test-HIAIdsAndNames.ps1
02_TOOLS\Test-HIAFileContent.ps1
08.STANDAR.PROBLEM_TROUBLE_INCIDENTS.txt

==========
00.10_COMO_EJECUTAR
==========

CASO TIPICO (DRAFT):
pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -Mode DRAFT

MODO CANON (estricto):
pwsh -NoProfile -File .\02_TOOLS\Invoke-HIAValidators.ps1 -Mode CANON

SALIDA:
- Consola: resumen
- Logs:
  .\03_ARTIFACTS\LOGS\VALIDATION.RUNNER.YYYYMMDD_HHMMSS.txt

ESTADO FINAL:
- Exit 0 si ambos validadores OK
- Exit 1 si alguno FAIL
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

function Test-EnsureDirectory {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Get-NowStamp {
  return (Get-Date).ToString("yyyyMMdd_HHmmss")
}

try {
  if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Error "FAIL: RootPath no existe: $RootPath"
    exit 1
  }

  $logsDir = Join-Path $RootPath "03_ARTIFACTS\LOGS"
  Test-EnsureDirectory -Path $logsDir
  $stamp = Get-NowStamp
  $runnerLog = Join-Path $logsDir ("VALIDATION.RUNNER.$stamp.txt")

  $toolIds = Join-Path $RootPath "02_TOOLS\Test-HIAIdsAndNames.ps1"
  $toolFc  = Join-Path $RootPath "02_TOOLS\Test-HIAFileContent.ps1"

  if (-not (Test-Path -LiteralPath $toolIds)) {
    Write-Error "FAIL: No existe: $toolIds"
    exit 1
  }
  if (-not (Test-Path -LiteralPath $toolFc)) {
    Write-Error "FAIL: No existe: $toolFc"
    exit 1
  }

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("==========") | Out-Null
  $lines.Add("VALIDATION.RUNNER") | Out-Null
  $lines.Add("==========") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add("ROOT..............: $RootPath") | Out-Null
  $lines.Add("MODE..............: $Mode") | Out-Null
  $lines.Add("TIMESTAMP.........: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))") | Out-Null
  $lines.Add("") | Out-Null

  $fail = $false

  # 01) IDs & Names
  $lines.Add("----------") | Out-Null
  $lines.Add("STEP..............: Test-HIAIdsAndNames") | Out-Null
  $lines.Add("----------") | Out-Null
  $cmd1 = "pwsh -NoProfile -File `"$toolIds`" -RootPath `"$RootPath`" -Mode $Mode"
  $lines.Add("CMD...............: $cmd1") | Out-Null

  $out1 = & pwsh -NoProfile -File $toolIds -RootPath $RootPath -Mode $Mode 2>&1
  $code1 = $LASTEXITCODE
  $lines.Add("EXIT_CODE.........: $code1") | Out-Null
  $lines.Add("OUTPUT............:") | Out-Null
  $lines.Add(($out1 | Out-String).TrimEnd()) | Out-Null
  $lines.Add("") | Out-Null

  if ($code1 -ne 0) { $fail = $true }

  # 02) FileContent
  $lines.Add("----------") | Out-Null
  $lines.Add("STEP..............: Test-HIAFileContent") | Out-Null
  $lines.Add("----------") | Out-Null
  $cmd2 = "pwsh -NoProfile -File `"$toolFc`" -RootPath `"$RootPath`" -Mode $Mode"
  $lines.Add("CMD...............: $cmd2") | Out-Null

  $out2 = & pwsh -NoProfile -File $toolFc -RootPath $RootPath -Mode $Mode 2>&1
  $code2 = $LASTEXITCODE
  $lines.Add("EXIT_CODE.........: $code2") | Out-Null
  $lines.Add("OUTPUT............:") | Out-Null
  $lines.Add(($out2 | Out-String).TrimEnd()) | Out-Null
  $lines.Add("") | Out-Null

  if ($code2 -ne 0) { $fail = $true }

  [System.IO.File]::WriteAllLines($runnerLog, $lines, [System.Text.Encoding]::UTF8)

  if ($fail) {
    Write-Error "FAIL: Validators failed. See: $runnerLog"
    exit 1
  }

  Write-Output "OK: Validators passed. See: $runnerLog"
  exit 0

} catch {
  Write-Error ("FAIL: " + $_.Exception.Message)
  exit 1
}