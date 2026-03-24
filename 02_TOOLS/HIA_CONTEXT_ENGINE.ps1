<#
===============================================================================
MODULE: HIA_CONTEXT_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: CONTEXT ENGINE

OBJETIVO
Construir un paquete de contexto operativo derivado desde fuentes reales.

COMMANDS:
- build: genera package + manifest + snapshot historico
- show: muestra package activo actual

VERSION: v0.1
DATE: 2026-03-24
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("build", "show")]
    [string]$Command = "build",

    [Parameter(Mandatory = $false)]
    [string]$TaskType = "general",

    [Parameter(Mandatory = $false)]
    [string]$TargetKind = "router",

    [Parameter(Mandatory = $false)]
    [ValidateSet("L0", "L1", "L2", "L3")]
    [string]$ContextLevel = "L1",

    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    param([string]$CandidateRoot)

    if ($CandidateRoot) {
        $resolved = (Resolve-Path $CandidateRoot).Path
        if (Test-Path (Join-Path $resolved "02_TOOLS")) {
            return $resolved
        }
    }

    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path (Join-Path $current "02_TOOLS")) {
            return $current
        }

        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }

        $current = $parent
    }
}

function Get-HIAContextPaths {
    param([string]$Root)

    $contextDir = Join-Path $Root "03_ARTIFACTS\context"
    $historyDir = Join-Path $contextDir "history"

    return @{
        ContextDir = $contextDir
        HistoryDir = $historyDir
        PackagePath = Join-Path $contextDir "CONTEXT.PACKAGE.ACTIVE.json"
        ManifestPath = Join-Path $contextDir "CONTEXT.MANIFEST.ACTIVE.txt"
        LiveStatePath = Join-Path $Root "01_UI\terminal\PROJECT.STATE.LIVE.txt"
        ActiveSessionPath = Join-Path $Root "03_ARTIFACTS\sessions\SESSION.ACTIVE.json"
        BatonCandidatePaths = @(
            (Join-Path $Root "HUMAN.README\04.0_HUMAN.BATON.txt"),
            (Join-Path $Root "HUMAN.BATON\04.0_HUMAN.BATON.txt"),
            (Join-Path $Root "HUMAN.BATON\HUMAN.BATON.txt")
        )
        RadarIndexPath = Join-Path $Root "03_ARTIFACTS\RADAR\Radar.Index.ACTIVE.txt"
    }
}

function Get-HIASectionValue {
    param(
        [string]$RawContent,
        [string]$SectionName,
        [string]$NextSectionName
    )

    $pattern = '(?ms)' + [regex]::Escape($SectionName) + '\s*-+\s*(.*?)\s*' + [regex]::Escape($NextSectionName)
    $match = [regex]::Match($RawContent, $pattern)
    if ($match.Success) {
        $value = ($match.Groups[1].Value -replace '\s+$', '').Trim()
        if ($value) {
            return $value
        }
    }

    return "UNKNOWN"
}

function Read-HIALiveState {
    param([string]$LiveStatePath)

    $snapshot = [ordered]@{
        path = $LiveStatePath
        exists = $false
        generated = "UNKNOWN"
        focus_actual = "UNKNOWN"
        mvp_activo = "UNKNOWN"
    }

    if (-not (Test-Path $LiveStatePath)) {
        return $snapshot
    }

    $snapshot.exists = $true
    $raw = Get-Content -Path $LiveStatePath -Raw

    $generatedMatch = [regex]::Match($raw, '(?m)^GENERATED:\s*(.+)$')
    if ($generatedMatch.Success) {
        $snapshot.generated = $generatedMatch.Groups[1].Value.Trim()
    }

    $snapshot.focus_actual = Get-HIASectionValue -RawContent $raw -SectionName "FOCO_ACTUAL" -NextSectionName "MVP_ACTIVO"
    $snapshot.mvp_activo = Get-HIASectionValue -RawContent $raw -SectionName "MVP_ACTIVO" -NextSectionName "MINIBATTLES_COMPLETADOS"

    return $snapshot
}

function Read-HIAActiveSession {
    param([string]$SessionPath)

    if (-not (Test-Path $SessionPath)) {
        return $null
    }

    try {
        $session = Get-Content -Path $SessionPath -Raw | ConvertFrom-Json
        return [ordered]@{
            id = if ($session.id) { [string]$session.id } else { "UNKNOWN" }
            status = if ($session.status) { [string]$session.status } else { "UNKNOWN" }
            operator = if ($session.operator) { [string]$session.operator } else { "UNKNOWN" }
            started_at = if ($session.started_at) { [string]$session.started_at } else { "UNKNOWN" }
            started_utc = if ($session.started_utc) { [string]$session.started_utc } else { "UNKNOWN" }
            logs_count = @($session.logs).Count
            path = $SessionPath
        }
    }
    catch {
        return [ordered]@{
            id = "UNKNOWN"
            status = "INVALID_JSON"
            operator = "UNKNOWN"
            started_at = "UNKNOWN"
            started_utc = "UNKNOWN"
            logs_count = 0
            path = $SessionPath
        }
    }
}

function Read-HIABaton {
    param([string[]]$CandidatePaths)

    foreach ($path in $CandidatePaths) {
        if (-not (Test-Path $path)) {
            continue
        }

        $firstLines = Get-Content -Path $path -TotalCount 30
        $idLine = ($firstLines | Where-Object { $_ -match 'ID_UNICO|ID_HINT|ID\.' } | Select-Object -First 1)
        if (-not $idLine) {
            $idLine = "UNKNOWN"
        }

        return [ordered]@{
            path = $path
            exists = $true
            last_modified_utc = (Get-Item $path).LastWriteTimeUtc.ToString("o")
            id_hint = $idLine.Trim()
        }
    }

    return [ordered]@{
        path = $null
        exists = $false
        last_modified_utc = $null
        id_hint = "UNKNOWN"
    }
}

function Get-HIARadarRefs {
    param(
        [string]$Root,
        [string]$RadarIndexPath
    )

    $refs = @()

    if (Test-Path $RadarIndexPath) {
        $file = Get-Item $RadarIndexPath
        $refs += [ordered]@{
            type = "radar_index"
            path = $file.FullName
            exists = $true
            size_bytes = $file.Length
            modified_utc = $file.LastWriteTimeUtc.ToString("o")
        }
        return $refs
    }

    $radarDir = Join-Path $Root "03_ARTIFACTS\RADAR"
    if (Test-Path $radarDir) {
        $candidate = Get-ChildItem -Path $radarDir -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '^Radar\.Index\.ACTIVE\.txt$'
        } | Select-Object -First 1

        if ($candidate) {
            $refs += [ordered]@{
                type = "radar_index"
                path = $candidate.FullName
                exists = $true
                size_bytes = $candidate.Length
                modified_utc = $candidate.LastWriteTimeUtc.ToString("o")
            }
        }
    }

    return $refs
}

function Get-HIATokenBudgetHint {
    param([string]$Level)

    switch ($Level) {
        "L0" { return 2000 }
        "L1" { return 4000 }
        "L2" { return 8000 }
        "L3" { return 12000 }
        default { return "UNKNOWN" }
    }
}

function Build-HIAContextPackage {
    param(
        [hashtable]$Paths,
        [string]$TaskTypeValue,
        [string]$TargetKindValue,
        [string]$ContextLevelValue
    )

    foreach ($dir in @($Paths.ContextDir, $Paths.HistoryDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }

    $liveState = Read-HIALiveState -LiveStatePath $Paths.LiveStatePath
    $session = Read-HIAActiveSession -SessionPath $Paths.ActiveSessionPath
    $baton = Read-HIABaton -CandidatePaths $Paths.BatonCandidatePaths
    $radarRefs = @(Get-HIARadarRefs -Root $script:ProjectRoot -RadarIndexPath $Paths.RadarIndexPath)

    $packageId = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff")
    $generatedUtc = (Get-Date).ToUniversalTime().ToString("o")

    $humanRefs = @(
        [ordered]@{ kind = "human_readme"; path = Join-Path $script:ProjectRoot "HUMAN.README"; exists = (Test-Path (Join-Path $script:ProjectRoot "HUMAN.README")) }
    )
    if ($baton.exists) {
        $humanRefs += [ordered]@{ kind = "baton"; path = $baton.path; exists = $true }
    }

    $artifactRefs = @(
        [ordered]@{ kind = "state_live"; path = $Paths.LiveStatePath; exists = (Test-Path $Paths.LiveStatePath) },
        [ordered]@{ kind = "session_active"; path = $Paths.ActiveSessionPath; exists = (Test-Path $Paths.ActiveSessionPath) },
        [ordered]@{ kind = "context_package_active"; path = $Paths.PackagePath; exists = $true },
        [ordered]@{ kind = "context_manifest_active"; path = $Paths.ManifestPath; exists = $true }
    )

    $package = [ordered]@{
        package_id = $packageId
        generated_at_utc = $generatedUtc
        task_type = $TaskTypeValue
        target_kind = $TargetKindValue
        context_level = $ContextLevelValue
        focus_actual = $liveState.focus_actual
        state_snapshot = $liveState
        session_snapshot = $session
        baton_ref = $baton
        human_refs = $humanRefs
        radar_refs = $radarRefs
        artifact_refs = $artifactRefs
        token_budget_hint = Get-HIATokenBudgetHint -Level $ContextLevelValue
        notes = @(
            "DERIVED_PACKAGE_NOT_CANONICAL_SOURCE_OF_TRUTH",
            "BUILD_MODE=MINIMUM_VIABLE_CONTEXT"
        )
    }

    $json = $package | ConvertTo-Json -Depth 12
    Set-Content -Path $Paths.PackagePath -Value $json -Encoding UTF8

    $historyPath = Join-Path $Paths.HistoryDir ("CONTEXT_{0}.json" -f $packageId)
    Set-Content -Path $historyPath -Value $json -Encoding UTF8

    $manifest = @(
        "HIA CONTEXT MANIFEST ACTIVE",
        "PACKAGE_ID: $packageId",
        "GENERATED_AT_UTC: $generatedUtc",
        "TASK_TYPE: $TaskTypeValue",
        "TARGET_KIND: $TargetKindValue",
        "CONTEXT_LEVEL: $ContextLevelValue",
        "SOURCE_STATE: $($Paths.LiveStatePath)",
        "SOURCE_SESSION: $($Paths.ActiveSessionPath)",
        "SOURCE_BATON: $($baton.path)",
        "SOURCE_RADAR_INDEX: $((($radarRefs | Select-Object -First 1).path))",
        "OUTPUT_PACKAGE: $($Paths.PackagePath)",
        "OUTPUT_HISTORY: $historyPath",
        "NOTES: Derived operational artifact. Canon remains in HUMAN/STATE/SESSION."
    )
    Set-Content -Path $Paths.ManifestPath -Value ($manifest -join [Environment]::NewLine) -Encoding UTF8

    return [ordered]@{
        Package = $package
        PackagePath = $Paths.PackagePath
        ManifestPath = $Paths.ManifestPath
        HistoryPath = $historyPath
    }
}

function Show-HIAContextPackage {
    param([hashtable]$Paths)

    if (-not (Test-Path $Paths.PackagePath)) {
        Write-Host ""
        Write-Host "CONTEXT PACKAGE NOT FOUND." -ForegroundColor Yellow
        Write-Host "Run: hia context build" -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    Get-Content -Path $Paths.PackagePath
    return $true
}

$script:ProjectRoot = Get-HIAProjectRoot -CandidateRoot $ProjectRoot
$paths = Get-HIAContextPaths -Root $script:ProjectRoot

if ($Command -eq "build") {
    $result = Build-HIAContextPackage -Paths $paths -TaskTypeValue $TaskType -TargetKindValue $TargetKind -ContextLevelValue $ContextLevel

    Write-Host ""
    Write-Host "CONTEXT BUILD COMPLETE" -ForegroundColor Green
    Write-Host "PACKAGE_PATH: $($result.PackagePath)"
    Write-Host "MANIFEST_PATH: $($result.ManifestPath)"
    Write-Host "HISTORY_PATH: $($result.HistoryPath)"
    Write-Host "FOCUS_ACTUAL: $($result.Package.focus_actual)"
    Write-Host "CONTEXT_LEVEL: $($result.Package.context_level)"
    Write-Host ""
    exit 0
}

$shown = Show-HIAContextPackage -Paths $paths
if ($shown) { exit 0 }
exit 1
