<#
[HIA_TOL_0018] Fix-HUMAN_ID_UNICO.ps1
DATE......: 2026-03-02
TIME......: 01:40
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.1

PURPOSE...
  Inserta/normaliza ID_UNICO en HUMAN.README canónicos para que SYNC/Validators
  puedan resolver fuentes por ID (no por filename).
  No toca contenido conceptual: solo metadata (prepend/replace de línea).

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0018_Fix-HUMAN_ID_UNICO.ps1 -ProjectRoot "C:\...\HIA"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log($m,$lvl="INFO"){ Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))][$lvl] $m" }

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
if (-not (Test-Path -LiteralPath $ProjectRoot)) { throw "ProjectRoot no existe: [$ProjectRoot]" }

$humanDir = Join-Path $ProjectRoot "HUMAN.README"

$targets = @(
  @{ path = Join-Path $humanDir "03.0_HUMAN.RADAR.txt"; id="HUMAN.RADAR.0001" },
  @{ path = Join-Path $humanDir "04.0_HUMAN.BATON.txt"; id="HUMAN.BATON.0001" },
  @{ path = Join-Path $humanDir "05.0_HUMAN.CIS.txt";   id="HUMAN.CIS.0001"   },
  @{ path = Join-Path $humanDir "06.0_HUMAN.PF0.txt";   id="HUMAN.PF0.0001"   }
)

foreach($t in $targets){
  $p = $t.path
  $id = $t.id

  if(-not (Test-Path -LiteralPath $p)){
    Log "SKIP (no existe): $p" "WARN"
    continue
  }

  $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8

  # Solo mirar header (primeras 120 líneas) para decidir si existe ID_UNICO real
  $lines = $raw -split "(`r`n|`n|`r)"
  $headN = [Math]::Min(120, $lines.Count)
  $head = ($lines[0..($headN-1)] -join "`n")

  if($head -match '(?im)^\s*ID_UNICO\s*[:=]'){
    # Normalizar si existe pero con otro valor
    $newHead = $head -replace '(?im)^\s*ID_UNICO\s*[:=]\s*.*$', "ID_UNICO=$id"
    if($newHead -ne $head){
      # Reemplazar solo en el header original
      $lines[0..($headN-1)] = ($newHead -split "`n")
      $newRaw = ($lines -join "`r`n")
      Set-Content -LiteralPath $p -Value $newRaw -Encoding UTF8
      Log "UPDATED ID_UNICO: $($p.Substring($ProjectRoot.Length).TrimStart('\')) -> $id"
    } else {
      Log "NOCHANGE ID_UNICO: $($p.Substring($ProjectRoot.Length).TrimStart('\'))"
    }
  } else {
    # Insertar ID_UNICO en la parte superior (prepend no destructivo)
    $prefix = @()
    $prefix += "ID_UNICO=$id"
    $prefix += ""  # línea en blanco
    $newRaw = ($prefix -join "`r`n") + $raw
    Set-Content -LiteralPath $p -Value $newRaw -Encoding UTF8
    Log "INSERTED ID_UNICO: $($p.Substring($ProjectRoot.Length).TrimStart('\')) -> $id"
  }
}

Log "DONE"