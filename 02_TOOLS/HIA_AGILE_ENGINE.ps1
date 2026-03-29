<#
===============================================================================
MODULE: HIA_AGILE_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: AGILE SYNCHRONIZATION ENGINE

OBJETIVO
Sincronizar artefactos Agile derivados desde Vision + Product Backlog.

COMMANDS:
- sync
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("sync")]
    [string]$Command = "sync"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
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

function Get-HIAAgilePaths {
    param([string]$ProjectRoot)

    $agileRoot = Join-Path $ProjectRoot "00_FRAMEWORK\AGILE"
    return [ordered]@{
        AgileRoot = $agileRoot
        Vision = Join-Path $agileRoot "HIA_AGL_0000_PRODUCT.VISION.txt"
        Backlog = Join-Path $agileRoot "HIA_AGL_0003_PRODUCT.BACKLOG.txt"
        Roadmap = Join-Path $agileRoot "HIA_AGL_0001_ROADMAP.txt"
        ReleasePlan = Join-Path $agileRoot "HIA_AGL_0002_RELEASE.PLAN.txt"
        Kanban = Join-Path $agileRoot "HIA_AGL_0004_KANBAN.ACTIVE.txt"
        Minibattles = Join-Path $agileRoot "HIA_AGL_0005_MINIBATTLES.ACTIVE.txt"
        Vault = Join-Path $agileRoot "HIA_AGL_0006_VAULT.IDEAS.txt"
        Warnings = Join-Path $agileRoot "HIA_AGL_0007_WARNINGS.ACTIVE.txt"
    }
}

function Get-HIAStableStampUtc {
    param([string[]]$SourcePaths)

    $timestamps = @()
    foreach ($path in $SourcePaths) {
        if (Test-Path $path) {
            $timestamps += (Get-Item $path).LastWriteTimeUtc
        }
    }

    if (@($timestamps).Count -eq 0) {
        return "UNKNOWN"
    }

    $latest = $timestamps | Sort-Object -Descending | Select-Object -First 1
    return $latest.ToString("o")
}

function Read-HIATextFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return ""
    }

    return (Get-Content -Path $Path -Raw)
}

function Parse-HIABacklogTable {
    param([string]$BacklogPath)

    $items = @()

    if (-not (Test-Path $BacklogPath)) {
        return $items
    }

    $lines = Get-Content -Path $BacklogPath
    foreach ($line in $lines) {
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

        $separatorCandidate = ($parts -join "")
        if ($separatorCandidate -match '^[\-\s]+$') {
            continue
        }

        $items += [pscustomobject]@{
            ID = $parts[0]
            TYPE = $parts[1].ToLowerInvariant()
            PRIORITY = $parts[2].ToUpperInvariant()
            TITLE = $parts[3]
            VALUE = $parts[4]
            EFFORT = $parts[5]
            STATUS = $parts[6].ToLowerInvariant()
        }
    }

    return @($items)
}

function Get-HIAKanbanStatus {
    param([string]$Status)

    switch ($Status.ToLowerInvariant()) {
        "backlog" { return "READY" }
        "ready" { return "READY" }
        "inprogress" { return "IN_PROGRESS" }
        "blocked" { return "BLOCKED" }
        "done" { return "DONE" }
        default { return "READY" }
    }
}

function New-HIAWarnings {
    param([object[]]$Items)

    $warnings = @()

    foreach ($item in $Items) {
        if ([string]::IsNullOrWhiteSpace($item.TITLE)) {
            $warnings += "WARN_MISSING_TITLE | $($item.ID) | Backlog item without TITLE"
        }

        if ($item.TYPE -eq "minibattle" -and [string]::IsNullOrWhiteSpace($item.VALUE)) {
            $warnings += "WARN_MINIBATTLE_NO_VALUE | $($item.ID) | Minibattle without VALUE"
        }

        if ($item.PRIORITY -notin @("P0", "P1")) {
            $warnings += "WARN_OUTSIDE_RELEASE_SCOPE | $($item.ID) | Priority $($item.PRIORITY) outside active release"
        }
    }

    return @($warnings)
}

function Convert-HIAItemsToLines {
    param([object[]]$Items)

    $lines = @()
    foreach ($item in ($Items | Sort-Object PRIORITY, ID)) {
        $lines += "$($item.ID) | $($item.TYPE) | $($item.PRIORITY) | $($item.TITLE) | $($item.VALUE) | $($item.EFFORT) | $($item.STATUS)"
    }
    return @($lines)
}

function Write-HIAAgileFile {
    param(
        [string]$Path,
        [string[]]$ContentLines
    )

    $final = ($ContentLines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine
    Set-Content -Path $Path -Value $final -Encoding utf8
}

function Sync-HIAAgileArtifacts {
    param([hashtable]$Paths)

    $visionText = Read-HIATextFile -Path $Paths.Vision
    $visionLines = @(
        $visionText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 6
    )
    if (@($visionLines).Count -eq 0) {
        $visionLines = @("UNKNOWN")
    }

    $items = Parse-HIABacklogTable -BacklogPath $Paths.Backlog
    $activeRelease = @($items | Where-Object { $_.PRIORITY -in @("P0", "P1") })
    $vaultItems = @($items | Where-Object { $_.PRIORITY -in @("P2", "P3") })
    $minibattles = @($items | Where-Object { $_.TYPE -eq "minibattle" })
    $warnings = New-HIAWarnings -Items $items

    if (@($items).Count -eq 0) {
        $warnings += "WARN_EMPTY_BACKLOG | N/A | No backlog rows parsed from table format"
    }

    $stampUtc = Get-HIAStableStampUtc -SourcePaths @($Paths.Vision, $Paths.Backlog)

    $roadmapLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0001_ROADMAP.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: AGILE ROADMAP (DERIVED)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "VISION_EXTRACT",
        "-------------------------------------------------------------------------------"
    ) + $visionLines + @(
        "",
        "ACTIVE_RELEASE_SCOPE (P0/P1)",
        "-------------------------------------------------------------------------------"
    ) + (Convert-HIAItemsToLines -Items $activeRelease)

    if (@($activeRelease).Count -eq 0) {
        $roadmapLines += "NONE"
    }

    $releaseLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0002_RELEASE.PLAN.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: RELEASE PLAN (ACTIVE)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "RULE: Only P0/P1 backlog items are included in active release.",
        "",
        "ID | TYPE | PRIORITY | TITLE | VALUE | EFFORT | STATUS",
        "-------------------------------------------------------------------------------"
    ) + (Convert-HIAItemsToLines -Items $activeRelease)

    if (@($activeRelease).Count -eq 0) {
        $releaseLines += "NONE"
    }

    $kanbanRows = @()
    foreach ($item in ($activeRelease | Sort-Object PRIORITY, ID)) {
        $kanbanRows += "$($item.ID) | $($item.TITLE) | $(Get-HIAKanbanStatus -Status $item.STATUS) | $($item.PRIORITY) | $($item.TYPE)"
    }

    $kanbanLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0004_KANBAN.ACTIVE.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: KANBAN ACTIVE BOARD (DERIVED)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "STATUS MAP: backlog->READY, ready->READY, inprogress->IN_PROGRESS, blocked->BLOCKED, done->DONE",
        "",
        "ID | TITLE | KANBAN_STATUS | PRIORITY | TYPE",
        "-------------------------------------------------------------------------------"
    ) + $kanbanRows

    if (@($kanbanRows).Count -eq 0) {
        $kanbanLines += "NONE"
    }

    $minibattleRows = @()
    foreach ($item in ($minibattles | Sort-Object PRIORITY, ID)) {
        $minibattleRows += "$($item.ID) | $($item.PRIORITY) | $($item.TITLE) | $($item.VALUE) | $($item.STATUS)"
    }

    $minibattleLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0005_MINIBATTLES.ACTIVE.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: MINIBATTLES ACTIVE (DERIVED)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "TYPE RULE: TYPE=minibattle generates a minibattle entry.",
        "",
        "ID | PRIORITY | TITLE | VALUE | STATUS",
        "-------------------------------------------------------------------------------"
    ) + $minibattleRows

    if (@($minibattleRows).Count -eq 0) {
        $minibattleLines += "NONE"
    }

    $vaultLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0006_VAULT.IDEAS.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: IDEA VAULT (P2/P3 BACKLOG)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "RULE: P2/P3 items are out of active release scope and move to vault.",
        "",
        "ID | TYPE | PRIORITY | TITLE | VALUE | EFFORT | STATUS",
        "-------------------------------------------------------------------------------"
    ) + (Convert-HIAItemsToLines -Items $vaultItems)

    if (@($vaultItems).Count -eq 0) {
        $vaultLines += "NONE"
    }

    $warningLines = @(
        "===============================================================================",
        "FILE: HIA_AGL_0007_WARNINGS.ACTIVE.txt",
        "SYSTEM: HIA - Human Intelligence Amplifier",
        "TYPE: AGILE WARNINGS (DERIVED)",
        "STAMP_UTC: $stampUtc",
        "SOURCE: HIA_AGILE_ENGINE.ps1",
        "===============================================================================",
        "",
        "RULES: missing TITLE, minibattle without VALUE, outside release scope.",
        "",
        "WARNING_CODE | ITEM_ID | DETAIL",
        "-------------------------------------------------------------------------------"
    ) + $warnings

    if (@($warnings).Count -eq 0) {
        $warningLines += "NONE"
    }

    Write-HIAAgileFile -Path $Paths.Roadmap -ContentLines $roadmapLines
    Write-HIAAgileFile -Path $Paths.ReleasePlan -ContentLines $releaseLines
    Write-HIAAgileFile -Path $Paths.Kanban -ContentLines $kanbanLines
    Write-HIAAgileFile -Path $Paths.Minibattles -ContentLines $minibattleLines
    Write-HIAAgileFile -Path $Paths.Vault -ContentLines $vaultLines
    Write-HIAAgileFile -Path $Paths.Warnings -ContentLines $warningLines

    Write-Host ""
    Write-Host "HIA AGILE SYNC COMPLETED" -ForegroundColor Green
    Write-Host "ROADMAP:      $($Paths.Roadmap)"
    Write-Host "RELEASE:      $($Paths.ReleasePlan)"
    Write-Host "KANBAN:       $($Paths.Kanban)"
    Write-Host "MINIBATTLES:  $($Paths.Minibattles)"
    Write-Host "VAULT:        $($Paths.Vault)"
    Write-Host "WARNINGS:     $($Paths.Warnings)"
    Write-Host ""
}

switch ($Command) {
    "sync" {
        $projectRoot = Get-HIAProjectRoot
        $paths = Get-HIAAgilePaths -ProjectRoot $projectRoot
        Sync-HIAAgileArtifacts -Paths $paths
        break
    }
}
