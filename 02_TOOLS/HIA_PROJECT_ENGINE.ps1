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
        (Join-Path $projectRoot "ARTIFACTS")
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

    Set-Content -Path (Join-Path $projectRoot "README.PROJECT.txt") -Value $readmeContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "PROJECT.CONFIG.json") -Value $configContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "HUMAN\01.0_HUMAN.PROJECT.txt") -Value $humanContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt") -Value $batonContent -Encoding UTF8
    Set-Content -Path (Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt") -Value $backlogContent -Encoding UTF8

    Write-Host ""
    Write-Host "PROJECT CREATED" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("PATH: {0}" -f $projectRoot)
    Write-Host ""
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

    $snapshot = Get-HIAProjectPortfolioSnapshot -ProjectRootPath $projectRoot -ProjectId $ProjectId
    $currentObjective = if ([string]::IsNullOrWhiteSpace([string]$snapshot.CURRENT_OBJECTIVE)) { "N/A" } else { [string]$snapshot.CURRENT_OBJECTIVE }
    $nextAction = if ([string]::IsNullOrWhiteSpace([string]$snapshot.NEXT_ACTION_BATON)) { "N/A" } else { [string]$snapshot.NEXT_ACTION_BATON }
    $nextReadyItem = if ([string]::IsNullOrWhiteSpace([string]$snapshot.NEXT_READY_ITEM)) { "N/A" } else { [string]$snapshot.NEXT_READY_ITEM }
    $lastSessionStatus = if ([string]::IsNullOrWhiteSpace([string]$snapshot.LAST_SESSION_STATUS)) { "N/A" } else { [string]$snapshot.LAST_SESSION_STATUS }
    $lastSessionId = if ([string]::IsNullOrWhiteSpace([string]$snapshot.LAST_SESSION_ID)) { "N/A" } else { [string]$snapshot.LAST_SESSION_ID }

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

    $lastActionOutput = Get-HIAProjectLastActionOutput -ProjectRootPath $projectRoot -PreferredRelativePath $safeTaskPath
    $lastActionLog = Get-HIAProjectLastActionLog -ProjectRootPath $projectRoot

    Write-Host ""
    Write-Host "PROJECT CONTINUE" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("CURRENT_OBJECTIVE: {0}" -f $currentObjective)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("NEXT_READY_ITEM: {0}" -f $nextReadyItem)
    Write-Host ("RESUME_RECOMMENDATION: {0}" -f $resumeRecommendation)
    Write-Host ("TASK_GUIDANCE: {0}" -f $taskGuidance)
    Write-Host ("SUGGESTED_COMMAND: {0}" -f $suggestedCommand)
    Write-Host ("LAST_ACTION_OUTPUT_STATUS: {0}" -f $lastActionOutput.STATUS)
    Write-Host ("LAST_ACTION_OUTPUT_PATH: {0}" -f $lastActionOutput.PATH)
    Write-Host ("LAST_ACTION_OUTPUT_PREVIEW: {0}" -f $lastActionOutput.PREVIEW)
    Write-Host ("LAST_ACTION_LOG_STATUS: {0}" -f $lastActionLog.STATUS)
    Write-Host ("LAST_ACTION_LOG_PATH: {0}" -f $lastActionLog.PATH)
    Write-Host ("LAST_ACTION_LOG_PREVIEW: {0}" -f $lastActionLog.PREVIEW)
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    $nextCommands = @(
        $suggestedCommand
        ("hia project status {0}" -f $ProjectId)
        ("hia project open {0}" -f $ProjectId)
        ("hia project session status {0}" -f $ProjectId)
    ) | Select-Object -Unique
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
    $lastActionOutput = Get-HIAProjectLastActionOutput -ProjectRootPath $projectRoot
    $lastActionLog = Get-HIAProjectLastActionLog -ProjectRootPath $projectRoot
    $hasRecentOutput = ([string]$lastActionOutput.STATUS -eq "FOUND")
    $hasRecentLog = ([string]$lastActionLog.STATUS -eq "FOUND")
    $hasRecentEvidence = ($hasRecentOutput -or $hasRecentLog)

    $reviewHandoff = "No recent action artifacts detected. Refresh project context before continuing."
    $suggestedCommand = ("hia project status {0}" -f $ProjectId)
    if ($hasRecentEvidence) {
        $reviewHandoff = "Recent project action artifacts detected. Continue operational loop safely."
        $suggestedCommand = ("hia project continue {0}" -f $ProjectId)
    }

    Write-Host ""
    Write-Host "PROJECT REVIEW" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("LAST_ACTION_OUTPUT_STATUS: {0}" -f $lastActionOutput.STATUS)
    Write-Host ("LAST_ACTION_OUTPUT_PATH: {0}" -f $lastActionOutput.PATH)
    Write-Host ("LAST_ACTION_LOG_STATUS: {0}" -f $lastActionLog.STATUS)
    Write-Host ("LAST_ACTION_LOG_PATH: {0}" -f $lastActionLog.PATH)
    Write-Host ("REVIEW_HANDOFF: {0}" -f $reviewHandoff)
    Write-Host ("SUGGESTED_COMMAND: {0}" -f $suggestedCommand)
    Write-Host ""
    Write-Host "NEXT_COMMANDS:" -ForegroundColor Yellow
    $nextCommands = @(
        $suggestedCommand
        ("hia project continue {0}" -f $ProjectId)
        ("hia project status {0}" -f $ProjectId)
        ("hia project open {0}" -f $ProjectId)
        ("hia project session status {0}" -f $ProjectId)
    ) | Select-Object -Unique
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

    $readmeStatus = if (Test-Path -LiteralPath $readmePath) { "OK" } else { "N/A" }
    $configStatus = if (Test-Path -LiteralPath $configPath) { "OK" } else { "N/A" }
    $batonStatus = if (Test-Path -LiteralPath $batonPath) { "OK" } else { "N/A" }
    $backlogStatus = if (Test-Path -LiteralPath $backlogPath) { "OK" } else { "N/A" }
    $sessionFileStatus = if (Test-Path -LiteralPath $sessionPath) { "OK" } else { "N/A" }
    $logsStatus = if (Test-Path -LiteralPath $logsPath) { "OK" } else { "N/A" }

    Write-Host ""
    Write-Host "PROJECT STATUS" -ForegroundColor Green
    Write-Host ("PROJECT_ID: {0}" -f $ProjectId)
    Write-Host ("PROJECT_ROOT: {0}" -f $projectRoot)
    Write-Host ("PROJECT_STATE: {0}" -f $projectState)
    Write-Host ("CURRENT_OBJECTIVE: {0}" -f $currentObjective)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("NEXT_READY_ITEM: {0}" -f $nextReadyItem)
    Write-Host ("LAST_SESSION_STATUS: {0}" -f $lastSessionStatus)
    Write-Host ("LAST_SESSION_ID: {0}" -f $lastSessionId)
    Write-Host ("LAST_SESSION_STARTED_UTC: {0}" -f $lastSessionStartedUtc)
    Write-Host ("LAST_SESSION_CLOSED_UTC: {0}" -f $lastSessionClosedUtc)
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
        Write-Host "MODO: STATUS (MB-2.4)"
        Write-Host ""
        $i = 1
        foreach ($proj in $projects) {
            $snapshot = $null
            try {
                $snapshot = Get-HIAProjectPortfolioSnapshot -ProjectRootPath $proj.FullName -ProjectId $proj.Name
            }
            catch {
                $snapshot = [ordered]@{
                    PROJECT_ID = $proj.Name
                    PROJECT_STATE = "N/A"
                    CURRENT_OBJECTIVE = "N/A"
                    NEXT_ACTION = "N/A"
                    LAST_SESSION_STATUS = "N/A"
                    LAST_SESSION_CLOSED_UTC = "N/A"
                }
            }

            Write-Host ("{0}. PROJECT_ID: {1}" -f $i, $snapshot.PROJECT_ID) -ForegroundColor Cyan
            Write-Host ("   PROJECT_STATE: {0}" -f $snapshot.PROJECT_STATE)
            Write-Host ("   CURRENT_OBJECTIVE: {0}" -f $snapshot.CURRENT_OBJECTIVE)
            Write-Host ("   NEXT_ACTION: {0}" -f $snapshot.NEXT_ACTION)
            Write-Host ("   LAST_SESSION_STATUS: {0}" -f $snapshot.LAST_SESSION_STATUS)
            Write-Host ("   LAST_SESSION_CLOSED_UTC: {0}" -f $snapshot.LAST_SESSION_CLOSED_UTC)
            Write-Host ""
            $i++
        }

        $firstProjectId = [string]$projects[0].Name
        Write-Host "NEXT COMMANDS:" -ForegroundColor Yellow
        Write-Host ("- hia project status {0}" -f $firstProjectId)
        Write-Host ("- hia project open {0}" -f $firstProjectId)
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
