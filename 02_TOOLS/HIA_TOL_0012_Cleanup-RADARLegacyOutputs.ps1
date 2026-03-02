[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [Parameter(Mandatory=$true)]
  [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = ($ProjectRoot -as [string]).Trim().Trim('"').Trim("'") -replace "[`r`n]",""
$radarDir = Join-Path $ProjectRoot "03_ARTIFACTS\RADAR"
$oldDir = Join-Path $radarDir "old"
New-Item -ItemType Directory -Path $oldDir -Force | Out-Null

$stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$legacyBucket = Join-Path $oldDir ("LEGACY_OUTPUTS." + $stamp)
New-Item -ItemType Directory -Path $legacyBucket -Force | Out-Null

$legacy = @(
  "HIA_RAD_INDEX.REPO.ACTIVE.txt",
  "HIA_RAD_0004_FULL.FULL.ACTIVE.txt",
  "HIA_RAD_POINTERS.ACTIVE.txt"
)

foreach ($name in $legacy) {
  $p = Join-Path $radarDir $name
  if (Test-Path -LiteralPath $p) {
    $dst = Join-Path $legacyBucket $name
    if ($PSCmdlet.ShouldProcess($p, "Move to $dst")) {
      Move-Item -LiteralPath $p -Destination $dst -Force
    }
  }
}

Write-Host "DONE: Legacy outputs moved to $legacyBucket"