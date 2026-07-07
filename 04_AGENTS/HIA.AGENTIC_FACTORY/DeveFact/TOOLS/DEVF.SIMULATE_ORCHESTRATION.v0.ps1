<#
DEVF.SIMULATE_ORCHESTRATION.v0.ps1

Safe local simulator.
No external AI calls.
No writes to repo by default except optional output under TEMP.
#>

param(
  [string]$RunId = "DEVF-SIM-RUN-0001"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$MB_ID="DEVF-SIMULATE-ORCHESTRATION-V0"
$ProjectRoot="C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ModuleRoot=Join-Path $ProjectRoot "04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact"
$TempRoot="C:\Users\aazcl\Downloads\Temp.DeveFactory"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$TempPath=Join-Path $TempRoot ("DEVF_SIMULATE_ORCHESTRATION_" + $Stamp)

$FinalStatus="UNKNOWN"
$ExecutionVerdict="UNKNOWN"
$SafeToProceed="NO"
$HumanActionRequired="Review simulator TOVS"
$Blocker="NONE"
$Warnings=@()
$Findings=@()

function EnsureDir($p){ if(-not(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function HasFile($rel){ return (Test-Path -LiteralPath (Join-Path $ModuleRoot $rel)) }

try{
  EnsureDir $TempPath
  if(-not(Test-Path -LiteralPath $ModuleRoot)){ throw "Module root missing: $ModuleRoot" }

  $required=@(
    "EXECUTION\SIMULATOR_CONTRACT.v0.md",
    "EXECUTION\SAMPLE_IDEA.v0.md",
    "EXECUTION\SAMPLE_DISCOVERY_QUESTIONS.v0.md",
    "EXECUTION\SAMPLE_TASK_PACKET.v0.yaml",
    "EXECUTION\TASK_PACKET.TEMPLATE.yaml",
    "EXECUTION\TOVS_CONTRACT.v0.md",
    "EXECUTION\BLOCKER_PACKET.TEMPLATE.yaml",
    "EXECUTION\VALIDATION_LOOP.v0.md"
  )

  $missing=@()
  foreach($rel in $required){ if(-not(HasFile $rel)){ $missing += $rel } }

  $Findings += "Run ID: $RunId"
  $Findings += "Required simulator inputs: $($required.Count)"
  $Findings += "Missing simulator inputs: $($missing.Count)"
  $Findings += "Simulated discovery status: READY_FOR_HUMAN_ANSWERS"
  $Findings += "Simulated task packet status: READY_SAMPLE_ONLY"
  $Findings += "Simulated blocker status: NONE"
  $Findings += "Simulated validation state: DRYRUN_PASS"

  if($missing.Count -gt 0){
    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="NEEDS_REVIEW"
    $SafeToProceed="NO"
    $HumanActionRequired="Resolve missing simulator inputs before using simulator."
    $Warnings += ("Missing: " + ($missing -join ", "))
  } else {
    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="OK_TO_VERIFY"
    $SafeToProceed="YES"
    $HumanActionRequired="Review simulator result; next step is BATCH-0005 verification."
  }
}
catch{
  $FinalStatus="FAIL"
  $ExecutionVerdict="FAILED"
  $SafeToProceed="NO"
  $HumanActionRequired="Diagnose simulator failure."
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
  Write-Host "TEMP_PATH=$TempPath"
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
  Write-Host "* NONE"
  Write-Host "NEXT_ACTION=$HumanActionRequired"
  Write-Host "TOVS_SUMMARY_END"
}