<#
DEVF.NEW_RUN.v1.ps1

Creates a controlled DeveFact run folder from a raw idea.

Improvements over v0:
- Side-by-side version; v0 is not overwritten.
- Optional -IntakeFile support.
- Duplicate run protection.
- -OverwriteExisting requires explicit confirmation.
- Emits clearer TOVS fields.
- Writes only under EXECUTION\RUNS\<RunId>.
- No external AI calls.
- No DB modification.
- No commit/push/build.
#>

param(
  [string]$RunId = "",
  [string]$Idea = "",
  [string]$IntakeFile = "",
  [string]$FirstUser = "Pablo / Control Tower operator",
  [switch]$Apply,
  [switch]$OverwriteExisting,
  [string]$ConfirmText = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$MB_ID="DEVF-NEW-RUN-v1"
$ProjectRoot="C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ModuleRoot=Join-Path $ProjectRoot "04_AGENTS\HIA.AGENTIC_FACTORY\DeveFact"
$TempRoot="C:\Users\aazcl\Downloads\Temp.DeveFactory"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$TempPath=Join-Path $TempRoot ("DEVF_NEW_RUN_V1_" + $Stamp)

$FinalStatus="UNKNOWN"
$ExecutionVerdict="UNKNOWN"
$SafeToProceed="NO"
$HumanActionRequired="Review TOVS_SUMMARY"
$Blocker="NONE"
$Warnings=@()
$Findings=@()

function EnsureDir($p){
  if(-not(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteText($path,$txt){
  EnsureDir (Split-Path -Parent $path)
  $enc=New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path,$txt,$enc)
}

try{
  EnsureDir $TempPath
  if(-not(Test-Path -LiteralPath $ModuleRoot)){
    throw "Module root not found: $ModuleRoot"
  }

  if([string]::IsNullOrWhiteSpace($RunId)){
    $RunId="DEVF-RUN-" + (Get-Date -Format "yyyyMMdd-HHmmss")
  }

  if(-not [string]::IsNullOrWhiteSpace($IntakeFile)){
    if(-not(Test-Path -LiteralPath $IntakeFile)){
      throw "IntakeFile not found: $IntakeFile"
    }
    $Idea=(Get-Content -LiteralPath $IntakeFile -Raw -Encoding UTF8).Trim()
  }

  if([string]::IsNullOrWhiteSpace($Idea)){
    throw "Idea is required either via -Idea or -IntakeFile."
  }

  $RunRoot=Join-Path $ModuleRoot ("EXECUTION\RUNS\" + $RunId)
  $exists=Test-Path -LiteralPath $RunRoot

  if($exists -and -not $OverwriteExisting){
    throw "Run already exists. Use -OverwriteExisting only if intentional: $RunRoot"
  }

  if($Apply){
    if($ConfirmText -ne "CREATE_DEVF_RUN"){
      throw "Apply requires -ConfirmText CREATE_DEVF_RUN"
    }

    if($exists -and $OverwriteExisting){
      Remove-Item -LiteralPath $RunRoot -Recurse -Force
    }

    EnsureDir $RunRoot

    $intake = @"
==========
RUN.INTAKE
==========
RUN_ID: $RunId
STATUS: GENERATED_BY_DEVF_NEW_RUN_V1
FIRST_USER: $FirstUser

RAW_HUMAN_IDEA:
$Idea
"@
    WriteText (Join-Path $RunRoot "RUN.INTAKE.md") $intake

    $questions = @"
==========
RUN.DISCOVERY_QUESTIONS
==========
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
    WriteText (Join-Path $RunRoot "RUN.DISCOVERY_QUESTIONS.md") $questions

    $orchestratorStub = @"
==========
RUN.ORCHESTRATOR_STUB
==========
STATUS: GENERATED_STUB
NEXT_ACTION:
Answer RUN.DISCOVERY_QUESTIONS.md, then create RUN.ORCHESTRATOR_OUTPUT.md.
"@
    WriteText (Join-Path $RunRoot "RUN.ORCHESTRATOR_STUB.md") $orchestratorStub

    $packetStub = @"
packet_id: GENERATED_STUB
status: NEEDS_ORCHESTRATOR_OUTPUT
expected_tovs:
  execution_verdict: OK_TO_REVIEW
  safe_to_proceed: YES
policy:
  no_push: true
  no_build: true
  no_db_modification: true
"@
    WriteText (Join-Path $RunRoot "RUN.EXECUTOR_TASK_PACKET.STUB.yaml") $packetStub

    $expectedTovs = @"
TOVS_SUMMARY_START
AI_TAIL_SCHEMA=v1
EXECUTION_VERDICT=OK_TO_REVIEW
SAFE_TO_PROCEED=YES
DB_MODIFIED=NO
COMMIT_PUSH_PERFORMED=NO
BUILD_EXECUTED=NO
TOVS_SUMMARY_END
"@
    WriteText (Join-Path $RunRoot "RUN.TOVS.EXPECTED.txt") $expectedTovs

    $validation = @"
==========
RUN.VALIDATION
==========
STATUS: GENERATED_PENDING_REVIEW
No DB modification.
No push.
No build.
"@
    WriteText (Join-Path $RunRoot "RUN.VALIDATION.md") $validation
  }

  $FinalStatus="PASS_WITH_REVIEW"
  if($Apply){
    $ExecutionVerdict="OK_TO_REVIEW"
    $SafeToProceed="YES"
    $HumanActionRequired="Review generated run and answer discovery questions."
  } else {
    $ExecutionVerdict="OK_TO_APPLY"
    $SafeToProceed="YES"
    $HumanActionRequired="Run with -Apply -ConfirmText CREATE_DEVF_RUN."
  }

  $Findings += "Mode: " + $(if($Apply){"APPLY"}else{"DRYRUN"})
  $Findings += "RunId: $RunId"
  $Findings += "RunRoot: $RunRoot"
  $Findings += "Run existed before: $exists"
  $Findings += "OverwriteExisting: $OverwriteExisting"
  $Findings += "Idea length: $($Idea.Length)"
}
catch{
  $FinalStatus="FAIL"
  $ExecutionVerdict="FAILED"
  $SafeToProceed="NO"
  $HumanActionRequired="Do not apply. Diagnose generator failure."
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
  Write-Host "PUSH_PERFORMED=NO"
  Write-Host "BUILD_EXECUTED=NO"
  if($Warnings.Count -eq 0){ Write-Host "WARNINGS=NONE" } else { Write-Host ("WARNINGS=" + ($Warnings -join " | ")) }
  Write-Host "KEY_FINDINGS:"
  foreach($f in $Findings){ Write-Host "* $f" }
  Write-Host "DECISIONS_NEEDED:"
  Write-Host "* Review generated run before orchestration."
  Write-Host "NEXT_ACTION=$HumanActionRequired"
  Write-Host "TOVS_SUMMARY_END"
}
