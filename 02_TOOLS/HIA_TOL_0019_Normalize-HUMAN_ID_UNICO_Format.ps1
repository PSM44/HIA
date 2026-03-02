<#
[HIA_TOL_0019] Normalize-HUMAN_ID_UNICO_Format.ps1
DATE......: 2026-03-02
TIME......: 01:40
TZ........: America/Santiago
CITY......: Santiago, Chile
VERSION...: 0.1

PURPOSE...
  Convierte ID_UNICO=XXXX -> ID_UNICO..........: XXXX (formato compatible con Invoke-HIAValidators.ps1)
  y elimina duplicados en header si aparecen.

USAGE...
  pwsh -NoProfile -File .\02_TOOLS\HIA_TOL_0019_Normalize-HUMAN_ID_UNICO_Format.ps1 -ProjectRoot "C:\...\HIA"
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
  $p  = $t.path
  $id = $t.id

  if(-not (Test-Path -LiteralPath $p)){
    Log "SKIP (no existe): $p" "WARN"
    continue
  }

  $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8

  # 1) Si existe ID_UNICO=..., reemplazarlo por ID_UNICO..........: ...
  $new = $raw -replace '(?im)^\s*ID_UNICO\s*=\s*.*$', ("ID_UNICO..........: " + $id)

  # 2) Si existe ID_UNICO...: pero con otro valor, normalizar valor
  $new = $new -replace '(?im)^\s*ID_UNICO\.+:\s*.*$', ("ID_UNICO..........: " + $id)

  # 3) Deduplicar: si por cualquier razón quedaron varias líneas ID_UNICO en header, quedarse con la primera
  $lines = $new -split "(`r`n|`n|`r)"
  $out = New-Object System.Collections.Generic.List[string]
  $seen = $false
  foreach($ln in $lines){
    if($ln -match '^(?i)\s*ID_UNICO'){
      if(-not $seen){
        $out.Add($ln) | Out-Null
        $seen = $true
      } else {
        # skip duplicates
        continue
      }
    } else {
      $out.Add($ln) | Out-Null
    }
  }

  $final = ($out -join "`r`n")
  if($final -ne $raw){
    Set-Content -LiteralPath $p -Value $final -Encoding UTF8
    Log "NORMALIZED: $($p.Substring($ProjectRoot.Length).TrimStart('\')) -> ID_UNICO..........: $id"
  } else {
    Log "NOCHANGE: $($p.Substring($ProjectRoot.Length).TrimStart('\'))"
  }
}

Log "DONE"