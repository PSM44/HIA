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
    $batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"

    $readmeStatus = if (Test-Path -LiteralPath $readmePath) { "OK" } else { "MISSING" }
    $batonStatus = if (Test-Path -LiteralPath $batonPath) { "OK" } else { "MISSING" }
    $backlogStatus = if (Test-Path -LiteralPath $backlogPath) { "OK" } else { "MISSING" }

    Write-Host ""
    Write-Host "PROJECT OPENED" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("PATH: {0}" -f $projectRoot)
    Write-Host ""
    Write-Host ("README: {0}" -f $readmeStatus)
    Write-Host ("BATON: {0}" -f $batonStatus)
    Write-Host ("BACKLOG: {0}" -f $backlogStatus)
    Write-Host ""
    Write-Host "NEXT ACTION:"
    Write-Host "Use project backlog / baton to continue development."
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

    $batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"

    $batonStatus = if (Test-Path -LiteralPath $batonPath) { "OK" } else { "MISSING" }
    $backlogStatus = if (Test-Path -LiteralPath $backlogPath) { "OK" } else { "MISSING" }

    $nextRow = $null
    if ($backlogStatus -eq "OK") {
        $lines = Get-Content -LiteralPath $backlogPath -ErrorAction Stop
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

            $status = $parts[6].ToLowerInvariant()
            if ($status -eq "ready") {
                $nextRow = [pscustomobject]@{
                    ID = $parts[0]
                    TITLE = $parts[3]
                    STATUS = $parts[6]
                }
                break
            }
        }
    }

    Write-Host ""
    Write-Host "PROJECT CONTINUE" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("PATH: {0}" -f $projectRoot)
    Write-Host ""
    Write-Host ("BATON: {0}" -f $batonStatus)
    Write-Host ("BACKLOG: {0}" -f $backlogStatus)
    Write-Host ""
    Write-Host "NEXT MINIBATTLE:"

    if ($nextRow) {
        Write-Host ("{0} | {1} | {2}" -f $nextRow.ID, $nextRow.TITLE, $nextRow.STATUS)
        Write-Host ""
        Write-Host "NEXT ACTION:"
        Write-Host "Continue development using next ready minibattle."
        Write-Host ""
        return
    }

    Write-Host "NONE"
    Write-Host ""
    Write-Host "NEXT ACTION:"
    Write-Host "No ready minibattle found in project backlog."
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

    $readmePath = Join-Path $projectRoot "README.PROJECT.txt"
    $batonPath = Join-Path $projectRoot "BATON\04.0_PROJECT.BATON.txt"
    $backlogPath = Join-Path $projectRoot "AGILE\PROJECT.BACKLOG.txt"

    $readmeStatus = if (Test-Path -LiteralPath $readmePath) { "OK" } else { "MISSING" }
    $batonStatus = if (Test-Path -LiteralPath $batonPath) { "OK" } else { "MISSING" }
    $backlogStatus = if (Test-Path -LiteralPath $backlogPath) { "OK" } else { "MISSING" }

    $readyCount = 0
    $backlogCount = 0
    $doneCount = 0
    $blockedCount = 0
    $nextRow = $null

    if ($backlogStatus -eq "OK") {
        $lines = Get-Content -LiteralPath $backlogPath -ErrorAction Stop
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

            $status = $parts[6].ToLowerInvariant()
            switch ($status) {
                "ready" { $readyCount++ }
                "backlog" { $backlogCount++ }
                "done" { $doneCount++ }
                "blocked" { $blockedCount++ }
            }

            if (-not $nextRow -and $status -eq "ready") {
                $nextRow = [pscustomobject]@{
                    ID = $parts[0]
                    TITLE = $parts[3]
                    STATUS = $parts[6]
                }
            }
        }
    }

    Write-Host ""
    Write-Host "PROJECT STATUS" -ForegroundColor Green
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("PATH: {0}" -f $projectRoot)
    Write-Host ""
    Write-Host ("README: {0}" -f $readmeStatus)
    Write-Host ("BATON: {0}" -f $batonStatus)
    Write-Host ("BACKLOG: {0}" -f $backlogStatus)
    Write-Host ""
    Write-Host "BACKLOG COUNTS:"
    Write-Host ("READY: {0}" -f $readyCount)
    Write-Host ("BACKLOG: {0}" -f $backlogCount)
    Write-Host ("DONE: {0}" -f $doneCount)
    Write-Host ("BLOCKED: {0}" -f $blockedCount)
    Write-Host ""
    Write-Host "NEXT MINIBATTLE:"

    if ($nextRow) {
        Write-Host ("{0} | {1} | {2}" -f $nextRow.ID, $nextRow.TITLE, $nextRow.STATUS)
    }
    else {
        Write-Host "NONE"
    }

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
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("SESSION_ID: {0}" -f $sessionId)
    Write-Host ("PATH: {0}" -f $sessionPath)
    Write-Host ""
}

function Get-HIAProjectSessionStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $sessionPath = Get-HIAProjectSessionPath -ProjectId $ProjectId

    Write-Host ""
    Write-Host "PROJECT SESSION STATUS" -ForegroundColor Cyan
    Write-Host ("ID: {0}" -f $ProjectId)

    if (-not (Test-Path -LiteralPath $sessionPath)) {
        Write-Host "STATUS: NONE"
        Write-Host ("PATH: {0}" -f $sessionPath)
        Write-Host ""
        return
    }

    $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
    $startedUtc = Convert-HIAUtcValueToString -Value $session.started_utc -Default "NONE"
    $closedUtc = Convert-HIAUtcValueToString -Value $session.closed_utc -Default "NONE"

    Write-Host ("STATUS: {0}" -f $session.status)
    Write-Host ("SESSION_ID: {0}" -f $session.session_id)
    Write-Host ("STARTED_UTC: {0}" -f $startedUtc)
    Write-Host ("CLOSED_UTC: {0}" -f $closedUtc)
    Write-Host ("PATH: {0}" -f $sessionPath)
    Write-Host ""
}

function Close-HIAProjectSession {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectId
    )

    $sessionPath = Get-HIAProjectSessionPath -ProjectId $ProjectId
    if (-not (Test-Path -LiteralPath $sessionPath)) {
        throw ("Project session not found: {0}" -f $sessionPath)
    }

    $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
    $session.status = "closed"
    $session.closed_utc = (Get-Date).ToUniversalTime().ToString("o")
    $session | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $sessionPath -Encoding UTF8

    Write-Host ""
    Write-Host "PROJECT SESSION CLOSED" -ForegroundColor Yellow
    Write-Host ("ID: {0}" -f $ProjectId)
    Write-Host ("SESSION_ID: {0}" -f $session.session_id)
    Write-Host ("PATH: {0}" -f $sessionPath)
    Write-Host ""
}

function Get-HIAProjects {
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

    $i = 1
    foreach ($proj in $projects) {
        Write-Host ("{0}. {1}" -f $i, $proj.Name)
        $i++
    }

    Write-Host ""
}
