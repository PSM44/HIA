<#
===============================================================================
MODULE: HIA_AI_PROMPT_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: PROMPT PACK RESOLVER (MB-1.6)
===============================================================================

OBJETIVO
Resolver contratos + prompt packs por herramienta + TaskType, listos para copiar.
Incluye trazabilidad mínima a 03_ARTIFACTS\LOGS\HIA_AI_PROMPTS.log
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) { return $current }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) { throw "PROJECT_ROOT not found." }
        $current = $parent
    }
}

function Get-HIAPromptPacksPath {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "00_FRAMEWORK\\HIA_RTG_0005_AI.PROMPT.PACKS.txt")
}

function Normalize-HIAToolName {
    param([string]$Tool)
    if ([string]::IsNullOrWhiteSpace($Tool)) { throw "Tool required." }
    $t = $Tool.Trim().ToUpperInvariant()
    switch ($t) {
        "CODEX" { return "CODEX" }
        "CLAUDE" { return "CLAUDE_CLOUD" }
        "CLAUDE_CLOUD" { return "CLAUDE_CLOUD" }
        "CLAUDECODE" { return "CLAUDE_CODE" }
        "CLAUDE_CODE" { return "CLAUDE_CODE" }
        "CHATGPT" { return "CHATGPT" }
        "OPENAI" { return "CHATGPT" }
        "OLLAMA" { return "OLLAMA" }
        "OPENCODE" { return "OPENCODE" }
        default { return $t }
    }
}

function Normalize-HIATaskType {
    param([string]$TaskType)
    if ([string]::IsNullOrWhiteSpace($TaskType)) { throw "TaskType required." }
    $tt = $TaskType.Trim().ToUpperInvariant()
    switch ($tt) {
        "ARCHITECTURE" { return "ARCHITECTURE" }
        "REPO_READ" { return "REPO_READ" }
        "CODE_CHANGE" { return "CODE_CHANGE" }
        "REFACTOR" { return "REFACTOR" }
        "VALIDATION" { return "VALIDATION" }
        "AUDIT" { return "AUDIT" }
        "DOCS" { return "DOCS" }
        "QUICK_LOCAL" { return "QUICK_LOCAL" }
        "FALLBACK" { return "FALLBACK" }
        "COST_SENSITIVE" { return "COST_SENSITIVE" }
        "HIGH_RISK_CHANGE" { return "HIGH_RISK_CHANGE" }
        default { return $tt }
    }
}

function Get-HIATaskContract {
    param(
        [string]$Tool,
        [string]$TaskType,
        [string]$Risk
    )

    $riskFinal = if ([string]::IsNullOrWhiteSpace($Risk)) { "MED" } else { $Risk.Trim().ToUpperInvariant() }

    $globalRestrictions = @(
        "Do not run destructive commands.",
        "Do not create commits or push automatically.",
        "Do not delete/move files; if needed, produce DELETE_PLAN_REQUERIDO with exact paths and rationale.",
        "Only one AI writes code at a time; others must review unless explicitly instructed."
    )

    if ($TaskType -eq "HIGH_RISK_CHANGE") {
        $globalRestrictions += "HIGH_RISK_CHANGE requires a second review and real validation (tests/validators/smoke)."
        $globalRestrictions += "Local models (OLLAMA/OPENCODE) cannot be the sole authority for canon in HIGH risk."
    }

    $toolNotes = @()
    switch ($Tool) {
        "CODEX" {
            $toolNotes += "Codex must not auto-commit or auto-push."
            $toolNotes += "Respect AGENTS.md and repo structure; make minimal focused changes."
        }
        "CLAUDE_CODE" {
            $toolNotes += "Claude Code should not rewrite the whole repo by default."
            $toolNotes += "Prefer small patches and explicit file lists."
        }
        "CHATGPT" {
            $toolNotes += "ChatGPT is governance/architecture/audit; do not claim validation without real tool output."
        }
        "CLAUDE_CLOUD" {
            $toolNotes += "Claude cloud is strong for long reviews and second opinions."
        }
        "OLLAMA" {
            $toolNotes += "Local model is cost_sensitive support; never canon by itself."
            $toolNotes += "If uncertain or high impact, explicitly recommend escalation to cloud."
        }
        "OPENCODE" {
            $toolNotes += "OpenCode is optional/experimental; do not present as core without evidence."
        }
    }

    $outputFormat = @(
        "SECTION: SUMMARY",
        "- (3-6 bullets)",
        "",
        "SECTION: ASSUMPTIONS",
        "- ...",
        "",
        "SECTION: RISKS",
        "- ...",
        "",
        "SECTION: VALIDATION",
        "- Exact commands to run and what to look for",
        "",
        "SECTION: NEXT_ACTIONS",
        "- ...",
        "",
        "SECTION: TRACE",
        "- What to log (session/artifacts/paths)"
    )

    $validationExpected = @()
    if ($TaskType -in @("CODE_CHANGE", "REFACTOR", "HIGH_RISK_CHANGE")) {
        $validationExpected += "Run: hia validate (and/or hia smoke) if available."
    }
    if ($TaskType -eq "VALIDATION") {
        $validationExpected += "Run tools locally and paste real output; do not invent results."
    }
    if ($validationExpected.Count -eq 0) {
        $validationExpected += "Provide concrete verification steps; if not possible, explain why."
    }

    return [ordered]@{
        tool = $Tool
        tasktype = $TaskType
        risk = $riskFinal
        objective = "Produce a reliable, verifiable result for the TaskType with HIA governance constraints."
        when_to_use = "Use when this TaskType is selected by HIA dispatch and this tool is primary/selected."
        when_not_to_use = "Do not use when it violates restrictions (high risk without review/validation, or would cause drift)."
        input_expected = "Operator-provided task prompt + relevant repo context/files. Ask for missing context explicitly."
        restrictions = $globalRestrictions
        tool_warnings = $toolNotes
        validation_expected = $validationExpected
        output_format_required = $outputFormat
        fallback_or_escalation = "If insufficient context/quality: escalate to cloud (ChatGPT/Claude cloud) or request second review."
    }
}

function Get-HIAPromptText {
    param(
        [hashtable]$Contract,
        [string]$OperatorTaskPrompt
    )

    $restr = @($Contract.restrictions | ForEach-Object { "- $_" }) -join "`n"
    $warn = @($Contract.tool_warnings | ForEach-Object { "- $_" }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($warn)) { $warn = "- (none)" }
    $val = @($Contract.validation_expected | ForEach-Object { "- $_" }) -join "`n"
    $fmt = ($Contract.output_format_required -join "`n")

    $taskPrompt = if ([string]::IsNullOrWhiteSpace($OperatorTaskPrompt)) { "<FILL: describe the task>" } else { $OperatorTaskPrompt.Trim() }

    return @"
HIA EXECUTION CONTRACT (MB-1.6)
TOOL: $($Contract.tool)
TASKTYPE: $($Contract.tasktype)
RISK: $($Contract.risk)

OBJECTIVE
$($Contract.objective)

TASK PROMPT (OPERATOR)
$taskPrompt

INPUT EXPECTED
$($Contract.input_expected)

RESTRICTIONS (NON-NEGOTIABLE)
$restr

TOOL WARNINGS
$warn

VALIDATION EXPECTED
$val

OUTPUT FORMAT (MANDATORY)
$fmt

FALLBACK / ESCALATION
$($Contract.fallback_or_escalation)
"@.Trim()
}

function Write-HIAPromptLog {
    param(
        [string]$ProjectRoot,
        [hashtable]$Result
    )

    $logDir = Join-Path $ProjectRoot "03_ARTIFACTS\\LOGS"
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $logPath = Join-Path $logDir "HIA_AI_PROMPTS.log"
    $line = "{0} | tool={1} | tasktype={2} | risk={3}" -f `
        ((Get-Date).ToUniversalTime().ToString("o")),
        $Result.tool,
        $Result.tasktype,
        $Result.risk

    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

function Invoke-HIAAiPrompt {
    param(
        [string]$Tool,
        [string]$TaskType,
        [string]$Risk = "",
        [string]$TaskPrompt = "",
        [switch]$Json
    )

    $projectRoot = Get-HIAProjectRoot
    $packsPath = Get-HIAPromptPacksPath -ProjectRoot $projectRoot

    $t = Normalize-HIAToolName -Tool $Tool
    $tt = Normalize-HIATaskType -TaskType $TaskType

    $contract = Get-HIATaskContract -Tool $t -TaskType $tt -Risk $Risk
    $promptText = Get-HIAPromptText -Contract $contract -OperatorTaskPrompt $TaskPrompt

    $result = [ordered]@{
        tool = $t
        tasktype = $tt
        risk = $contract.risk
        canonical_packs_file = $packsPath
        contract = $contract
        prompt_text = $promptText
        generated_utc = (Get-Date).ToUniversalTime().ToString("o")
    }

    Write-HIAPromptLog -ProjectRoot $projectRoot -Result $result

    if ($Json) {
        return $result
    }

    Write-Host ""
    Write-Host "HIA AI PROMPT PACK" -ForegroundColor Cyan
    Write-Host ("TOOL: {0}" -f $result.tool)
    Write-Host ("TASKTYPE: {0}" -f $result.tasktype)
    Write-Host ("RISK: {0}" -f $result.risk)
    Write-Host ("CANONICAL: {0}" -f $packsPath) -ForegroundColor DarkGray
    Write-Host ("TRACE: 03_ARTIFACTS\\LOGS\\HIA_AI_PROMPTS.log") -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "----- COPY PROMPT BELOW -----" -ForegroundColor Yellow
    Write-Host $promptText
    Write-Host "----- END PROMPT -----" -ForegroundColor Yellow
    Write-Host ""

    return $result
}

