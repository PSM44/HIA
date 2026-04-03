<#
===============================================================================
MODULE: HIA_PROJECT_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: PROJECT ENGINE

OBJETIVO
Listar proyectos activos y crear bootstrap minimo en 04_PROJECTS.

COMMANDS:
- Get-HIAProjects
- New-HIAProject
- Open-HIAProject
- Continue-HIAProject
- Show-HIAProjectStatus
- Start-HIAProjectSession
- Get-HIAProjectSessionStatus
- Close-HIAProjectSession
===============================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-HIAProjectRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectsRoot = Join-Path $PSScriptRoot "..\04_PROJECTS"
    if (-not (Test-Path -LiteralPath $projectsRoot)) {
        throw ("Project directory not found: {0}" -f $projectsRoot)
    }

    $projectsRoot = (Resolve-Path -LiteralPath $projectsRoot).Path
    $projectRoot = Join-Path $projectsRoot $ProjectId

    if (-not (Test-Path -LiteralPath $projectRoot)) {
        throw ("Project not found: {0}" -f $projectRoot)
    }

    return $projectRoot
}

function Get-HIAProjectSessionPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    $artifactsDir = Join-Path $projectRoot "ARTIFACTS"
    if (-not (Test-Path -LiteralPath $artifactsDir)) {
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    }

    return Join-Path $artifactsDir "SESSION.ACTIVE.json"
}

function Convert-HIAUtcValueToString {
    param(
        [Parameter(Mandatory = $false)]
        $Value,
        [Parameter(Mandatory = $false)]
        [string]$Default = "NONE"
    )

    if ($null -eq $Value) {
        return $Default
    }

    if ($Value -is [datetime]) {
        return $Value.ToUniversalTime().ToString("o")
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $Default
    }

    return $text
}

function Get-HIAFilePreview {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [int]$MaxLength = 160
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        return "N/A"
    }

    try {
        $lines = Get-Content -LiteralPath $FilePath -ErrorAction Stop
        $preview = "N/A"
        foreach ($line in $lines) {
            $text = [string]$line
            if (-not [string]::IsNullOrWhiteSpace($text)) {
                $preview = $text.Trim()
                break
            }
        }

        if ($preview.Length -gt $MaxLength) {
            $preview = ("{0}..." -f $preview.Substring(0, $MaxLength))
        }

        return $preview
    }
    catch {
        return "N/A"
    }
}

function Get-HIAProjectLastActionSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath
    )

    $result = [ordered]@{
        STATUS = "N/A"
        PATH = "N/A"
        DATA = $null
    }

    $snapshotPath = Join-Path $ProjectRootPath "ARTIFACTS\LAST.ACTION.json"
    if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) {
        return $result
    }

    try {
        $snapshotData = Get-Content -LiteralPath $snapshotPath -Raw | ConvertFrom-Json
        if ($null -eq $snapshotData) {
            return $result
        }

        $result.STATUS = "FOUND"
        $result.PATH = $snapshotPath
        $result.DATA = $snapshotData
        return $result
    }
    catch {
        return $result
    }
}

function Get-HIAProjectLastActionOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath,
        [string]$PreferredRelativePath = ""
    )

    $result = [ordered]@{
        STATUS = "N/A"
        PATH = "N/A"
        PREVIEW = "N/A"
    }

    $tasksRootPath = Join-Path $ProjectRootPath "ARTIFACTS\TASKS"
    if (-not (Test-Path -LiteralPath $tasksRootPath -PathType Container)) {
        return $result
    }

    $resolvedTasksRoot = (Resolve-Path -LiteralPath $tasksRootPath).Path
    $tasksRootPrefix = if ($resolvedTasksRoot.EndsWith("\")) { $resolvedTasksRoot } else { $resolvedTasksRoot + "\" }
    $selectedFile = $null

    $lastActionSnapshot = Get-HIAProjectLastActionSnapshot -ProjectRootPath $ProjectRootPath
    if ($lastActionSnapshot.STATUS -eq "FOUND") {
        $snapshotOutputPath = [string]$lastActionSnapshot.DATA.output_path
        if (-not [string]::IsNullOrWhiteSpace($snapshotOutputPath)) {
            $snapshotOutputFullPath = [System.IO.Path]::GetFullPath($snapshotOutputPath)
            if (
                $snapshotOutputFullPath.StartsWith($tasksRootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
                (Test-Path -LiteralPath $snapshotOutputFullPath -PathType Leaf)
            ) {
                $selectedFile = Get-Item -LiteralPath $snapshotOutputFullPath -ErrorAction SilentlyContinue
            }
        }
    }

    if ($null -eq $selectedFile -and -not [string]::IsNullOrWhiteSpace($PreferredRelativePath)) {
        $preferredFullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRootPath $PreferredRelativePath))
        if (
            $preferredFullPath.StartsWith($tasksRootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
            (Test-Path -LiteralPath $preferredFullPath -PathType Leaf)
        ) {
            $selectedFile = Get-Item -LiteralPath $preferredFullPath -ErrorAction SilentlyContinue
        }
    }

    if ($null -eq $selectedFile) {
        $selectedFile = Get-ChildItem -LiteralPath $resolvedTasksRoot -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
    }

    if ($null -eq $selectedFile) {
        return $result
    }

    $result.STATUS = "FOUND"
    $result.PATH = $selectedFile.FullName
    $result.PREVIEW = Get-HIAFilePreview -FilePath $selectedFile.FullName -MaxLength 160
    return $result
}

function Get-HIAProjectLastActionLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath
    )

    $result = [ordered]@{
        STATUS = "N/A"
        PATH = "N/A"
        PREVIEW = "N/A"
    }

    $taskLogPath = Join-Path $ProjectRootPath "ARTIFACTS\LOGS\TASK.CREATE_FILE.log"
    $logsRootPath = Join-Path $ProjectRootPath "ARTIFACTS\LOGS"
    if (Test-Path -LiteralPath $logsRootPath -PathType Container) {
        $resolvedLogsRoot = (Resolve-Path -LiteralPath $logsRootPath).Path
        $logsRootPrefix = if ($resolvedLogsRoot.EndsWith("\")) { $resolvedLogsRoot } else { $resolvedLogsRoot + "\" }
        $lastActionSnapshot = Get-HIAProjectLastActionSnapshot -ProjectRootPath $ProjectRootPath
        if ($lastActionSnapshot.STATUS -eq "FOUND") {
            $snapshotLogPath = [string]$lastActionSnapshot.DATA.log_path
            if (-not [string]::IsNullOrWhiteSpace($snapshotLogPath)) {
                $snapshotLogFullPath = [System.IO.Path]::GetFullPath($snapshotLogPath)
                if (
                    $snapshotLogFullPath.StartsWith($logsRootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
                    (Test-Path -LiteralPath $snapshotLogFullPath -PathType Leaf)
                ) {
                    $taskLogPath = $snapshotLogFullPath
                }
            }
        }
    }

    if (-not (Test-Path -LiteralPath $taskLogPath -PathType Leaf)) {
        return $result
    }

    $result.STATUS = "FOUND"
    $result.PATH = $taskLogPath
    $result.PREVIEW = Get-HIAFilePreview -FilePath $taskLogPath -MaxLength 160
    return $result
}

function Get-HIAProjectLastTaskOutcome {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath
    )

    $logPath = Join-Path $ProjectRootPath "ARTIFACTS\LOGS\TASK.CREATE_FILE.log"
    if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
        return [ordered]@{ FOUND=$false; SCOPE="TASK.CREATE_FILE"; RESULT="N/A"; REQUEST_PATH="N/A"; TARGET_PATH="N/A"; MESSAGE="N/A"; TIMESTAMP="N/A" }
    }

    try {
        $lastLine = Get-Content -LiteralPath $logPath -Tail 1
    }
    catch {
        return [ordered]@{ FOUND=$false; SCOPE="TASK.CREATE_FILE"; RESULT="N/A"; REQUEST_PATH="N/A"; TARGET_PATH="N/A"; MESSAGE="N/A"; TIMESTAMP="N/A" }
    }

    $result = [ordered]@{
        FOUND     = $true
        SCOPE     = "TASK.CREATE_FILE"
        RESULT    = "N/A"
        REQUEST_PATH  = "N/A"
        TARGET_PATH   = "N/A"
        MESSAGE   = "N/A"
        TIMESTAMP = "N/A"
    }

    if ($lastLine -match "^\s*(?<ts>[^|]+)\s*\|") {
        $result.TIMESTAMP = ($Matches['ts']).Trim()
    }
    $parts = $lastLine -split "\|"
    foreach ($p in $parts) {
        $kv = $p.Trim()
        if ($kv -like "TASK=*") { $result.SCOPE = ($kv -replace "^TASK=","").Trim() }
        elseif ($kv -like "RESULT=*") { $result.RESULT = ($kv -replace "^RESULT=","").Trim() }
        elseif ($kv -like "RELATIVE=*") { $result.REQUEST_PATH = ($kv -replace "^RELATIVE=","").Trim() }
        elseif ($kv -like "FILE=*") { $result.TARGET_PATH = ($kv -replace "^FILE=","").Trim() }
        elseif ($kv -like "MSG=*") { $result.MESSAGE = ($kv -replace "^MSG=","").Trim() }
    }

    # avoid labeling absolutes as relative target
    if ([System.IO.Path]::IsPathRooted($result.REQUEST_PATH)) {
        # keep REQUEST_PATH as-is, but do not treat as relative target
    }

    return $result
}

function Get-HIAProjectEvidenceContinuity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath
    )

    $freshnessHours = 72
    $timestampToleranceHours = 6
    $pairingToleranceHours = 6

    $lastActionSnapshot = Get-HIAProjectLastActionSnapshot -ProjectRootPath $ProjectRootPath
    $lastActionOutput = Get-HIAProjectLastActionOutput -ProjectRootPath $ProjectRootPath
    $lastActionLog = Get-HIAProjectLastActionLog -ProjectRootPath $ProjectRootPath

    $sourceTask = "N/A"
    $capturedUtc = "N/A"
    $sessionId = "N/A"
    $snapshotOutputPath = $null
    $snapshotLogPath = $null

    if ($lastActionSnapshot.STATUS -eq "FOUND" -and $lastActionSnapshot.DATA) {
        $sourceTask = if ([string]::IsNullOrWhiteSpace([string]$lastActionSnapshot.DATA.source_task)) { "N/A" } else { ([string]$lastActionSnapshot.DATA.source_task).Trim() }
        $capturedUtc = Convert-HIAUtcValueToString -Value $lastActionSnapshot.DATA.captured_utc -Default "N/A"
        if ($lastActionSnapshot.DATA.PSObject.Properties.Name -contains "session_id") {
            $sessionId = if ([string]::IsNullOrWhiteSpace([string]$lastActionSnapshot.DATA.session_id)) { "N/A" } else { [string]$lastActionSnapshot.DATA.session_id }
        }
        $snapshotOutputPath = [string]$lastActionSnapshot.DATA.output_path
        $snapshotLogPath = [string]$lastActionSnapshot.DATA.log_path
    }

    $hasMismatch = $false
    $anchorParts = New-Object System.Collections.Generic.List[string]
    $consistencyIssues = New-Object System.Collections.Generic.List[string]

    # Snapshot precedence and coherence checks
    if (-not [string]::IsNullOrWhiteSpace($snapshotOutputPath)) {
        $resolvedSnapOutput = [System.IO.Path]::GetFullPath($snapshotOutputPath) 2>$null
        if (-not (Test-Path -LiteralPath $resolvedSnapOutput -PathType Leaf)) {
            $hasMismatch = $true
        }
        elseif ($lastActionOutput.STATUS -eq "FOUND") {
            $resolvedSelectedOutput = [System.IO.Path]::GetFullPath($lastActionOutput.PATH) 2>$null
            if (-not $resolvedSelectedOutput.Equals($resolvedSnapOutput, [System.StringComparison]::OrdinalIgnoreCase)) {
                $consistencyIssues.Add("snapshot_output_differs_from_selected_output")
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($snapshotLogPath)) {
        $resolvedSnapLog = [System.IO.Path]::GetFullPath($snapshotLogPath) 2>$null
        if (-not (Test-Path -LiteralPath $resolvedSnapLog -PathType Leaf)) {
            $hasMismatch = $true
        }
        elseif ($lastActionLog.STATUS -eq "FOUND") {
            $resolvedSelectedLog = [System.IO.Path]::GetFullPath($lastActionLog.PATH) 2>$null
            if (-not $resolvedSelectedLog.Equals($resolvedSnapLog, [System.StringComparison]::OrdinalIgnoreCase)) {
                $consistencyIssues.Add("snapshot_log_differs_from_selected_log")
            }
        }
    }

    # Evidence presence
    $hasEvidence = ($lastActionSnapshot.STATUS -eq "FOUND" -or $lastActionOutput.STATUS -eq "FOUND" -or $lastActionLog.STATUS -eq "FOUND")

    # Build anchor parts
    if ($sourceTask -ne "N/A") { $anchorParts.Add(("source={0}" -f $sourceTask)) }
    if ($capturedUtc -ne "N/A") { $anchorParts.Add(("captured_utc={0}" -f $capturedUtc)) }
    if ($lastActionOutput.STATUS -eq "FOUND") { $anchorParts.Add(("output={0}" -f $lastActionOutput.PATH)) }
    if ($lastActionLog.STATUS -eq "FOUND") { $anchorParts.Add(("log={0}" -f $lastActionLog.PATH)) }
    if ($anchorParts.Count -eq 0) { $anchorParts.Add("no recent artifacts") }

    # Choose reference timestamp for freshness
    $evidenceTimestamp = $null
    if ($capturedUtc -ne "N/A") {
        try { $evidenceTimestamp = [datetime]::Parse($capturedUtc).ToUniversalTime() } catch { $evidenceTimestamp = $null }
    }
    if ($null -eq $evidenceTimestamp -and $lastActionOutput.STATUS -eq "FOUND") {
        try { $evidenceTimestamp = (Get-Item -LiteralPath $lastActionOutput.PATH).LastWriteTimeUtc } catch { $evidenceTimestamp = $null }
    }
    if ($null -eq $evidenceTimestamp -and $lastActionLog.STATUS -eq "FOUND") {
        try { $evidenceTimestamp = (Get-Item -LiteralPath $lastActionLog.PATH).LastWriteTimeUtc } catch { $evidenceTimestamp = $null }
    }

    $state = "MISSING"
    $ageHours = "N/A"

    if ($hasMismatch) {
        $state = "MISMATCH"
    }
    elseif (-not $hasEvidence) {
        $state = "MISSING"
    }
    else {
        if ($null -ne $evidenceTimestamp) {
            $ageHours = [math]::Round(((Get-Date).ToUniversalTime() - $evidenceTimestamp).TotalHours, 1)
            if ($ageHours -gt $freshnessHours) {
                $state = "STALE"
            }
            else {
                $state = "FRESH"
            }
        }
        else {
            # Evidence present but no timestamp; treat as MISMATCH for safety.
            $state = "MISMATCH"
        }
    }

    $handoff = "No recent action artifacts detected. Refresh project context before continuing."
    if ($state -eq "FRESH") {
        $handoff = ("Evidence anchor fresh ({0}). Keep operational loop conservative." -f ($anchorParts -join " | "))
    }
    elseif ($state -eq "STALE") {
        $handoff = ("Evidence anchor stale ({0}). Refresh context before continuing." -f ($anchorParts -join " | "))
    }
    elseif ($state -eq "MISMATCH") {
        $handoff = ("Evidence mismatch ({0}). Refresh context before continuing." -f ($anchorParts -join " | "))
    }

    $result = [ordered]@{
        STATE = $state
        AGE_HOURS = $ageHours
        SOURCE_TASK = $sourceTask
        CAPTURED_UTC = $capturedUtc
        SESSION_ID = $sessionId
        OUTPUT_STATUS = $lastActionOutput.STATUS
        OUTPUT_PATH = $lastActionOutput.PATH
        OUTPUT_PREVIEW = $lastActionOutput.PREVIEW
        LOG_STATUS = $lastActionLog.STATUS
        LOG_PATH = $lastActionLog.PATH
        LOG_PREVIEW = $lastActionLog.PREVIEW
        ANCHOR = ($anchorParts -join " | ")
        HANDOFF = $handoff
        CONSISTENCY = "N/A"
        CONSISTENCY_NOTES = @()
    }

    # Consistency checks only if evidence exists and not a hard mismatch
    if ($hasEvidence -and $state -in @("FRESH", "STALE")) {
        # Session consistency (only if session file exists and active)
        $sessionPath = Join-Path $ProjectRootPath "ARTIFACTS\SESSION.ACTIVE.json"
        if (Test-Path -LiteralPath $sessionPath) {
            try {
                $sessionObj = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
                $sessionStatus = [string]$sessionObj.status
                $activeSessionId = [string]$sessionObj.session_id
                if ($sourceTask -ne "N/A" -and -not [string]::IsNullOrWhiteSpace($sessionId) -and -not [string]::IsNullOrWhiteSpace($activeSessionId)) {
                    if ($sessionStatus.ToLowerInvariant() -eq "active" -and -not $sessionId.Equals($activeSessionId, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $consistencyIssues.Add("snapshot_session_differs_from_active_session")
                    }
                }
            }
            catch {
                # Ignore parsing errors to stay deterministic without failing execution
            }
        }

        # Output/Log pairing by timestamp proximity
        if ($lastActionOutput.STATUS -eq "FOUND" -and $lastActionLog.STATUS -eq "FOUND") {
            try {
                $outTime = (Get-Item -LiteralPath $lastActionOutput.PATH).LastWriteTimeUtc
                $logTime = (Get-Item -LiteralPath $lastActionLog.PATH).LastWriteTimeUtc
                $pairDiff = [math]::Abs((($outTime - $logTime).TotalHours))
                if ($pairDiff -gt $pairingToleranceHours) {
                    $consistencyIssues.Add("output_log_timestamp_divergence")
                }
            }
            catch { }
        }

        # Timestamp order sanity vs captured_utc
        if ($null -ne $evidenceTimestamp) {
            if ($lastActionOutput.STATUS -eq "FOUND") {
                try {
                    $outTime = (Get-Item -LiteralPath $lastActionOutput.PATH).LastWriteTimeUtc
                    if ([math]::Abs((($evidenceTimestamp - $outTime).TotalHours)) -gt $timestampToleranceHours) {
                        $consistencyIssues.Add("captured_vs_output_timestamp_divergence")
                    }
                }
                catch { }
            }
            if ($lastActionLog.STATUS -eq "FOUND") {
                try {
                    $logTime = (Get-Item -LiteralPath $lastActionLog.PATH).LastWriteTimeUtc
                    if ([math]::Abs((($evidenceTimestamp - $logTime).TotalHours)) -gt $timestampToleranceHours) {
                        $consistencyIssues.Add("captured_vs_log_timestamp_divergence")
                    }
                }
                catch { }
            }
        }

        # Determine consistency state
        if ($consistencyIssues.Count -gt 0) {
            $stateConsistency = "INCONSISTENT"
        }
        else {
            $stateConsistency = "CONSISTENT"
        }
        $result.CONSISTENCY = $stateConsistency
        $result.CONSISTENCY_NOTES = @($consistencyIssues)
    }
    else {
        $result.CONSISTENCY = "N/A"
        $result.CONSISTENCY_NOTES = @()
    }

    return $result
}

function Get-HIASessionSafety {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath,
        [int]$MaxActiveHours = 12
    )

    $sessionPath = Join-Path $ProjectRootPath "ARTIFACTS\SESSION.ACTIVE.json"
    $state = "N/A"
    $notes = @()
    $ageHours = "N/A"

    if (-not (Test-Path -LiteralPath $sessionPath -PathType Leaf)) {
        return [ordered]@{ STATE = $state; NOTES = $notes; AGE_HOURS = $ageHours }
    }

    try {
        $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
        $status = [string]$session.status
        $started = $session.started_utc
        if (-not [string]::IsNullOrWhiteSpace($status) -and $status.ToLowerInvariant() -eq "active") {
            $startedUtc = $null
            try {
                if ($started -is [datetime]) {
                    $startedUtc = $started.ToUniversalTime()
                }
                else {
                    $startedUtc = [datetime]::Parse($started, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
                }
            }
            catch { $startedUtc = $null }
            if ($null -ne $startedUtc) {
                $ageHours = [math]::Round(((Get-Date).ToUniversalTime() - $startedUtc).TotalHours,1)
                if ($ageHours -lt 0) { $ageHours = 0 }
                if ($ageHours -gt $MaxActiveHours) {
                    $state = "WARN"
                    $notes += ("Active session age {0}h > {1}h threshold" -f $ageHours, $MaxActiveHours)
                }
                else {
                    $state = "OK"
                }
            }
            else {
                $state = "WARN"
                $notes += "Active session has invalid start time"
            }
        }
    }
    catch {
        $state = "N/A"
        $notes = @()
    }

    return [ordered]@{
        STATE = $state
        NOTES = $notes
        AGE_HOURS = $ageHours
    }
}

function Add-HIADecisionLedgerEntry {
    param(
        $ProjectId,
        $Decision,
        $ActionText,
        $Result
    )

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    $ledgerPath = Join-Path $projectRoot "ARTIFACTS\DECISION_LEDGER.txt"

    $utcNow = (Get-Date).ToUniversalTime().ToString("o")
    $normalize = {
        param($text)
        $t = [string]$text
        if ([string]::IsNullOrWhiteSpace($t)) { return "N/A" }
        $t = $t -replace '\r','' -replace '\n',''
        $t = $t -replace '\|','/'
        return $t.Trim()
    }

    $entry = "UTC={0} | DECISION={1} | ACTION={2} | RESULT={3}" -f `
        $utcNow, `
        (& $normalize $Decision), `
        (& $normalize $ActionText), `
        (& $normalize $Result)

    $existing = @()
    if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
        try { $existing = Get-Content -LiteralPath $ledgerPath -ErrorAction Stop } catch { $existing = @() }
    }

    $all = @()
    if ($existing) { $all += $existing }
    $all += $entry
    if ($all.Count -gt 3) {
        $all = $all | Select-Object -Last 3
    }

    $ledgerDir = [System.IO.Path]::GetDirectoryName($ledgerPath)
    if (-not (Test-Path -LiteralPath $ledgerDir)) {
        New-Item -ItemType Directory -Path $ledgerDir -Force | Out-Null
    }

    $content = $all -join [Environment]::NewLine
    Set-Content -LiteralPath $ledgerPath -Value $content -Encoding UTF8
}

function Get-HIADecisionLedgerLatest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath
    )

    $ledgerPath = Join-Path $ProjectRootPath "ARTIFACTS\DECISION_LEDGER.txt"
    $decisionVal = "N/A"
    $actionVal = "N/A"
    $resultVal = "N/A"

    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return $result
    }

    try {
        $lines = Get-Content -LiteralPath $ledgerPath -ErrorAction Stop
        if ($lines.Count -eq 0) { return [pscustomobject]@{ DECISION = $decisionVal; ACTION = $actionVal; RESULT = $resultVal } }
        $latest = [string]($lines | Select-Object -Last 1)
        if ($latest -match "DECISION=([^|]+)") { $decisionVal = ($Matches[1]).Trim() }
        if ($latest -match "ACTION=([^|]+)") { $actionVal = ($Matches[1]).Trim() }
        if ($latest -match "RESULT=([^|]+)") { $resultVal = ($Matches[1]).Trim() }
    }
    catch {
        return [pscustomobject]@{ DECISION = $decisionVal; ACTION = $actionVal; RESULT = $resultVal }
    }

    return [pscustomobject]@{
        DECISION = $decisionVal
        ACTION = $actionVal
        RESULT = $resultVal
    }
}

function Test-HIAProjectConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRootPath,
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $configPath = Join-Path $ProjectRootPath "PROJECT.CONFIG.json"
    $status = "FAIL"
    $notes = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        $notes.Add("config_missing")
        return [ordered]@{ STATUS = $status; NOTES = $notes }
    }

    try {
        $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    }
    catch {
        $notes.Add("config_unreadable_json")
        return [ordered]@{ STATUS = $status; NOTES = $notes }
    }

    $projectIdField = $null
    if ($config.PSObject.Properties.Name -contains "project_id") {
        $projectIdField = [string]$config.project_id
    }
    if ([string]::IsNullOrWhiteSpace($projectIdField)) {
        $notes.Add("project_id_missing")
    }
    elseif (-not $projectIdField.Equals($ProjectId, [System.StringComparison]::OrdinalIgnoreCase)) {
        $notes.Add(("project_id_mismatch:{0}" -f $projectIdField))
    }

    $stateField = $null
    if ($config.PSObject.Properties.Name -contains "state") {
        $stateField = [string]$config.state
    }
    elseif ($config.PSObject.Properties.Name -contains "status") {
        $stateField = [string]$config.status
    }
    if ([string]::IsNullOrWhiteSpace($stateField)) {
        $notes.Add("state_missing")
    }

    if ($notes.Count -eq 0) {
        $status = "OK"
    }

    return [ordered]@{
        STATUS = $status
        NOTES = $notes
        PATH = $configPath
    }
}

function New-HIAProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectsRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\04_PROJECTS")).Path
    $projectRoot = Join-Path $projectsRoot $ProjectId

    if (Test-Path -LiteralPath $projectRoot) {
        throw ("Project already exists: {0}" -f $projectRoot)
    }

    $folders = @(
        $projectRoot,
        (Join-Path $projectRoot "HUMAN"),
        (Join-Path $projectRoot "BATON"),
        (Join-Path $projectRoot "RADAR"),
        (Join-Path $projectRoot "AGILE"),
        (Join-Path $projectRoot "ARTIFACTS"),
        (Join-Path $projectRoot "ARTIFACTS\LOGS"),
        (Join-Path $projectRoot "ARTIFACTS\TASKS")
    )

    foreach ($folder in $folders) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    $readmeContent = @"
===============================================================================
FILE: README.PROJECT.txt
PROJECT: $ProjectId
TYPE: PROJECT README
VERSION: v0.1-DRAFT
DATE: 2026-03-29
TZ: America/Santiago
OWNER: HUMAN
===============================================================================

01.00_PROPOSITO
Proyecto inicializado bajo HIA.

02.00_OBJETIVO
Definir y desarrollar este proyecto dentro del entorno HIA.

03.00_SCOPE_INICIAL
03.01 Proyecto creado.
03.02 Estructura mínima operativa creada.
03.03 Aún sin radar propio generado.
03.04 Aún sin sesión específica abierta.

04.00_COMPONENTES_DEL_PROYECTO
04.01 HUMAN
04.02 BATON
04.03 RADAR
04.04 AGILE
04.05 ARTIFACTS
"@

    $configContent = @"
{
  "project_id": "$ProjectId",
  "status": "active",
  "context_source": "project_radar",
  "has_human": true,
  "has_baton": true,
  "has_radar": true,
  "has_agile": true
}
"@

    $humanContent = @"
===============================================================================
FILE: 01.0_HUMAN.PROJECT.txt
PROJECT: $ProjectId
TYPE: HUMAN PROJECT SPIRIT
VERSION: v0.1-DRAFT
DATE: 2026-03-29
TZ: America/Santiago
OWNER: HUMAN
===============================================================================

01.00_PROPOSITO
Definir el espíritu y dirección humana del proyecto.

02.00_VISION
Proyecto inicializado bajo HIA.

03.00_CRITERIOS_DE_TRABAJO
03.01 Human-first.
03.02 IA como amplificador.
03.03 Contexto derivado desde RADAR.
03.04 Incrementos demostrables.
"@

    $batonContent = @"
===============================================================================
FILE: 04.0_PROJECT.BATON.txt
PROJECT: $ProjectId
TYPE: PROJECT BATON
VERSION: v0.1-DRAFT
DATE: 2026-03-29
TZ: America/Santiago
OWNER: HUMAN + SYSTEM
===============================================================================

01.00_PROPOSITO
Mantener continuidad operativa del proyecto.

02.00_ESTADO_ACTUAL
Proyecto recién inicializado.

03.00_OBJETIVO_ACTUAL
Definir siguiente minibattle del proyecto.
"@

    $backlogContent = "ID | TYPE | PRIORITY | TITLE | VALUE | EFFORT | STATUS`r`n"
    $sessionClosed = @{
        project_id = $ProjectId
        status = "closed"
        session_id = "N/A"
        started_utc = $null
        closed_utc = $null
    }

    Set-Content -Path (Join-Path $projectRoot "README.PROJECT.txt") -Value $readmeContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "PROJECT.CONFIG.json") -Value $configContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "HUMAN\01.0_HUMAN.PROJECT.txt") -Value $humanContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt") -Value $batonContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt") -Value $backlogContent -Encoding UTF8
    ($sessionClosed | ConvertTo-Json -Depth 3) | Set-Content -LiteralPath (Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json") -Encoding UTF8

    Write-Host ""
    Write-Host "PROJECT CREATED" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("PATH: {0}" -f $projectRoot)
    Write-Host ""
    Write-Host "STARTER STRUCTURE:" -ForegroundColor Yellow
    Write-Host ("- BATON: {0}" -f (Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"))
    Write-Host ("- BACKLOG: {0}" -f (Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"))
    Write-Host ("- SESSION_FILE: {0}" -f (Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json"))
    Write-Host ("- LOGS_DIR: {0}" -f (Join-Path $projectRoot "ARTIFACTS\LOGS"))
    Write-Host ("- TASKS_DIR: {0}" -f (Join-Path $projectRoot "ARTIFACTS\TASKS"))
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    Write-Host ("- hia project status {0}" -f $ProjectId)
    Write-Host ("- hia project review {0}" -f $ProjectId)
    Write-Host ("- hia project session status {0}" -f $ProjectId)
    Write-Host ""
}

function Remove-HIAProjectSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId,
        [switch]$ForceConfirm,
        [string]$ConfirmToken
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        $global:HIA_EXIT_CODE = 2
        throw "Usage: hia project delete <project_id> [--confirm]"
    }

    if (-not (Get-Command Resolve-HIAProjectRoot -ErrorAction SilentlyContinue)) {
        $global:HIA_EXIT_CODE = 1
        throw "Resolve-HIAProjectRoot is not available."
    }

    $projectRoot = $null
    try {
        $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    }
    catch {
        $global:HIA_EXIT_CODE = 3
        throw $_.Exception
    }

    $projectsRoot = Split-Path -Path $projectRoot -Parent
    $archiveRoot = Join-Path $projectsRoot "_ARCHIVE"
    if (-not (Test-Path -LiteralPath $archiveRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
    }

    $expected = ("DELETE {0}" -f $ProjectId)
    $envConfirm = $env:HIA_CONFIRM_DELETE
    $autoConfirm = $ForceConfirm -or (
        -not [string]::IsNullOrWhiteSpace($envConfirm) -and
        @("YES","Y","TRUE","CONFIRM") -contains $envConfirm.ToUpperInvariant()
    )

    $provided = $ConfirmToken
    if (-not $autoConfirm) {
        if ([string]::IsNullOrWhiteSpace($provided)) {
            $provided = Read-Host -Prompt ("Type '{0}' to confirm (or anything else to cancel)" -f $expected)
        }
    }

    if (-not $autoConfirm -and $provided -ne $expected) {
        Write-Host "Project delete cancelled (confirmation mismatch)." -ForegroundColor Yellow
        $global:HIA_EXIT_CODE = 1
        return $false
    }

    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    $archiveTarget = Join-Path $archiveRoot ("{0}_{1}" -f $ProjectId, $timestamp)

    try {
        Move-Item -LiteralPath $projectRoot -Destination $archiveTarget -Force
    }
    catch {
        $global:HIA_EXIT_CODE = 1
        throw $_.Exception
    }

    Write-Host ""
    Write-Host "PROJECT REMOVED (SAFE MOVE)" -ForegroundColor Yellow
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("FROM: {0}" -f $projectRoot)
    Write-Host ("TO:   {0}" -f $archiveTarget)
    Write-Host "ACTION: archive move (no permanent delete)"
    Write-Host ""

    $global:HIA_EXIT_CODE = 0
    return $true
}

function Open-HIAProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId

    $readmePath = Join-Path $projectRoot "README.PROJECT.txt"
    $readmePresent = if (Test-Path -LiteralPath $readmePath) { "YES" } else { "NO" }
    $snapshot = Get-HIAProjectPortfolioSnapshot -ProjectRootPath $projectRoot -ProjectId $ProjectId

    Write-Host ""
    Write-Host "PROJECT OPEN LANDING" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("PROJECT_ROOT: {0}" -f $projectRoot)
    Write-Host ("README_PRESENT: {0}" -f $readmePresent)
    Write-Host ("CURRENT_OBJECTIVE: {0}" -f $snapshot.CURRENT_OBJECTIVE)
    Write-Host ("NEXT_ACTION: {0}" -f $snapshot.NEXT_ACTION)
    Write-Host ("NEXT_READY_ITEM: {0}" -f $snapshot.NEXT_READY_ITEM)
    Write-Host ("LAST_SESSION_STATUS: {0}" -f $snapshot.LAST_SESSION_STATUS)
    Write-Host ("LAST_SESSION_CLOSED_UTC: {0}" -f $snapshot.LAST_SESSION_CLOSED_UTC)
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    Write-Host ("- hia project status {0}" -f $ProjectId)
    Write-Host ("- hia project continue {0}" -f $ProjectId)
    Write-Host ("- hia project session status {0}" -f $ProjectId)
    Write-Host ""
}

function Continue-HIAProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    $lastTask = Get-HIAProjectLastTaskOutcome -ProjectRootPath $projectRoot
    $configCheck = Test-HIAProjectConfig -ProjectRootPath $projectRoot -ProjectId $ProjectId

    $snapshot = Get-HIAProjectPortfolioSnapshot -ProjectRootPath $projectRoot -ProjectId $ProjectId
    $currentObjective = if ([string]::IsNullOrWhiteSpace([string]$snapshot.CURRENT_OBJECTIVE)) { "N/A" } else { [string]$snapshot.CURRENT_OBJECTIVE }
    $nextAction = if ([string]::IsNullOrWhiteSpace([string]$snapshot.NEXT_ACTION_BATON)) { "N/A" } else { [string]$snapshot.NEXT_ACTION_BATON }
    $nextReadyItem = if ([string]::IsNullOrWhiteSpace([string]$snapshot.NEXT_READY_ITEM)) { "N/A" } else { [string]$snapshot.NEXT_READY_ITEM }
    $lastSessionStatus = if ([string]::IsNullOrWhiteSpace([string]$snapshot.LAST_SESSION_STATUS)) { "N/A" } else { [string]$snapshot.LAST_SESSION_STATUS }
    $lastSessionId = if ([string]::IsNullOrWhiteSpace([string]$snapshot.LAST_SESSION_ID)) { "N/A" } else { [string]$snapshot.LAST_SESSION_ID }
    $sessionPath = Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json"
    $lastSessionStartedUtc = "N/A"
    $lastSessionClosedUtc = "N/A"
    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $sess = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
            $lastSessionStartedUtc = Convert-HIAUtcValueToString -Value $sess.started_utc -Default "N/A"
            $lastSessionClosedUtc = Convert-HIAUtcValueToString -Value $sess.closed_utc -Default "N/A"
        }
        catch {
            $lastSessionStartedUtc = "N/A"
            $lastSessionClosedUtc = "N/A"
        }
    }

    $resumeRecommendation = "N/A"
    if ($nextAction -ne "N/A") {
        $resumeRecommendation = $nextAction
    }
    elseif ($nextReadyItem -ne "N/A") {
        $resumeRecommendation = $nextReadyItem
    }

    $taskGuidance = "N/A"
    if ($lastSessionStatus -ne "active") {
        $taskGuidance = "Start project session before executing project task."
    }
    elseif ($nextAction -ne "N/A") {
        $taskGuidance = "Use NEXT_ACTION from BATON as immediate task."
    }
    elseif ($nextReadyItem -ne "N/A") {
        $taskGuidance = "Use NEXT_READY_ITEM from backlog as immediate task."
    }
    else {
        $taskGuidance = "No actionable task found; review BATON and backlog."
    }

    $hasContext = ($currentObjective -ne "N/A" -or $nextAction -ne "N/A" -or $nextReadyItem -ne "N/A")
    $safeTaskPath = "ARTIFACTS\\TASKS\\NEXT_ACTION.txt"
    if ($lastSessionId -ne "N/A") {
        $safeTaskPath = ("ARTIFACTS\\TASKS\\SESSION.{0}.NEXT_ACTION.txt" -f $lastSessionId)
    }
    $expectedOutputExists = $false
    try {
        $safeTaskPathNormalized = $safeTaskPath.Replace("\\", "\")
        $expectedOutputPath = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $safeTaskPathNormalized))
        $expectedOutputExists = Test-Path -LiteralPath $expectedOutputPath -PathType Leaf
    }
    catch {
        $expectedOutputExists = $false
    }

    $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    if ($lastSessionStatus -ne "active") {
        $suggestedCommand = ("hia project session start {0}" -f $ProjectId)
    }
    elseif ($hasContext -and -not $expectedOutputExists) {
        $suggestedCommand = ("hia task create-file-project {0} {1}" -f $ProjectId, $safeTaskPath)
    }
    elseif ($hasContext -and $expectedOutputExists) {
        $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    }
    elseif (-not $hasContext) {
        $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    }

    $evidenceContinuity = Get-HIAProjectEvidenceContinuity -ProjectRootPath $projectRoot

    $operationalThread = "NO_EVIDENCE -> Use BATON/BACKLOG + session guidance."
    if ($lastTask.RESULT -eq "rejected") {
        $operationalThread = ("LAST_TASK_REJECTED -> {0}" -f $lastTask.MESSAGE)
        $taskGuidance = "Last task was rejected. Review task log/evidence before continuing."
    }
    if ($evidenceContinuity.STATE -eq "FRESH") {
        if ($evidenceContinuity.CONSISTENCY -eq "INCONSISTENT") {
            $operationalThread = ("EVIDENCE_FRESH_INCONSISTENT -> {0}" -f $evidenceContinuity.ANCHOR)
            $taskGuidance = "Evidence inconsistent. Refresh context (status/radar/session) before executing tasks."
            $suggestedCommand = ("hia project status {0}" -f $ProjectId)
        }
        else {
            $operationalThread = ("EVIDENCE_ANCHOR[FRESH] -> {0}" -f $evidenceContinuity.ANCHOR)
            if ($lastSessionStatus -ne "active") {
                $taskGuidance = "Review evidence anchor then start session before executing next task."
                $suggestedCommand = ("hia project review {0}" -f $ProjectId)
            }
            elseif ($taskGuidance -eq "N/A" -or $taskGuidance -like "No actionable*") {
                $taskGuidance = "Anchor on last evidence before executing BATON/backlog task."
            }
        }
    }
    else {
        $operationalThread = ("EVIDENCE_{0} -> Refresh context before tasks." -f $evidenceContinuity.STATE)
        $taskGuidance = ("Evidence {0}. Refresh context (status/radar/session) before executing tasks." -f $evidenceContinuity.STATE)
        $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    }

    $sessionSafety = Get-HIASessionSafety -ProjectRootPath $projectRoot -MaxActiveHours 12
    if ($sessionSafety.STATE -eq "WARN") {
        $taskGuidance = ("Session warning: {0}. " -f (($sessionSafety.NOTES) -join "; ")) + $taskGuidance
    }

    Write-Host ""
    Write-Host "PROJECT CONTINUE" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("CURRENT_OBJECTIVE: {0}" -f $currentObjective)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("NEXT_READY_ITEM: {0}" -f $nextReadyItem)
    Write-Host ("RESUME_RECOMMENDATION: {0}" -f $resumeRecommendation)
    Write-Host ("TASK_GUIDANCE: {0}" -f $taskGuidance)
    Write-Host ("SUGGESTED_COMMAND: {0}" -f $suggestedCommand)
    Write-Host ("OPERATIONAL_THREAD: {0}" -f $operationalThread)
    Write-Host ("LAST_SESSION_STATUS: {0}" -f $lastSessionStatus)
    Write-Host ("LAST_SESSION_ID: {0}" -f $lastSessionId)
    Write-Host ("LAST_SESSION_STARTED_UTC: {0}" -f $lastSessionStartedUtc)
    Write-Host ("LAST_SESSION_CLOSED_UTC: {0}" -f $lastSessionClosedUtc)
    Write-Host ("EVIDENCE_STATE: {0}" -f $evidenceContinuity.STATE)
    Write-Host ("EVIDENCE_AGE_HOURS: {0}" -f $evidenceContinuity.AGE_HOURS)
    Write-Host ("EVIDENCE_CONSISTENCY: {0}" -f $evidenceContinuity.CONSISTENCY)
    Write-Host ("EVIDENCE_CONSISTENCY_NOTES: {0}" -f (($evidenceContinuity.CONSISTENCY_NOTES) -join ", "))
    Write-Host ("EVIDENCE_ANCHOR: {0}" -f $evidenceContinuity.ANCHOR)
    Write-Host ("EVIDENCE_CAPTURED_UTC: {0}" -f $evidenceContinuity.CAPTURED_UTC)
    Write-Host ("EVIDENCE_SESSION_ID: {0}" -f $evidenceContinuity.SESSION_ID)
    Write-Host ("LATEST_OUTPUT_PATH: {0}" -f $evidenceContinuity.OUTPUT_PATH)
    Write-Host ("LATEST_LOG_PATH: {0}" -f $evidenceContinuity.LOG_PATH)
    Write-Host ("LAST_TASK_SCOPE: {0}" -f $lastTask.SCOPE)
    Write-Host ("LAST_TASK_RESULT: {0}" -f $lastTask.RESULT)
    Write-Host ("LAST_TASK_REQUEST: {0}" -f $lastTask.REQUEST_PATH)
    Write-Host ("LAST_TASK_TARGET: {0}" -f $lastTask.TARGET_PATH)
    Write-Host ("LAST_TASK_MESSAGE: {0}" -f $lastTask.MESSAGE)
    $debugPointer = "No recent artifacts"
    if ($evidenceContinuity.OUTPUT_STATUS -eq "FOUND" -and $evidenceContinuity.LOG_STATUS -eq "FOUND") {
        $debugPointer = "Inspect log then output"
    }
    elseif ($evidenceContinuity.LOG_STATUS -eq "FOUND") {
        $debugPointer = "Inspect log first"
    }
    elseif ($evidenceContinuity.OUTPUT_STATUS -eq "FOUND") {
        $debugPointer = "Inspect output"
    }
    Write-Host ("DEBUG_POINTER: {0}" -f $debugPointer)
    Write-Host ("SESSION_SAFETY: {0}" -f $sessionSafety.STATE)
    Write-Host ("SESSION_SAFETY_NOTES: {0}" -f (($sessionSafety.NOTES) -join ", "))
    Write-Host ("SESSION_SAFETY_AGE_HOURS: {0}" -f $sessionSafety.AGE_HOURS)
    Write-Host ("PROJECT_CONFIG_STATUS: {0}" -f $configCheck.STATUS)
    Write-Host ("PROJECT_CONFIG_NOTES: {0}" -f (($configCheck.NOTES) -join ", "))
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    $nextCommands = New-Object System.Collections.Generic.List[string]
    $nextCommands.Add($suggestedCommand) | Out-Null
    if ($evidenceContinuity.STATE -eq "FRESH" -and $evidenceContinuity.CONSISTENCY -eq "CONSISTENT") {
        $nextCommands.Add(("hia project continue {0}" -f $ProjectId)) | Out-Null
    }
    $nextCommands.Add(("hia project status {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project open {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project session status {0}" -f $ProjectId)) | Out-Null
    $nextCommands = $nextCommands | Select-Object -Unique
    foreach ($cmd in $nextCommands) {
        Write-Host ("- {0}" -f $cmd)
    }
    Write-Host ""
}

function Review-HIAProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    $configCheck = Test-HIAProjectConfig -ProjectRootPath $projectRoot -ProjectId $ProjectId
    $evidenceContinuity = Get-HIAProjectEvidenceContinuity -ProjectRootPath $projectRoot
    $lastTask = Get-HIAProjectLastTaskOutcome -ProjectRootPath $projectRoot
    $sessionPath = Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json"
    $lastSessionStatus = "N/A"
    $lastSessionId = "N/A"
    $lastSessionStartedUtc = "N/A"
    $lastSessionClosedUtc = "N/A"
    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $sess = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$sess.status)) {
                $lastSessionStatus = [string]$sess.status
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$sess.session_id)) {
                $lastSessionId = [string]$sess.session_id
            }
            $lastSessionStartedUtc = Convert-HIAUtcValueToString -Value $sess.started_utc -Default "N/A"
            $lastSessionClosedUtc = Convert-HIAUtcValueToString -Value $sess.closed_utc -Default "N/A"
        }
        catch {
            $lastSessionStatus = "N/A"
            $lastSessionId = "N/A"
            $lastSessionStartedUtc = "N/A"
            $lastSessionClosedUtc = "N/A"
        }
    }

    # BATON/BACKLOG for sync hint
    $batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"
    $nextActionBaton = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
        "06.00_NEXT_ACTION","06.00_PROXIMA_ACCION","06.00_SIGUIENTE_ACCION",
        "05.00_NEXT_ACTION","05.00_PROXIMA_ACCION","05.00_SIGUIENTE_ACCION",
        "05.00_SIGUIENTE_MINIBATTLE","05.00_NEXT_MINIBATTLE"
    )
    $nextReadyBacklog = Get-HIANextReadyBacklogItem -BacklogPath $backlogPath

    $reviewHandoff = $evidenceContinuity.HANDOFF
    if ($lastTask.FOUND -and $lastTask.RESULT -eq "rejected") {
        $reviewHandoff = ("Last task rejected: {0}. " -f $lastTask.MESSAGE) + $reviewHandoff
    }
    $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    if ($evidenceContinuity.STATE -eq "FRESH" -and $evidenceContinuity.CONSISTENCY -eq "CONSISTENT") {
        $suggestedCommand = ("hia project continue {0}" -f $ProjectId)
    }

    $sessionSafety = Get-HIASessionSafety -ProjectRootPath $projectRoot -MaxActiveHours 12
    $ledgerDecision = "N/A"
    $ledgerAction = "N/A"
    $ledgerResult = "N/A"
    $ledgerPath = Join-Path $projectRoot "ARTIFACTS\DECISION_LEDGER.txt"
    if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
        try {
            $latestLedgerLine = [string](Get-Content -LiteralPath $ledgerPath -ErrorAction Stop | Select-Object -Last 1)
            if ($latestLedgerLine -match "DECISION=([^|]+)") { $ledgerDecision = ($Matches[1]).Trim() }
            if ($latestLedgerLine -match "ACTION=([^|]+)") { $ledgerAction = ($Matches[1]).Trim() }
            if ($latestLedgerLine -match "RESULT=([^|]+)") { $ledgerResult = ($Matches[1]).Trim() }
        }
        catch { }
    }

    Write-Host ""
    Write-Host "PROJECT REVIEW" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("LAST_SESSION_STATUS: {0}" -f $lastSessionStatus)
    Write-Host ("LAST_SESSION_ID: {0}" -f $lastSessionId)
    Write-Host ("LAST_SESSION_STARTED_UTC: {0}" -f $lastSessionStartedUtc)
    Write-Host ("LAST_SESSION_CLOSED_UTC: {0}" -f $lastSessionClosedUtc)
    Write-Host ("EVIDENCE_STATE: {0}" -f $evidenceContinuity.STATE)
    Write-Host ("EVIDENCE_AGE_HOURS: {0}" -f $evidenceContinuity.AGE_HOURS)
    Write-Host ("EVIDENCE_CONSISTENCY: {0}" -f $evidenceContinuity.CONSISTENCY)
    Write-Host ("EVIDENCE_CONSISTENCY_NOTES: {0}" -f (($evidenceContinuity.CONSISTENCY_NOTES) -join ", "))
    Write-Host ("EVIDENCE_ANCHOR: {0}" -f $evidenceContinuity.ANCHOR)
    Write-Host ("EVIDENCE_CAPTURED_UTC: {0}" -f $evidenceContinuity.CAPTURED_UTC)
    Write-Host ("EVIDENCE_SESSION_ID: {0}" -f $evidenceContinuity.SESSION_ID)
    Write-Host ("LATEST_OUTPUT_PATH: {0}" -f $evidenceContinuity.OUTPUT_PATH)
    Write-Host ("LATEST_LOG_PATH: {0}" -f $evidenceContinuity.LOG_PATH)
    Write-Host ("LAST_TASK_SCOPE: {0}" -f $lastTask.SCOPE)
    Write-Host ("LAST_TASK_RESULT: {0}" -f $lastTask.RESULT)
    Write-Host ("LAST_TASK_REQUEST: {0}" -f $lastTask.REQUEST_PATH)
    Write-Host ("LAST_TASK_TARGET: {0}" -f $lastTask.TARGET_PATH)
    Write-Host ("LAST_TASK_MESSAGE: {0}" -f $lastTask.MESSAGE)
    $debugPointer = "No recent artifacts"
    if ($evidenceContinuity.OUTPUT_STATUS -eq "FOUND" -and $evidenceContinuity.LOG_STATUS -eq "FOUND") {
        $debugPointer = "Inspect log then output"
    }
    elseif ($evidenceContinuity.LOG_STATUS -eq "FOUND") {
        $debugPointer = "Inspect log first"
    }
    elseif ($evidenceContinuity.OUTPUT_STATUS -eq "FOUND") {
        $debugPointer = "Inspect output"
    }
    Write-Host ("DEBUG_POINTER: {0}" -f $debugPointer)
    Write-Host ("SESSION_SAFETY: {0}" -f $sessionSafety.STATE)
    Write-Host ("SESSION_SAFETY_NOTES: {0}" -f (($sessionSafety.NOTES) -join ", "))
    Write-Host ("SESSION_SAFETY_AGE_HOURS: {0}" -f $sessionSafety.AGE_HOURS)
    Write-Host ("LEDGER_DECISION: {0}" -f $ledgerDecision)
    Write-Host ("LEDGER_ACTION: {0}" -f $ledgerAction)
    Write-Host ("LEDGER_RESULT: {0}" -f $ledgerResult)
    Write-Host ("PROJECT_CONFIG_STATUS: {0}" -f $configCheck.STATUS)
    Write-Host ("PROJECT_CONFIG_NOTES: {0}" -f (($configCheck.NOTES) -join ", "))
    $syncHint = "N/A"
    $syncNotes = "N/A"
    if ($nextActionBaton -ne "N/A" -and $nextReadyBacklog -ne "N/A") {
        $batonToken = ($nextActionBaton -split "\|")[0].Trim()
        $readyToken = ($nextReadyBacklog -split "\|")[0].Trim()
        if ([string]::IsNullOrWhiteSpace($batonToken) -or [string]::IsNullOrWhiteSpace($readyToken)) {
            $syncHint = "N/A"
            $syncNotes = "Tokens not comparable"
        }
        elseif ($batonToken.Equals($readyToken, [System.StringComparison]::OrdinalIgnoreCase)) {
            $syncHint = "OK"
            $syncNotes = "BATON and BACKLOG READY aligned"
        }
        else {
            $syncHint = "WARN"
            $syncNotes = ("BATON={0} vs READY={1}" -f $batonToken, $readyToken)
        }
    }
    Write-Host ("SYNC_HINT: {0}" -f $syncHint)
    Write-Host ("SYNC_HINT_NOTES: {0}" -f $syncNotes)
    Write-Host ("REVIEW_HANDOFF: {0}" -f $reviewHandoff)
    Write-Host ("SUGGESTED_COMMAND: {0}" -f $suggestedCommand)
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    $nextCommands = New-Object System.Collections.Generic.List[string]
    $nextCommands.Add($suggestedCommand) | Out-Null
    if ($evidenceContinuity.STATE -eq "FRESH" -and $evidenceContinuity.CONSISTENCY -eq "CONSISTENT") {
        $nextCommands.Add(("hia project continue {0}" -f $ProjectId)) | Out-Null
    }
    $nextCommands.Add(("hia project status {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project open {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project session status {0}" -f $ProjectId)) | Out-Null

    $nextCommands = $nextCommands | Select-Object -Unique
    foreach ($cmd in $nextCommands) {
        Write-Host ("- {0}" -f $cmd)
    }
    Write-Host ""
}

function Show-HIAProjectStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    if ([string]::IsNullOrWhiteSpace($ProjectId)) {
        throw "ProjectId is required."
    }

    $projectRoot = Resolve-HIAProjectRoot -ProjectId $ProjectId
    $lastTask = Get-HIAProjectLastTaskOutcome -ProjectRootPath $projectRoot

    function Find-HIABatonValue {
        param(
            [string[]]$Lines,
            [string[]]$Headers
        )

        if (-not $Lines -or $Lines.Count -eq 0) {
            return "N/A"
        }

        foreach ($header in $Headers) {
            for ($i = 0; $i -lt $Lines.Count; $i++) {
                if ($Lines[$i].Trim().ToUpperInvariant() -ne $header.Trim().ToUpperInvariant()) {
                    continue
                }

                $j = $i + 1
                while ($j -lt $Lines.Count) {
                    $candidate = $Lines[$j].Trim()
                    if ([string]::IsNullOrWhiteSpace($candidate)) {
                        $j++
                        continue
                    }

                    if ($candidate -match '^\d{2}\.\d{2}_') {
                        break
                    }

                    return $candidate
                }
            }
        }

        return "N/A"
    }

    $readmePath = Join-Path $projectRoot "README.PROJECT.txt"
    $configPath = Join-Path $projectRoot "PROJECT.CONFIG.json"
    $batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"
    $sessionPath = Join-Path $projectRoot "ARTIFACTS\SESSION.ACTIVE.json"
    $logsPath = Join-Path $projectRoot "ARTIFACTS\LOGS"

    $projectState = "N/A"
    if (Test-Path -LiteralPath $configPath) {
        try {
            $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$cfg.status)) {
                $projectState = [string]$cfg.status
            }
        }
        catch {
            $projectState = "N/A"
        }
    }

    $batonLines = @()
    if (Test-Path -LiteralPath $batonPath) {
        try {
            $batonLines = @(Get-Content -LiteralPath $batonPath)
        }
        catch {
            $batonLines = @()
        }
    }

    $currentObjective = Find-HIABatonValue -Lines $batonLines -Headers @(
        "04.00_OBJETIVO_ACTUAL",
        "04.00_CURRENT_OBJECTIVE"
    )

    $nextAction = Find-HIABatonValue -Lines $batonLines -Headers @(
        "06.00_NEXT_ACTION",
        "06.00_PROXIMA_ACCION",
        "06.00_SIGUIENTE_ACCION",
        "05.00_NEXT_ACTION",
        "05.00_PROXIMA_ACCION",
        "05.00_SIGUIENTE_ACCION"
    )

    if ($nextAction -eq "N/A") {
        $nextAction = Find-HIABatonValue -Lines $batonLines -Headers @(
            "05.00_SIGUIENTE_MINIBATTLE",
            "05.00_NEXT_MINIBATTLE"
        )
    }

    $nextReadyItem = "N/A"
    if (Test-Path -LiteralPath $backlogPath) {
        try {
            $backlogLines = Get-Content -LiteralPath $backlogPath
            foreach ($line in $backlogLines) {
                $trimmed = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
                if (-not $trimmed.Contains("|")) { continue }

                $parts = $trimmed -split '\|', 7
                $parts = @($parts | ForEach-Object { $_.Trim() })
                if ($parts.Count -ne 7) { continue }

                if (
                    $parts[0].ToUpperInvariant() -eq "ID" -and
                    $parts[1].ToUpperInvariant() -eq "TYPE" -and
                    $parts[2].ToUpperInvariant() -eq "PRIORITY"
                ) {
                    continue
                }

                if ($parts[6].ToLowerInvariant() -eq "ready") {
                    $nextReadyItem = ("{0} | {1} | {2}" -f $parts[0], $parts[3], $parts[6])
                    break
                }
            }
        }
        catch {
            $nextReadyItem = "N/A"
        }
    }

    $lastSessionStatus = "N/A"
    $lastSessionId = "N/A"
    $lastSessionStartedUtc = "N/A"
    $lastSessionClosedUtc = "N/A"

    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$session.status)) {
                $lastSessionStatus = [string]$session.status
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
                $lastSessionId = [string]$session.session_id
            }
            $lastSessionStartedUtc = Convert-HIAUtcValueToString -Value $session.started_utc -Default "N/A"
            $lastSessionClosedUtc = Convert-HIAUtcValueToString -Value $session.closed_utc -Default "N/A"
        }
        catch {
            $lastSessionStatus = "N/A"
            $lastSessionId = "N/A"
            $lastSessionStartedUtc = "N/A"
            $lastSessionClosedUtc = "N/A"
        }
    }

    # NEXT STEP SNAPSHOT (MB-2.24)
    $nextStepSnapshot = "No deterministic next step. Consider hia project review to refresh context."
    $nextStepReason = "No strong signal detected"
    $nextStepSource = "N/A"
    $evidenceContinuity = $null

    if ($nextAction -ne "N/A") {
        $nextStepSnapshot = $nextAction
        $nextStepReason = "BATON NEXT_ACTION"
        $nextStepSource = "BATON"
    }
    elseif ($nextReadyItem -ne "N/A") {
        $nextStepSnapshot = $nextReadyItem
        $nextStepReason = "BACKLOG first READY item"
        $nextStepSource = "BACKLOG"
    }
    elseif ($lastSessionStatus.ToLowerInvariant() -eq "active") {
        $nextStepSnapshot = "Session active. Continue or close the session before new work."
        $nextStepReason = "SESSION active"
        $nextStepSource = "SESSION"
    }
    else {
        try {
            $evidenceContinuity = Get-HIAProjectEvidenceContinuity -ProjectRootPath $projectRoot
            if ($evidenceContinuity.STATE -eq "FRESH") {
                $anchor = if ([string]::IsNullOrWhiteSpace([string]$evidenceContinuity.ANCHOR)) { "evidence anchor" } else { [string]$evidenceContinuity.ANCHOR }
                $nextStepSnapshot = ("Continue from evidence: {0}" -f $anchor)
                $nextStepReason = "EVIDENCE fresh"
                $nextStepSource = "EVIDENCE"
            }
        }
        catch {
            # Keep defaults if evidence continuity fails; status should remain deterministic
        }
    }

    $readmeStatus = if (Test-Path -LiteralPath $readmePath) { "OK" } else { "N/A" }
    $configCheck = Test-HIAProjectConfig -ProjectRootPath $projectRoot -ProjectId $ProjectId
    $configStatus = $configCheck.STATUS
    $batonStatus = if (Test-Path -LiteralPath $batonPath) { "OK" } else { "N/A" }
    $backlogStatus = if (Test-Path -LiteralPath $backlogPath) { "OK" } else { "N/A" }
    $sessionFileStatus = if (Test-Path -LiteralPath $sessionPath) { "OK" } else { "N/A" }
    $logsStatus = if (Test-Path -LiteralPath $logsPath) { "OK" } else { "N/A" }

    $ledgerDecision = "N/A"
    $ledgerAction = "N/A"
    $ledgerResult = "N/A"
    $ledgerPath = Join-Path $projectRoot "ARTIFACTS\DECISION_LEDGER.txt"
    if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
        try {
            $latestLedgerLine = [string](Get-Content -LiteralPath $ledgerPath -ErrorAction Stop | Select-Object -Last 1)
            if ($latestLedgerLine -match "DECISION=([^|]+)") { $ledgerDecision = ($Matches[1]).Trim() }
            if ($latestLedgerLine -match "ACTION=([^|]+)") { $ledgerAction = ($Matches[1]).Trim() }
            if ($latestLedgerLine -match "RESULT=([^|]+)") { $ledgerResult = ($Matches[1]).Trim() }
        }
        catch { }
    }

    # SYNC HINT (BATON vs BACKLOG READY)
    $syncHint = "N/A"
    $syncNotes = "N/A"
    if ($nextAction -ne "N/A" -and $nextReadyItem -ne "N/A") {
        $batonToken = ($nextAction -split "\|")[0].Trim()
        $readyToken = ($nextReadyItem -split "\|")[0].Trim()
        if ([string]::IsNullOrWhiteSpace($batonToken) -or [string]::IsNullOrWhiteSpace($readyToken)) {
            $syncHint = "N/A"
            $syncNotes = "Tokens not comparable"
        }
        elseif ($batonToken.Equals($readyToken, [System.StringComparison]::OrdinalIgnoreCase)) {
            $syncHint = "OK"
            $syncNotes = "BATON and BACKLOG READY aligned"
        }
        else {
            $syncHint = "WARN"
            $syncNotes = ("BATON={0} vs READY={1}" -f $batonToken, $readyToken)
        }
    }

    Write-Host ""
    Write-Host "PROJECT STATUS" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("PROJECT_ROOT: {0}" -f $projectRoot)
    Write-Host ("PROJECT_STATE: {0}" -f $projectState)
    Write-Host ("CURRENT_OBJECTIVE: {0}" -f $currentObjective)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("NEXT_READY_ITEM: {0}" -f $nextReadyItem)
    Write-Host ("NEXT_STEP_SNAPSHOT: {0}" -f $nextStepSnapshot)
    Write-Host ("NEXT_STEP_REASON: {0}" -f $nextStepReason)
    Write-Host ("NEXT_STEP_SOURCE: {0}" -f $nextStepSource)
    Write-Host ("LAST_SESSION_STATUS: {0}" -f $lastSessionStatus)
    Write-Host ("LAST_SESSION_ID: {0}" -f $lastSessionId)
    Write-Host ("LAST_SESSION_STARTED_UTC: {0}" -f $lastSessionStartedUtc)
    Write-Host ("LAST_SESSION_CLOSED_UTC: {0}" -f $lastSessionClosedUtc)
    Write-Host ("LAST_TASK_SCOPE: {0}" -f $lastTask.SCOPE)
    Write-Host ("LAST_TASK_RESULT: {0}" -f $lastTask.RESULT)
    Write-Host ("LAST_TASK_REQUEST: {0}" -f $lastTask.REQUEST_PATH)
    Write-Host ("LAST_TASK_TARGET: {0}" -f $lastTask.TARGET_PATH)
    Write-Host ("LAST_TASK_MESSAGE: {0}" -f $lastTask.MESSAGE)
    Write-Host ("LEDGER_DECISION: {0}" -f $ledgerDecision)
    Write-Host ("LEDGER_ACTION: {0}" -f $ledgerAction)
    Write-Host ("LEDGER_RESULT: {0}" -f $ledgerResult)
    Write-Host ("SYNC_HINT: {0}" -f $syncHint)
    Write-Host ("SYNC_HINT_NOTES: {0}" -f $syncNotes)
    Write-Host ("PROJECT_CONFIG_STATUS: {0}" -f $configStatus)
    Write-Host ("PROJECT_CONFIG_NOTES: {0}" -f (($configCheck.NOTES) -join ", "))
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    $suggestedCommand = ("hia project review {0}" -f $ProjectId)
    if ($evidenceContinuity -and $evidenceContinuity.STATE -eq "FRESH" -and $evidenceContinuity.CONSISTENCY -eq "CONSISTENT") {
        $suggestedCommand = ("hia project continue {0}" -f $ProjectId)
    }
    elseif ($lastSessionStatus.ToLowerInvariant() -eq "active") {
        $suggestedCommand = ("hia project session status {0}" -f $ProjectId)
    }
    $nextCommands = New-Object System.Collections.Generic.List[string]
    $nextCommands.Add($suggestedCommand) | Out-Null
    $nextCommands.Add(("hia project continue {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project review {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project status {0}" -f $ProjectId)) | Out-Null
    $nextCommands.Add(("hia project session status {0}" -f $ProjectId)) | Out-Null
    $nextCommands = $nextCommands | Select-Object -Unique
    foreach ($cmd in $nextCommands) {
        Write-Host ("- {0}" -f $cmd)
    }
    Write-Host ""
    Write-Host "RELEVANT_PATHS:"
    Write-Host ("BATON: {0} [{1}]" -f $batonPath, $batonStatus)
    Write-Host ("BACKLOG: {0} [{1}]" -f $backlogPath, $backlogStatus)
    Write-Host ("SESSION_FILE: {0} [{1}]" -f $sessionPath, $sessionFileStatus)
    Write-Host ("PROJECT_CONFIG: {0} [{1}]" -f $configPath, $configStatus)
    Write-Host ("README: {0} [{1}]" -f $readmePath, $readmeStatus)
    Write-Host ("ARTIFACTS_LOGS: {0} [{1}]" -f $logsPath, $logsStatus)
    Write-Host ""
}

function Start-HIAProjectSession {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $sessionPath = Get-HIAProjectSessionPath -ProjectId $ProjectId
    $sessionId = [guid]::NewGuid().ToString()
    $startedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $payload = [ordered]@{
        project_id = $ProjectId
        status = "active"
        session_id = $sessionId
        started_utc = $startedUtc
        closed_utc = $null
    }

    ($payload | ConvertTo-Json -Depth 3) | Set-Content -LiteralPath $sessionPath -Encoding UTF8

    Write-Host ""
    Write-Host "PROJECT SESSION STARTED" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("SESSION_ID: {0}" -f $sessionId)
    Write-Host ("STARTED_UTC: {0}" -f $startedUtc)
    Write-Host ("CLOSED_UTC: N/A")
    Write-Host ("SESSION_FILE: {0}" -f $sessionPath)
    Write-Host ""
}

function Get-HIAProjectSessionStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $sessionPath = Get-HIAProjectSessionPath -ProjectId $ProjectId

    $sessionStatus = "N/A"
    $sessionId = "N/A"
    $startedUtc = "N/A"
    $closedUtc = "N/A"

    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json

            if (-not [string]::IsNullOrWhiteSpace([string]$session.status)) {
                $sessionStatus = [string]$session.status
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
                $sessionId = [string]$session.session_id
            }

            $startedUtc = Convert-HIAUtcValueToString -Value $session.started_utc -Default "N/A"
            $closedUtc = Convert-HIAUtcValueToString -Value $session.closed_utc -Default "N/A"
        }
        catch {
            $sessionStatus = "N/A"
            $sessionId = "N/A"
            $startedUtc = "N/A"
            $closedUtc = "N/A"
        }
    }

    Write-Host ""
    Write-Host "PROJECT SESSION STATUS" -ForegroundColor Cyan
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("SESSION_STATUS: {0}" -f $sessionStatus)
    Write-Host ("SESSION_ID: {0}" -f $sessionId)
    Write-Host ("STARTED_UTC: {0}" -f $startedUtc)
    Write-Host ("CLOSED_UTC: {0}" -f $closedUtc)
    Write-Host ("SESSION_FILE: {0}" -f $sessionPath)
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    Write-Host ("- hia project session start {0}" -f $ProjectId)
    Write-Host ("- hia project session close {0}" -f $ProjectId)
    Write-Host ("- hia project status {0}" -f $ProjectId)
    Write-Host ""
}

function Close-HIAProjectSession {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $sessionPath = Get-HIAProjectSessionPath -ProjectId $ProjectId
    $closedUtc = (Get-Date).ToUniversalTime().ToString("o")
    $sessionId = [guid]::NewGuid().ToString()
    $startedUtc = $closedUtc
    $createdClosedSnapshot = $false

    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json

            if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
                $sessionId = [string]$session.session_id
            }
            $startedUtc = Convert-HIAUtcValueToString -Value $session.started_utc -Default $closedUtc
        }
        catch {
            $createdClosedSnapshot = $true
        }
    }
    else {
        $createdClosedSnapshot = $true
    }

    $payload = [ordered]@{
        project_id = $ProjectId
        status = "closed"
        session_id = $sessionId
        started_utc = $startedUtc
        closed_utc = $closedUtc
    }

    ($payload | ConvertTo-Json -Depth 3) | Set-Content -LiteralPath $sessionPath -Encoding UTF8

    Write-Host ""
    Write-Host "PROJECT SESSION CLOSED" -ForegroundColor Yellow
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("SESSION_ID: {0}" -f $sessionId)
    Write-Host ("STARTED_UTC: {0}" -f $startedUtc)
    Write-Host ("CLOSED_UTC: {0}" -f $closedUtc)
    Write-Host ("SESSION_FILE: {0}" -f $sessionPath)
    if ($createdClosedSnapshot) {
        Write-Host "NOTE: Session file was missing or invalid; created closed snapshot." -ForegroundColor DarkYellow
    }
    Write-Host ""
}

function Get-HIABatonValueByHeaders {
    param(
        [string]$BatonPath,
        [string[]]$Headers
    )

    if (-not (Test-Path -LiteralPath $BatonPath)) {
        return "N/A"
    }

    $lines = @()
    try {
        $lines = @(Get-Content -LiteralPath $BatonPath)
    }
    catch {
        return "N/A"
    }

    if ($lines.Count -eq 0) {
        return "N/A"
    }

    foreach ($header in $Headers) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim().ToUpperInvariant() -ne $header.Trim().ToUpperInvariant()) {
                continue
            }

            $j = $i + 1
            while ($j -lt $lines.Count) {
                $candidate = $lines[$j].Trim()
                if ([string]::IsNullOrWhiteSpace($candidate)) {
                    $j++
                    continue
                }

                if ($candidate -match '^\d{2}\.\d{2}_') {
                    break
                }

                return $candidate
            }
        }
    }

    return "N/A"
}

function Get-HIANextReadyBacklogItem {
    param([string]$BacklogPath)

    if (-not (Test-Path -LiteralPath $BacklogPath)) {
        return "N/A"
    }

    try {
        $backlogLines = Get-Content -LiteralPath $BacklogPath
        foreach ($line in $backlogLines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
            if (-not $trimmed.Contains("|")) { continue }

            $parts = $trimmed -split '\|', 7
            $parts = @($parts | ForEach-Object { $_.Trim() })
            if ($parts.Count -ne 7) { continue }

            if (
                $parts[0].ToUpperInvariant() -eq "ID" -and
                $parts[1].ToUpperInvariant() -eq "TYPE" -and
                $parts[2].ToUpperInvariant() -eq "PRIORITY"
            ) {
                continue
            }

            if ($parts[6].ToLowerInvariant() -eq "ready") {
                return ("{0} | {1} | {2}" -f $parts[0], $parts[3], $parts[6])
            }
        }
    }
    catch {
        return "N/A"
    }

    return "N/A"
}

function Get-HIAProjectPortfolioSnapshot {
    param(
        [string]$ProjectRootPath,
        [string]$ProjectId
    )

    $configPath = Join-Path $ProjectRootPath "PROJECT.CONFIG.json"
    $batonPath = Join-Path $ProjectRootPath "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $ProjectRootPath "AGILE\PROJECT.BACKLOG.txt"
    $sessionPath = Join-Path $ProjectRootPath "ARTIFACTS\SESSION.ACTIVE.json"

    $projectState = "N/A"
    if (Test-Path -LiteralPath $configPath) {
        try {
            $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$cfg.status)) {
                $projectState = [string]$cfg.status
            }
        }
        catch {
            $projectState = "N/A"
        }
    }

    $currentObjective = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
        "04.00_OBJETIVO_ACTUAL",
        "04.00_CURRENT_OBJECTIVE"
    )

    $nextActionBaton = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
        "06.00_NEXT_ACTION",
        "06.00_PROXIMA_ACCION",
        "06.00_SIGUIENTE_ACCION",
        "05.00_NEXT_ACTION",
        "05.00_PROXIMA_ACCION",
        "05.00_SIGUIENTE_ACCION",
        "05.00_SIGUIENTE_MINIBATTLE",
        "05.00_NEXT_MINIBATTLE"
    )
    $nextAction = $nextActionBaton

    $nextReadyItem = Get-HIANextReadyBacklogItem -BacklogPath $backlogPath
    if ($nextAction -eq "N/A" -and $nextReadyItem -ne "N/A") {
        $nextAction = $nextReadyItem
    }

    $lastSessionStatus = "N/A"
    $lastSessionId = "N/A"
    $lastSessionClosedUtc = "N/A"
    if (Test-Path -LiteralPath $sessionPath) {
        try {
            $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$session.status)) {
                $lastSessionStatus = [string]$session.status
            }
            if (-not [string]::IsNullOrWhiteSpace([string]$session.session_id)) {
                $lastSessionId = [string]$session.session_id
            }
            $lastSessionClosedUtc = Convert-HIAUtcValueToString -Value $session.closed_utc -Default "N/A"
        }
        catch {
            $lastSessionStatus = "N/A"
            $lastSessionId = "N/A"
            $lastSessionClosedUtc = "N/A"
        }
    }

    return [ordered]@{
        PROJECT_ID = $ProjectId
        PROJECT_STATE = $projectState
        CURRENT_OBJECTIVE = $currentObjective
        NEXT_ACTION_BATON = $nextActionBaton
        NEXT_ACTION = $nextAction
        NEXT_READY_ITEM = $nextReadyItem
        LAST_SESSION_STATUS = $lastSessionStatus
        LAST_SESSION_ID = $lastSessionId
        LAST_SESSION_CLOSED_UTC = $lastSessionClosedUtc
    }
}

function Get-HIAProjects {
    param(
        [ValidateSet("list", "status")]
        [string]$Mode = "list"
    )

    $projectsRoot = Join-Path $PSScriptRoot "..\04_PROJECTS"

    if (-not (Test-Path -LiteralPath $projectsRoot)) {
        Write-Host ""
        Write-Host ("ERROR: Project directory not found: {0}" -f $projectsRoot) -ForegroundColor Red
        Write-Host ""
        return
    }

    $projectsRoot = (Resolve-Path -LiteralPath $projectsRoot).Path
    $projects = @(Get-ChildItem -LiteralPath $projectsRoot -Directory -Force -ErrorAction Stop | Sort-Object Name)

    Write-Host ""
    Write-Host "PROYECTOS DETECTADOS" -ForegroundColor Cyan
    Write-Host "-------------------"

    if ($projects.Count -eq 0) {
        Write-Host "No projects found."
        Write-Host ""
        return
    }

    if ($Mode -eq "status") {
        function TrimPad {
            param($text, [int]$len)
            $t = [string]$text
            if ($t.Length -gt $len) { return $t.Substring(0, $len) }
            return $t.PadRight($len)
        }

        $cols = @{
            PROJECT_ID = 18
            NEXT = 24
            SESSION = 10
            EVIDENCE = 9
            SAFETY = 8
            LEDGER = 24
        }

        Write-Host ""
        Write-Host ("PROJECTS SNAPSHOT (MB-2.26)") -ForegroundColor Cyan
        $header = "{0} {1} {2} {3} {4} {5}" -f `
            (TrimPad "PROJECT_ID" $cols.PROJECT_ID),
            (TrimPad "NEXT" $cols.NEXT),
            (TrimPad "SESSION" $cols.SESSION),
            (TrimPad "EVIDENCE" $cols.EVIDENCE),
            (TrimPad "SAFETY" $cols.SAFETY),
            (TrimPad "LEDGER_DECISION" $cols.LEDGER)
        Write-Host $header
        Write-Host ("-" * ($cols.PROJECT_ID + $cols.NEXT + $cols.SESSION + $cols.EVIDENCE + $cols.SAFETY + $cols.LEDGER + 5))

        $script:suggestedPortfolioCmd = $null
        $projectIndex = New-Object System.Collections.Generic.List[object]
        $idx = 1
        foreach ($proj in $projects) {
            try {
                $root = $proj.FullName
                $batonPath = Join-Path $root "BATON\04.0_PROJECT.BATON.txt"
                $backlogPath = Join-Path $root "AGILE\PROJECT.BACKLOG.txt"
                $sessionPath = Join-Path $root "ARTIFACTS\SESSION.ACTIVE.json"

                $nextAction = Get-HIABatonValueByHeaders -BatonPath $batonPath -Headers @(
                    "06.00_NEXT_ACTION","06.00_PROXIMA_ACCION","06.00_SIGUIENTE_ACCION",
                    "05.00_NEXT_ACTION","05.00_PROXIMA_ACCION","05.00_SIGUIENTE_ACCION",
                    "05.00_SIGUIENTE_MINIBATTLE","05.00_NEXT_MINIBATTLE"
                )
                if ($nextAction -eq "N/A") {
                    $nextReady = Get-HIANextReadyBacklogItem -BacklogPath $backlogPath
                    if ($nextReady -ne "N/A") { $nextAction = $nextReady }
                }

                $sessionStatus = "N/A"
                if (Test-Path -LiteralPath $sessionPath) {
                    try {
                        $sess = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
                        if (-not [string]::IsNullOrWhiteSpace([string]$sess.status)) {
                            $sessionStatus = [string]$sess.status
                        }
                    } catch { $sessionStatus = "N/A" }
                }

                $evidence = Get-HIAProjectEvidenceContinuity -ProjectRootPath $root
                $sessionSafety = Get-HIASessionSafety -ProjectRootPath $root -MaxActiveHours 12

                $ledgerDecision = "N/A"
                $ledgerPath = Join-Path $root "ARTIFACTS\DECISION_LEDGER.txt"
                if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
                    try {
                        $latestLedgerLine = [string](Get-Content -LiteralPath $ledgerPath -ErrorAction Stop | Select-Object -Last 1)
                        if ($latestLedgerLine -match "DECISION=([^|]+)") { $ledgerDecision = ($Matches[1]).Trim() }
                    } catch { $ledgerDecision = "N/A" }
                }

                $row = "{0} {1} {2} {3} {4} {5}" -f `
                    (TrimPad ("[{0}]" -f $idx) 5),
                    (TrimPad $proj.Name $cols.PROJECT_ID),
                    (TrimPad $nextAction $cols.NEXT),
                    (TrimPad $sessionStatus $cols.SESSION),
                    (TrimPad $evidence.STATE $cols.EVIDENCE),
                    (TrimPad $sessionSafety.STATE $cols.SAFETY),
                    (TrimPad $ledgerDecision $cols.LEDGER)
                Write-Host $row
                $projectIndex.Add([ordered]@{ IDX = $idx; PROJECT_ID = $proj.Name }) | Out-Null
                $idx++

                # capture a conservative suggested command for portfolio hint
                if (-not $script:suggestedPortfolioCmd) {
                    if ($sessionStatus -eq "active") {
                        $script:suggestedPortfolioCmd = ("hia project review {0}" -f $proj.Name)
                    }
                    elseif ($evidence.STATE -eq "FRESH" -and $evidence.CONSISTENCY -eq "CONSISTENT") {
                        $script:suggestedPortfolioCmd = ("hia project continue {0}" -f $proj.Name)
                    }
                    else {
                        $script:suggestedPortfolioCmd = ("hia project status {0}" -f $proj.Name)
                    }
                }
            }
            catch {
                Write-Host (TrimPad $proj.Name $cols.PROJECT_ID) " error while reading project snapshot"
            }
        }

        Write-Host ""
        Write-Host "INDEX MAP:" -ForegroundColor Yellow
        foreach ($entry in $projectIndex) {
            Write-Host ("  {0} -> {1}" -f $entry.IDX, $entry.PROJECT_ID)
        }
        Write-Host ""
        Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
        $portfolioCmds = New-Object System.Collections.Generic.List[string]
        if ($script:suggestedPortfolioCmd) { $portfolioCmds.Add($script:suggestedPortfolioCmd) | Out-Null }
        $firstId = [string]$projects[0].Name
        $portfolioCmds.Add(("hia project status {0}" -f $firstId)) | Out-Null
        $portfolioCmds.Add(("hia project review {0}" -f $firstId)) | Out-Null
        $portfolioCmds.Add(("hia project continue {0}" -f $firstId)) | Out-Null
        $portfolioCmds = $portfolioCmds | Select-Object -Unique
        foreach ($pc in $portfolioCmds) { Write-Host ("- {0}" -f $pc) }
        Write-Host ""
        return
    }

    $i = 1
    foreach ($proj in $projects) {
        Write-Host ("{0}. {1}" -f $i, $proj.Name)
        $i++
    }

    $firstProjectId = [string]$projects[0].Name
    Write-Host ""
    Write-Host "NEXT COMMANDS:" -ForegroundColor Yellow
    Write-Host "- hia projects status"
    Write-Host ("- hia project status {0}" -f $firstProjectId)
    Write-Host ("- hia project open {0}" -f $firstProjectId)
    Write-Host ""
}
