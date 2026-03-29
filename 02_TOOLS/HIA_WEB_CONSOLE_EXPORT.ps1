<#
===============================================================================
MODULE: HIA_WEB_CONSOLE_EXPORT.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: WEB CONSOLE EXPORT

OBJETIVO
Exportar un snapshot de solo lectura para la consola web local.
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    param([string]$CandidateRoot)

    if ($CandidateRoot) {
        $resolved = (Resolve-Path -LiteralPath $CandidateRoot).Path
        if (Test-Path -LiteralPath (Join-Path $resolved "02_TOOLS")) {
            return $resolved
        }
    }

    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) {
            return $current
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }
        $current = $parent
    }
}

function Get-HIASectionText {
    param(
        [string]$Text,
        [string]$SectionName,
        [string]$NextSectionName
    )

    $lines = @($Text -split "\r?\n")
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq $SectionName) {
            $startIndex = $i
            break
        }
    }

    if ($startIndex -lt 0) {
        return $null
    }

    $cursor = $startIndex + 1
    if ($cursor -lt $lines.Count -and $lines[$cursor].Trim() -match '^[-=]{3,}$') {
        $cursor++
    }

    $collected = New-Object System.Collections.Generic.List[string]
    for ($k = $cursor; $k -lt $lines.Count; $k++) {
        $line = $lines[$k]
        $trimmed = $line.Trim()

        if ($NextSectionName -and $trimmed -eq $NextSectionName) {
            break
        }

        if ($trimmed -match '^={5,}$') {
            break
        }

        if (
            $trimmed -match '^[A-Z0-9_.]+$' -and
            ($k + 1) -lt $lines.Count -and
            $lines[$k + 1].Trim() -match '^[-=]{3,}$'
        ) {
            break
        }

        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $collected.Add($trimmed)
        }
    }

    if ($collected.Count -eq 0) {
        return $null
    }

    return ($collected -join [Environment]::NewLine).Trim()
}

function Get-HIAObjectPropertyValue {
    param(
        [object]$Object,
        [string]$PropertyName
    )

    if ($null -eq $Object) {
        return $null
    }

    $prop = $Object.PSObject.Properties[$PropertyName]
    if ($null -eq $prop) {
        return $null
    }

    return $prop.Value
}

function Get-HIAValueAsString {
    param(
        [object]$Value,
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

function Get-HIAStateData {
    param(
        [string]$LivePath,
        [System.Collections.Generic.List[string]]$Warnings
    )

    $state = [ordered]@{
        mvp_activo = "UNKNOWN"
        proximo_paso = "UNKNOWN"
        foco_actual = "UNKNOWN"
        ultimo_radar = "UNKNOWN"
        ultima_actividad = "UNKNOWN"
        generated_live = "UNKNOWN"
        minibattles = @()
    }

    if (-not (Test-Path -LiteralPath $LivePath)) {
        $Warnings.Add("PROJECT.STATE.LIVE.txt not found: $LivePath")
        return $state
    }

    $raw = Get-Content -LiteralPath $LivePath -Raw

    $generatedMatch = [regex]::Match($raw, '(?m)^GENERATED:\s*(.+)$')
    if ($generatedMatch.Success) {
        $state.generated_live = $generatedMatch.Groups[1].Value.Trim()
    }

    $foco = Get-HIASectionText -Text $raw -SectionName "FOCO_ACTUAL" -NextSectionName "MVP_ACTIVO"
    if ($foco) { $state.foco_actual = $foco }

    $mvp = Get-HIASectionText -Text $raw -SectionName "MVP_ACTIVO" -NextSectionName "MINIBATTLES_COMPLETADOS"
    if ($mvp) { $state.mvp_activo = $mvp }

    $nextStep = Get-HIASectionText -Text $raw -SectionName "PROXIMO_PASO" -NextSectionName ""
    if ($nextStep) {
        $state.proximo_paso = $nextStep
    }

    $miniText = Get-HIASectionText -Text $raw -SectionName "MINIBATTLES_COMPLETADOS" -NextSectionName "ESTADISTICAS"
    if ($miniText) {
        $miniLines = @($miniText -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\[MB-' })
        $state.minibattles = $miniLines
    }

    foreach ($line in ($raw -split "\r?\n")) {
        if ($line -match '^\s*ULTIMO_RADAR:\s*(.+)$') {
            $state.ultimo_radar = $matches[1].Trim()
        }
        elseif ($line -match '^\s*ULTIMA_ACTIVIDAD:\s*(.+)$') {
            $state.ultima_actividad = $matches[1].Trim()
        }
    }

    return $state
}

function Get-HIASessionData {
    param(
        [string]$SessionsDir,
        [System.Collections.Generic.List[string]]$Warnings
    )

    $session = [ordered]@{
        status = "none"
        session_id = "NONE"
        operator = "UNKNOWN"
        started_utc = "NONE"
        closed_utc = "NONE"
        summary_path = "NONE"
        log_path = "NONE"
        source = "none"
    }

    $activePath = Join-Path $SessionsDir "ACTIVE_SESSION.json"
    if (Test-Path -LiteralPath $activePath) {
        try {
            $active = Get-Content -LiteralPath $activePath -Raw | ConvertFrom-Json
            $activeStatus = Get-HIAObjectPropertyValue -Object $active -PropertyName "status"
            $activeId = Get-HIAObjectPropertyValue -Object $active -PropertyName "id"
            $activeSessionId = Get-HIAObjectPropertyValue -Object $active -PropertyName "session_id"
            $activeOperator = Get-HIAObjectPropertyValue -Object $active -PropertyName "operator"
            $activeStartedUtc = Get-HIAObjectPropertyValue -Object $active -PropertyName "started_utc"
            $activeClosedUtc = Get-HIAObjectPropertyValue -Object $active -PropertyName "closed_utc"

            $session.status = if ([string]::IsNullOrWhiteSpace([string]$activeStatus)) { "active" } else { [string]$activeStatus }
            $session.session_id = if ([string]::IsNullOrWhiteSpace([string]$activeId)) { [string]$activeSessionId } else { [string]$activeId }
            $session.operator = if ([string]::IsNullOrWhiteSpace([string]$activeOperator)) { "UNKNOWN" } else { [string]$activeOperator }
            $session.started_utc = Get-HIAValueAsString -Value $activeStartedUtc
            $session.closed_utc = Get-HIAValueAsString -Value $activeClosedUtc
            $session.source = "active"
            $session.summary_path = $activePath
            $logCandidate = Join-Path $SessionsDir ("{0}.log.txt" -f $session.session_id)
            if (Test-Path -LiteralPath $logCandidate) {
                $session.log_path = $logCandidate
            }
            return $session
        }
        catch {
            $Warnings.Add("ACTIVE_SESSION.json invalid JSON: $activePath")
        }
    }

    $latest = Get-ChildItem -LiteralPath $SessionsDir -Filter "SESSION_*.json" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1

    if (-not $latest) {
        $Warnings.Add("No active session and no SESSION_<id>.json found.")
        return $session
    }

    try {
        $obj = Get-Content -LiteralPath $latest.FullName -Raw | ConvertFrom-Json
        $objStatus = Get-HIAObjectPropertyValue -Object $obj -PropertyName "status"
        $objId = Get-HIAObjectPropertyValue -Object $obj -PropertyName "id"
        $objSessionId = Get-HIAObjectPropertyValue -Object $obj -PropertyName "session_id"
        $objOperator = Get-HIAObjectPropertyValue -Object $obj -PropertyName "operator"
        $objStartedUtc = Get-HIAObjectPropertyValue -Object $obj -PropertyName "started_utc"
        $objClosedUtc = Get-HIAObjectPropertyValue -Object $obj -PropertyName "closed_utc"

        $session.status = if ([string]::IsNullOrWhiteSpace([string]$objStatus)) { "closed" } else { [string]$objStatus }
        $session.session_id = if ([string]::IsNullOrWhiteSpace([string]$objId)) { [string]$objSessionId } else { [string]$objId }
        $session.operator = if ([string]::IsNullOrWhiteSpace([string]$objOperator)) { "UNKNOWN" } else { [string]$objOperator }
        $session.started_utc = Get-HIAValueAsString -Value $objStartedUtc
        $session.closed_utc = Get-HIAValueAsString -Value $objClosedUtc
        $session.summary_path = $latest.FullName
        $session.source = "latest_closed"

        $logCandidate = Join-Path $SessionsDir ("{0}.log.txt" -f $session.session_id)
        if (Test-Path -LiteralPath $logCandidate) {
            $session.log_path = $logCandidate
        }
        else {
            $Warnings.Add("Session log file not found for $($session.session_id).")
        }
    }
    catch {
        $Warnings.Add("Latest session file invalid JSON: $($latest.FullName)")
    }

    return $session
}

function Get-HIAPlanFromTxt {
    param([System.IO.FileInfo]$File)

    $lines = Get-Content -LiteralPath $File.FullName
    $id = $File.BaseName
    $status = "unknown"
    $task = "UNKNOWN"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()

        if ($line -match '^PLAN_ID:\s*(.+)$') {
            $id = $matches[1].Trim()
            continue
        }

        if ($line -eq "TASK") {
            for ($k = $i + 1; $k -lt $lines.Count; $k++) {
                $taskLine = $lines[$k].Trim()
                if (-not [string]::IsNullOrWhiteSpace($taskLine)) {
                    $task = $taskLine
                    break
                }
            }
            continue
        }

        if ($line -eq "STATUS") {
            for ($k = $i + 1; $k -lt $lines.Count; $k++) {
                $statusLine = $lines[$k].Trim()
                if (-not [string]::IsNullOrWhiteSpace($statusLine)) {
                    $status = $statusLine
                    break
                }
            }
        }
    }

    return [ordered]@{
        plan_id = $id
        status = $status
        task = $task
        updated_utc = $File.LastWriteTimeUtc.ToString("o")
        source_file = $File.Name
    }
}

function Get-HIAPlanFromJson {
    param([System.IO.FileInfo]$File)

    $obj = Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json

    $idValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "id"
    $planIdValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "plan_id"
    $statusValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "status"
    $requestValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "request"
    $taskValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "task"
    $goalValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "goal"
    $stepsValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "steps"
    $completedValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "completed_utc"
    $createdValue = Get-HIAObjectPropertyValue -Object $obj -PropertyName "created_utc"

    $id = if ($idValue) { [string]$idValue } elseif ($planIdValue) { [string]$planIdValue } else { $File.BaseName }
    $status = if ($statusValue) { [string]$statusValue } else { "unknown" }
    $task = "UNKNOWN"

    if ($requestValue) {
        $task = [string]$requestValue
    }
    elseif ($taskValue) {
        $task = [string]$taskValue
    }
    elseif ($goalValue) {
        $task = [string]$goalValue
    }
    elseif ($stepsValue -and @($stepsValue).Count -gt 0) {
        $firstStep = @($stepsValue)[0]
        if ($firstStep -is [string]) {
            $task = [string]$firstStep
        }
        elseif (Get-HIAObjectPropertyValue -Object $firstStep -PropertyName "description") {
            $task = [string](Get-HIAObjectPropertyValue -Object $firstStep -PropertyName "description")
        }
        else {
            $task = "steps available"
        }
    }

    $updatedUtc = $File.LastWriteTimeUtc.ToString("o")
    if ($completedValue) {
        $updatedUtc = Get-HIAValueAsString -Value $completedValue -Default $updatedUtc
    }
    elseif ($createdValue) {
        $updatedUtc = Get-HIAValueAsString -Value $createdValue -Default $updatedUtc
    }

    return [ordered]@{
        plan_id = $id
        status = $status
        task = $task
        updated_utc = $updatedUtc
        source_file = $File.Name
    }
}

function Get-HIAPlansData {
    param(
        [string]$PlansDir,
        [System.Collections.Generic.List[string]]$Warnings
    )

    $plans = New-Object System.Collections.Generic.List[object]

    if (-not (Test-Path -LiteralPath $PlansDir)) {
        $Warnings.Add("Plans directory not found: $PlansDir")
        return $plans
    }

    $txtFiles = Get-ChildItem -LiteralPath $PlansDir -Filter "PLAN_*.txt" -File -ErrorAction SilentlyContinue
    foreach ($file in $txtFiles) {
        try {
            $plans.Add((Get-HIAPlanFromTxt -File $file))
        }
        catch {
            $Warnings.Add("Failed to parse plan txt: $($file.Name)")
        }
    }

    $jsonFiles = Get-ChildItem -LiteralPath $PlansDir -Filter "*.json" -File -ErrorAction SilentlyContinue
    foreach ($file in $jsonFiles) {
        try {
            $plans.Add((Get-HIAPlanFromJson -File $file))
        }
        catch {
            $Warnings.Add("Failed to parse plan json: $($file.Name)")
        }
    }

    return @($plans | Sort-Object updated_utc -Descending)
}

function Get-HIAPlanSummary {
    param(
        [object[]]$Plans,
        [object]$StateData
    )

    $completed = 0
    $pending = 0
    $other = 0

    foreach ($plan in $Plans) {
        $status = [string]$plan.status
        switch ($status.ToLowerInvariant()) {
            "completed" { $completed++ }
            "done" { $completed++ }
            "executed" { $completed++ }
            "closed" { $completed++ }
            "planned" { $pending++ }
            "pending" { $pending++ }
            "approved" { $pending++ }
            "executing" { $pending++ }
            "active" { $pending++ }
            default { $other++ }
        }
    }

    $nextMini = "NONE"
    $nextLines = @([string]$StateData.proximo_paso -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -like "- *" })
    if ($nextLines.Count -gt 0) {
        $nextMini = $nextLines[0]
    }

    return [ordered]@{
        plans_total = $Plans.Count
        plans_completed = $completed
        plans_pending = $pending
        plans_other = $other
        minibattles_completed = @($StateData.minibattles).Count
        minibattle_actual = $nextMini
    }
}

function Export-HIAWebConsoleData {
    param([string]$Root)

    $warnings = New-Object System.Collections.Generic.List[string]

    $livePath = Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt"
    $sessionsDir = Join-Path $Root "03_ARTIFACTS\sessions"
    $plansDir = Join-Path $Root "03_ARTIFACTS\plans"
    $outputDir = Join-Path $Root "01_UI\web\data"
    $outputPath = Join-Path $outputDir "console-data.json"

    if (-not (Test-Path -LiteralPath $sessionsDir)) {
        $warnings.Add("Sessions directory not found: $sessionsDir")
    }

    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $stateData = Get-HIAStateData -LivePath $livePath -Warnings $warnings
    $sessionData = Get-HIASessionData -SessionsDir $sessionsDir -Warnings $warnings
    $plans = Get-HIAPlansData -PlansDir $plansDir -Warnings $warnings
    $planSummary = Get-HIAPlanSummary -Plans $plans -StateData $stateData

    $payload = [ordered]@{
        status = [ordered]@{
            project_root = $Root
            generated_live = $stateData.generated_live
            foco_actual = $stateData.foco_actual
            mvp_activo = $stateData.mvp_activo
            proximo_paso = $stateData.proximo_paso
            ultimo_radar = $stateData.ultimo_radar
            ultima_actividad = $stateData.ultima_actividad
            live_path = $livePath
        }
        session = $sessionData
        plan_summary = $planSummary
        plans = $plans
        sources = @(
            @{ label = "PROJECT.STATE.LIVE"; path = $livePath; exists = (Test-Path -LiteralPath $livePath) },
            @{ label = "Sessions"; path = $sessionsDir; exists = (Test-Path -LiteralPath $sessionsDir) },
            @{ label = "Plans"; path = $plansDir; exists = (Test-Path -LiteralPath $plansDir) }
        )
        diagnostics = [ordered]@{
            generated_utc = (Get-Date).ToUniversalTime().ToString("o")
            generator = "HIA_WEB_CONSOLE_EXPORT.ps1"
            warnings = @($warnings)
        }
    }

    $payload | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $outputPath -Encoding UTF8

    Write-Host ""
    Write-Host "HIA WEB CONSOLE EXPORT COMPLETE" -ForegroundColor Green
    Write-Host ("OUTPUT: {0}" -f $outputPath)
    Write-Host ("PLANS: {0}" -f $planSummary.plans_total)
    Write-Host ("SESSION_STATUS: {0}" -f $sessionData.status)
    Write-Host ("WARNINGS: {0}" -f $warnings.Count)
    Write-Host ""
}

$resolvedRoot = Get-HIAProjectRoot -CandidateRoot $ProjectRoot
Export-HIAWebConsoleData -Root $resolvedRoot
