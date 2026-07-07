<#
DEVF.NEW_RUN.v0.ps1

Creates a new local DeveFact run folder from a raw idea.
No external AI calls. No DB. No Git. No build. No push.

Default DRYRUN.
Apply requires -Apply -ConfirmText CREATE_DEVF_RUN.
#>

param(
  [string]$RunId = "",
  [string]$Idea = "",
  [string]$FirstUser = "Pablo",
  [switch]$Apply,
  [string]$ConfirmText = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$MB_ID="DEVF-NEW-RUN-V0"
$ProjectRoot="C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ModuleRoot=Join-Path $ProjectRoot "04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact"
$TempRoot="C:\Users\aazcl\Downloads\Temp.DeveFactory"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$TempPath=Join-Path $TempRoot ("DEVF_NEW_RUN_" + $Stamp)

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
  EnsureDir $TempPath
  if(-not(Test-Path -LiteralPath $ModuleRoot)){ throw "Module root missing: $ModuleRoot" }

  if([string]::IsNullOrWhiteSpace($RunId)){ $RunId="DEVF-RUN-" + (Get-Date -Format "yyyyMMdd-HHmm") }
  if([string]::IsNullOrWhiteSpace($Idea)){ $Idea="PLACEHOLDER_IDEA_REQUIRES_HUMAN_INPUT" }

  if($RunId -notmatch '^DEVF-(SIM-)?RUN-[A-Za-z0-9\-]+$'){
    throw "Invalid RunId format: $RunId"
  }

  $runRoot=Join-Path $ModuleRoot ("EXECUTION\RUNS\" + $RunId)
  $files=@{}

  $files["RUN.INTAKE.md"] = @"
==========
RUN.INTAKE
==========
RUN_ID: $RunId
STATUS: GENERATED_STUB

RAW_HUMAN_IDEA:
$Idea

FIRST_USER:
$FirstUser

OUTPUT_TYPE:
DELIVERABLE_DONE

NO_SCOPE:
- No UI unless explicitly approved.
- No API unless explicitly approved.
- No deploy.
- No external AI call.
- No DB changes.
- No push.
"@

  $files["RUN.DISCOVERY_QUESTIONS.md"] = @"
==========
RUN.DISCOVERY_QUESTIONS
==========
RUN_ID: $RunId
STATUS: GENERATED_STUB

Q001. What problem should this solve in one sentence?
Q002. Who is the first user?
Q003. What input will the user provide?
Q004. What output should be produced first?
Q005. What is explicitly out of scope?
Q006. What can the executor modify?
Q007. What must the executor never modify?
Q008. What validation proves acceptance?
Q009. What should happen if blocked?
Q010. Should the first pilot be documentation-only, script-assisted, or UI-based?
"@

  $files["RUN.ORCHESTRATOR_STUB.md"] = @"
==========
RUN.ORCHESTRATOR_STUB
==========
RUN_ID: $RunId
STATUS: GENERATED_STUB

This file must be completed after human answers discovery questions.
"@

  $files["RUN.EXECUTOR_TASK_PACKET.STUB.yaml"] = @"
packet_id: "$RunId-PACKET-STUB"
run_id: "$RunId"
status: "GENERATED_STUB"
expected_tovs:
  final_status: "PASS_WITH_REVIEW"
  execution_verdict: "OK_TO_VERIFY"
  safe_to_proceed: "YES"
"@

  $files["RUN.TOVS.EXPECTED.txt"] = @"
TOVS_SUMMARY_START
AI_TAIL_SCHEMA=v1
MB_ID=DEVF-NEW-RUN-V0
FINAL_STATUS=PASS_WITH_REVIEW
EXECUTION_VERDICT=OK_TO_REVIEW
SAFE_TO_PROCEED=YES
HUMAN_ACTION_REQUIRED=Review generated run stub and answer discovery questions.
BLOCKER=NONE
PROJECT_ROOT=$ProjectRoot
TEMP_PATH=<dynamic>
TOVS_ONLY_MODE=HYBRID
MAX_PASTE_CHARS=9000
DB_MODIFIED=NO
CANON_MODIFIED=DOCS_ONLY
COMMIT_PUSH_PERFORMED=NO
BUILD_EXECUTED=NO
WARNINGS=NONE
KEY_FINDINGS:
* Run ID: $RunId
DECISIONS_NEEDED:
* Answer discovery questions before task execution.
NEXT_ACTION=Review generated run stub and answer discovery questions.
TOVS_SUMMARY_END
"@

  if($Apply -and $ConfirmText -ne "CREATE_DEVF_RUN"){
    throw "Apply requires -ConfirmText CREATE_DEVF_RUN"
  }

  if($Apply){
    if(Test-Path -LiteralPath $runRoot){ throw "Run folder already exists: $runRoot" }
    EnsureDir $runRoot
    foreach($name in $files.Keys){
      WriteText (Join-Path $runRoot $name) $files[$name]
    }
    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="OK_TO_REVIEW"
    $SafeToProceed="YES"
    $HumanActionRequired="Review generated run stub and answer discovery questions."
  } else {
    $FinalStatus="PASS_WITH_REVIEW"
    $ExecutionVerdict="OK_TO_APPLY"
    $SafeToProceed="YES"
    $HumanActionRequired="Run with -Apply -ConfirmText CREATE_DEVF_RUN to create the run folder."
  }

  $Findings += "Run ID: $RunId"
  $Findings += "Idea length: $($Idea.Length)"
  $Findings += "Run root: $runRoot"
  $Findings += "Files planned: $($files.Keys.Count)"
  $Findings += "Applied: $($Apply.IsPresent)"
}
catch{
  $FinalStatus="FAIL"
  $ExecutionVerdict="FAILED"
  $SafeToProceed="NO"
  $HumanActionRequired="Do not proceed. Diagnose new run failure."
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
  Write-Host ("CANON_MODIFIED=" + $(if($Apply){"DOCS_ONLY"}else{"NO"}))
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