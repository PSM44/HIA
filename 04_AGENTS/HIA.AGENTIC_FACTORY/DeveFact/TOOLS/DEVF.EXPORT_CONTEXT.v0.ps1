<#
DEVF.EXPORT_CONTEXT.v0.ps1

Exports a compact DeveFact context package for upload/migration/audit.

Safety:
- Default dry-run.
- Apply requires -Apply -ConfirmText EXPORT_DEVF_CONTEXT.
- Writes only under C:\Users\aazcl\Downloads\Temp.DeveFactory.
- Does not modify repo.
- Does not push.
- Does not build.
- Does not read secrets intentionally.
#>

param(
  [switch]$Apply,
  [string]$ConfirmText = "",
  [string]$PackageName = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$MB_ID="DEVF-EXPORT-CONTEXT-V0"
$ProjectRoot="C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ModuleRoot=Join-Path $ProjectRoot "04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact"
$TempRoot="C:\Users\aazcl\Downloads\Temp.DeveFactory"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
if([string]::IsNullOrWhiteSpace($PackageName)){ $PackageName="DEVF_CONTEXT_EXPORT_$Stamp" }
$OutDir=Join-Path $TempRoot $PackageName

$FinalStatus="UNKNOWN"
$ExecutionVerdict="UNKNOWN"
$SafeToProceed="NO"
$HumanActionRequired="Review TOVS_SUMMARY"
$Blocker="NONE"
$Warnings=@()
$Findings=@()

function EnsureDir($p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteText($path,$txt){
  EnsureDir (Split-Path -Parent $path)
  $enc=New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path,$txt,$enc)
}

try{
  if(-not(Test-Path -LiteralPath $ModuleRoot)){ throw "Module root not found: $ModuleRoot" }
  if($Apply -and $ConfirmText -ne "EXPORT_DEVF_CONTEXT"){ throw "Apply requires -ConfirmText EXPORT_DEVF_CONTEXT" }

  $items=@(
    "HUMAN",
    "CONTEXT",
    "BATON",
    "REGISTERS",
    "EXECUTION\BATCH_0010.TASKS.yaml",
    "EXECUTION\BATCH_0011.TASKS.yaml",
    "EXECUTION\BATCH_0012.TASKS.yaml",
    "EXECUTION\CONTEXT_EXPORTER_CONTRACT.v0.md",
    "EXECUTION\CONTEXT_EXPORT_MANIFEST.v0.yaml",
    "VALIDATION\BATCH_0010.ACCEPTANCE.md",
    "VALIDATION\BATCH_0011.ACCEPTANCE.md",
    "VALIDATION\BATCH_0012.ACCEPTANCE.md",
    "TOOLS\DEVF.NEW_RUN.v0.ps1",
    "TOOLS\DEVF.EXPORT_CONTEXT.v0.ps1"
  )

  $planned=$items.Count
  $copied=0

  if($Apply){
    if(Test-Path -LiteralPath $OutDir){ Remove-Item -LiteralPath $OutDir -Recurse -Force }
    EnsureDir $OutDir
    foreach($item in $items){
      $src=Join-Path $ModuleRoot $item
      $dst=Join-Path $OutDir $item
      if(Test-Path -LiteralPath $src){
        EnsureDir (Split-Path -Parent $dst)
        Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
        $copied++
      }
    }

    $manifest=@"
DEVFACT_CONTEXT_EXPORT
Generated=$Stamp
ProjectRoot=$ProjectRoot
ModuleRoot=$ModuleRoot
OutDir=$OutDir
CopiedItems=$copied
NoSecretsPolicy=TRUE
NoPush=TRUE
NoBuild=TRUE
"@
    WriteText (Join-Path $OutDir "EXPORT.MANIFEST.txt") $manifest

    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="OK_TO_REVIEW"
    $SafeToProceed="YES"
    $HumanActionRequired="Review exported context package before upload or migration."
  } else {
    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="OK_TO_APPLY"
    $SafeToProceed="YES"
    $HumanActionRequired="Run with -Apply -ConfirmText EXPORT_DEVF_CONTEXT."
  }

  $Findings += "Mode: " + $(if($Apply){"APPLY"}else{"DRYRUN"})
  $Findings += "Module root: $ModuleRoot"
  $Findings += "Output dir: $OutDir"
  $Findings += "Items planned: $planned"
  $Findings += "Items copied: $copied"
}
catch{
  $FinalStatus="FAIL"
  $ExecutionVerdict="FAILED"
  $SafeToProceed="NO"
  $HumanActionRequired="Do not use exported package. Diagnose exporter failure."
  $Blocker=$_.Exception.Message
}
finally{
  Write-Host "TOVS_SUMMARY_START"
  Write-Host "AI_TAIL_SCHEMA=v1"
  Write-Host "MB_ID=$MB_ID"
  Write-Host "FINAL_STATUS=$FinalStatus"
  Write-Host "EXECUTION_VERDICT=$ExecutionVerdict"
  Write-Host "SAFE_TO_PROCEED=$SafeToProceed"
  Write-Host "HUMAN_ACTION_REQUIRED=$HumanActionRequired"
  Write-Host "BLOCKER=$Blocker"
  Write-Host "PROJECT_ROOT=$ProjectRoot"
  Write-Host "TEMP_PATH=$OutDir"
  Write-Host "TOVS_ONLY_MODE=HYBRID"
  Write-Host "MAX_PASTE_CHARS=9000"
  Write-Host "DB_MODIFIED=NO"
  Write-Host "CANON_MODIFIED=NO"
  Write-Host "COMMIT_PUSH_PERFORMED=NO"
  Write-Host "BUILD_EXECUTED=NO"
  if($Warnings.Count -eq 0){ Write-Host "WARNINGS=NONE" } else { Write-Host ("WARNINGS=" + ($Warnings -join " | ")) }
  Write-Host "KEY_FINDINGS:"
  foreach($f in $Findings){ Write-Host "* $f" }
  Write-Host "DECISIONS_NEEDED:"
  Write-Host "* Review context export before upload/migration."
  Write-Host "NEXT_ACTION=$HumanActionRequired"
  Write-Host "TOVS_SUMMARY_END"
}