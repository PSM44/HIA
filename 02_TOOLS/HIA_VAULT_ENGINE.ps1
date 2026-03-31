<#
===============================================================================
MODULE: HIA_VAULT_ENGINE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: VAULT SHELL MVP (MB-1.9)
===============================================================================

OBJETIVO
Vault shell mínima para capturar, listar y consultar ideas/aprendizajes/
pendientes reutilizables.

QUE ES EL VAULT
- ideas, hipótesis, hallazgos, aprendizajes, pendientes de exploración,
  mejoras futuras, decisiones que aún no son backlog formal

QUE NO ES EL VAULT
- session log
- backlog activo
- minibattle activa
- project state live

ESTRUCTURA EN DISCO
  <ProjectRoot>\03_ARTIFACTS\VAULT\
    VAULT.INDEX.json
    entries\
      VAULT_YYYYMMDD_HHMMSS_<slug>.txt

TIPOS SOPORTADOS
  idea | hypothesis | learning | improvement | note | risk

OPERACIONES
  1. List entries
  2. Add entry
  3. View entry
  4. Help
  5. Back (sale del vault shell)

REPLAY (para validación no interactiva)
Si $env:HIA_INTERACTIVE_REPLAY apunta a un .txt, consume inputs línea por línea.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# PATHS
# ---------------------------------------------------------------------------

function Get-HIAVaultDir {
    param([string]$ProjectRoot)
    return (Join-Path $ProjectRoot "03_ARTIFACTS\VAULT")
}

function Get-HIAVaultIndexPath {
    param([string]$ProjectRoot)
    return (Join-Path (Get-HIAVaultDir -ProjectRoot $ProjectRoot) "VAULT.INDEX.json")
}

function Get-HIAVaultEntriesDir {
    param([string]$ProjectRoot)
    return (Join-Path (Get-HIAVaultDir -ProjectRoot $ProjectRoot) "entries")
}

# ---------------------------------------------------------------------------
# INIT
# ---------------------------------------------------------------------------

function Initialize-HIAVault {
    param([string]$ProjectRoot)

    $vaultDir   = Get-HIAVaultDir    -ProjectRoot $ProjectRoot
    $entriesDir = Get-HIAVaultEntriesDir -ProjectRoot $ProjectRoot
    $indexPath  = Get-HIAVaultIndexPath  -ProjectRoot $ProjectRoot

    if (-not (Test-Path -LiteralPath $vaultDir)) {
        New-Item -ItemType Directory -Path $vaultDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $entriesDir)) {
        New-Item -ItemType Directory -Path $entriesDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $indexPath)) {
        $emptyIndex = [ordered]@{
            vault_version = "1.0"
            created_utc   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            entries       = @()
        }
        $emptyIndex | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $indexPath -Encoding UTF8
    }
}

# ---------------------------------------------------------------------------
# INDEX READ / WRITE
# ---------------------------------------------------------------------------

function Read-HIAVaultIndex {
    param([string]$ProjectRoot)

    Initialize-HIAVault -ProjectRoot $ProjectRoot

    $indexPath = Get-HIAVaultIndexPath -ProjectRoot $ProjectRoot
    try {
        $raw = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
        $data = $raw | ConvertFrom-Json
        # Normalize entries to array
        if ($null -eq $data.entries) {
            $data | Add-Member -MemberType NoteProperty -Name "entries" -Value @() -Force
        }
        return $data
    }
    catch {
        Write-Host ("VAULT: error reading index: {0}" -f $_.Exception.Message) -ForegroundColor Red
        return $null
    }
}

function Save-HIAVaultIndex {
    param(
        [string]$ProjectRoot,
        [object]$Index
    )
    $indexPath = Get-HIAVaultIndexPath -ProjectRoot $ProjectRoot
    $Index | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $indexPath -Encoding UTF8
}

# ---------------------------------------------------------------------------
# ENTRY OPERATIONS
# ---------------------------------------------------------------------------

function New-HIAVaultEntryFile {
    param(
        [string]$ProjectRoot,
        [string]$Title,
        [string]$Type,
        [string]$ProjectScope,
        [string]$Source,
        [string]$Body
    )

    Initialize-HIAVault -ProjectRoot $ProjectRoot

    $now      = Get-Date
    $nowUtc   = $now.ToUniversalTime()
    $stamp    = $now.ToString("yyyyMMdd_HHmmss")

    # Build slug from title: lowercase, spaces → underscore, strip non-alphanumeric
    $slug = ($Title.ToLower() -replace '[^a-z0-9\s]', '') -replace '\s+', '_'
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40) }
    if ([string]::IsNullOrWhiteSpace($slug)) { $slug = "entry" }

    $vaultId  = "VAULT_{0}_{1}" -f $stamp, $slug
    $fileName = "{0}.txt" -f $vaultId
    $entryPath = Join-Path (Get-HIAVaultEntriesDir -ProjectRoot $ProjectRoot) $fileName

    # Validate type
    $validTypes = @("idea","hypothesis","learning","improvement","note","risk")
    $typeNorm = $Type.ToLower().Trim()
    if ($typeNorm -notin $validTypes) { $typeNorm = "note" }

    # Validate scope
    $scopeNorm = $ProjectScope.Trim()
    if ([string]::IsNullOrWhiteSpace($scopeNorm)) { $scopeNorm = "global" }

    # Write entry file
    $entryContent = @"
VAULT_ID:      $vaultId
TITLE:         $Title
TYPE:          $typeNorm
PROJECT_SCOPE: $scopeNorm
STATUS:        active
CREATED_UTC:   $($nowUtc.ToString("yyyy-MM-ddTHH:mm:ssZ"))
SOURCE:        $Source
--------------------------------------------------------------------------------
BODY:
$Body
"@

    Set-Content -LiteralPath $entryPath -Value $entryContent -Encoding UTF8

    # Update index
    $index = Read-HIAVaultIndex -ProjectRoot $ProjectRoot
    $entryMeta = [ordered]@{
        vault_id      = $vaultId
        title         = $Title
        type          = $typeNorm
        project_scope = $scopeNorm
        status        = "active"
        created_utc   = $nowUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
        file          = $fileName
    }

    $existingEntries = @($index.entries)
    $updatedEntries  = $existingEntries + $entryMeta
    $index | Add-Member -MemberType NoteProperty -Name "entries" -Value $updatedEntries -Force

    Save-HIAVaultIndex -ProjectRoot $ProjectRoot -Index $index

    return [ordered]@{
        vault_id   = $vaultId
        file       = $fileName
        entry_path = $entryPath
    }
}

function Read-HIAVaultEntryFile {
    param(
        [string]$ProjectRoot,
        [string]$FileName
    )
    $path = Join-Path (Get-HIAVaultEntriesDir -ProjectRoot $ProjectRoot) $FileName
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    return (Get-Content -LiteralPath $path -Raw -Encoding UTF8)
}

# ---------------------------------------------------------------------------
# DISPLAY HELPERS
# ---------------------------------------------------------------------------

function Write-HIAVaultHeader {
    param([string]$ProjectRoot)
    try { Clear-Host } catch { }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " HIA — Vault Shell (MB-1.9)" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host (" ROOT:  {0}" -f $ProjectRoot)
    Write-Host (" NOW:   {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    Write-Host " Vault: ideas · hipótesis · aprendizajes · mejoras · notas · riesgos" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-HIAVaultMenu {
    Write-Host "VAULT — Menú" -ForegroundColor Yellow
    Write-Host "1.- Listar entradas"
    Write-Host "2.- Agregar entrada"
    Write-Host "3.- Ver detalle de entrada"
    Write-Host "F1.- Ayuda"
    Write-Host "0.- Volver (portfolio shell)"
    Write-Host ""
}

function Show-HIAVaultHelp {
    Write-Host ""
    Write-Host "AYUDA — Vault Shell" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "El Vault captura conocimiento reutilizable:"
    Write-Host "  idea        - Idea pendiente de evaluar"
    Write-Host "  hypothesis  - Hipótesis a validar"
    Write-Host "  learning    - Aprendizaje obtenido"
    Write-Host "  improvement - Mejora futura propuesta"
    Write-Host "  note        - Nota general"
    Write-Host "  risk        - Riesgo identificado"
    Write-Host ""
    Write-Host "El Vault NO es:"
    Write-Host "  - Session log"
    Write-Host "  - Backlog activo"
    Write-Host "  - Minibattle activa"
    Write-Host "  - Project state live"
    Write-Host ""
    Write-Host "Estructura en disco:"
    Write-Host "  03_ARTIFACTS\VAULT\VAULT.INDEX.json"
    Write-Host "  03_ARTIFACTS\VAULT\entries\VAULT_YYYYMMDD_HHMMSS_<slug>.txt"
    Write-Host ""
}

function Show-HIAVaultList {
    param([string]$ProjectRoot)

    $index = Read-HIAVaultIndex -ProjectRoot $ProjectRoot
    if ($null -eq $index) {
        Write-Host "ERROR: No se pudo leer el índice del Vault." -ForegroundColor Red
        return
    }

    $entries = @($index.entries)
    Write-Host ""
    Write-Host ("VAULT — ENTRADAS: {0}" -f $entries.Count) -ForegroundColor Yellow
    Write-Host ""

    if ($entries.Count -eq 0) {
        Write-Host "  (Vault vacío. Usa opción 2 para agregar una entrada.)" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    for ($i = 0; $i -lt $entries.Count; $i++) {
        $e = $entries[$i]
        Write-Host ("{0,3}.- [{1,-12}] {2}" -f ($i + 1), [string]$e.type, [string]$e.title) -ForegroundColor Cyan
        Write-Host ("       ID:     {0}" -f [string]$e.vault_id) -ForegroundColor DarkGray
        Write-Host ("       SCOPE:  {0}  |  STATUS: {1}  |  CREATED: {2}" -f [string]$e.project_scope, [string]$e.status, [string]$e.created_utc) -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Show-HIAVaultEntryDetail {
    param(
        [string]$ProjectRoot,
        [int]$Index
    )

    $vaultIndex = Read-HIAVaultIndex -ProjectRoot $ProjectRoot
    if ($null -eq $vaultIndex) {
        Write-Host "ERROR: No se pudo leer el índice del Vault." -ForegroundColor Red
        return
    }

    $entries = @($vaultIndex.entries)
    if ($entries.Count -eq 0) {
        Write-Host "  (Vault vacío. Usa opción 2 para agregar una entrada.)" -ForegroundColor DarkGray
        return
    }

    $i = $Index - 1
    if ($i -lt 0 -or $i -ge $entries.Count) {
        Write-Host "  Número fuera de rango. Entradas disponibles: 1 a $($entries.Count)" -ForegroundColor Yellow
        return
    }

    $entry = $entries[$i]
    $raw = Read-HIAVaultEntryFile -ProjectRoot $ProjectRoot -FileName ([string]$entry.file)

    Write-Host ""
    Write-Host "VAULT — DETALLE ENTRADA #$($Index)" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

    if ($null -eq $raw) {
        Write-Host "  ERROR: Archivo de entrada no encontrado." -ForegroundColor Red
        Write-Host ("  FILE: {0}" -f [string]$entry.file) -ForegroundColor DarkGray
    }
    else {
        Write-Host $raw
    }

    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# ---------------------------------------------------------------------------
# ADD ENTRY — INTERACTIVE WIZARD
# ---------------------------------------------------------------------------

function Add-HIAVaultEntryInteractive {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    Write-Host ""
    Write-Host "VAULT — NUEVA ENTRADA" -ForegroundColor Yellow
    Write-Host "Tipos válidos: idea | hypothesis | learning | improvement | note | risk" -ForegroundColor DarkGray
    Write-Host ""

    $title = (Read-HIAVaultInput -Prompt " TITLE (texto breve): " -ReplayQueue $ReplayQueue).Trim()
    if ([string]::IsNullOrWhiteSpace($title)) {
        Write-Host "  CANCELADO: el título no puede estar vacío." -ForegroundColor Yellow
        return
    }

    $type = (Read-HIAVaultInput -Prompt " TYPE [note]: " -ReplayQueue $ReplayQueue).Trim()
    if ([string]::IsNullOrWhiteSpace($type)) { $type = "note" }

    $scope = (Read-HIAVaultInput -Prompt " PROJECT_SCOPE (global / project_id / none) [global]: " -ReplayQueue $ReplayQueue).Trim()
    if ([string]::IsNullOrWhiteSpace($scope)) { $scope = "global" }

    $source = (Read-HIAVaultInput -Prompt " SOURCE (sesion/manual/radar/etc.) [manual]: " -ReplayQueue $ReplayQueue).Trim()
    if ([string]::IsNullOrWhiteSpace($source)) { $source = "manual" }

    Write-Host " BODY (texto de la entrada. Escribe 'END' en línea sola para terminar):" -ForegroundColor DarkGray
    $bodyLines = New-Object System.Collections.Generic.List[string]
    while ($true) {
        $line = Read-HIAVaultInput -Prompt "   " -ReplayQueue $ReplayQueue
        if ($line.Trim().ToUpperInvariant() -eq "END") { break }
        $bodyLines.Add($line)
        # Safety: if ReplayQueue is active and exhausted, stop
        if ($ReplayQueue -and $ReplayQueue.Count -eq 0 -and $bodyLines.Count -ge 1) { break }
    }
    $body = ($bodyLines -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($body)) {
        Write-Host "  CANCELADO: el body no puede estar vacío." -ForegroundColor Yellow
        return
    }

    try {
        $result = New-HIAVaultEntryFile `
            -ProjectRoot $ProjectRoot `
            -Title       $title `
            -Type        $type `
            -ProjectScope $scope `
            -Source       $source `
            -Body         $body

        Write-Host ""
        Write-Host "VAULT ENTRY CREADA" -ForegroundColor Green
        Write-Host ("  VAULT_ID: {0}" -f $result.vault_id)
        Write-Host ("  FILE:     {0}" -f $result.file)
        Write-Host ("  PATH:     {0}" -f $result.entry_path)
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "ERROR creando entrada:" -ForegroundColor Red
        Write-Host ("  {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ""
    }
}

# ---------------------------------------------------------------------------
# INPUT HELPER (wrapper para replay)
# ---------------------------------------------------------------------------

function Read-HIAVaultInput {
    param(
        [string]$Prompt,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )
    if ($ReplayQueue -and $ReplayQueue.Count -gt 0) {
        $next = $ReplayQueue.Dequeue()
        Write-Host ("{0}{1}" -f $Prompt, $next) -ForegroundColor DarkGray
        return $next
    }
    $v = Read-Host -Prompt $Prompt
    if ($null -eq $v) { return "" }
    return $v
}

function Pause-HIAVault {
    param([System.Collections.Generic.Queue[string]]$ReplayQueue)
    $null = Read-HIAVaultInput -Prompt " Enter para continuar..." -ReplayQueue $ReplayQueue
}

# ---------------------------------------------------------------------------
# MAIN VAULT SHELL
# ---------------------------------------------------------------------------

function Invoke-HIAVaultShell {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.Queue[string]]$ReplayQueue
    )

    # Ensure vault exists on disk
    try {
        Initialize-HIAVault -ProjectRoot $ProjectRoot
    }
    catch {
        Write-Host "ERROR inicializando Vault: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    while ($true) {
        Write-HIAVaultHeader -ProjectRoot $ProjectRoot
        Show-HIAVaultMenu

        $sel = (Read-HIAVaultInput -Prompt " Seleccion: " -ReplayQueue $ReplayQueue).Trim()

        switch ($sel.ToUpperInvariant()) {
            "0" { return }
            "F1" {
                Show-HIAVaultHelp
                Pause-HIAVault -ReplayQueue $ReplayQueue
            }
            "1" {
                Show-HIAVaultList -ProjectRoot $ProjectRoot
                Pause-HIAVault -ReplayQueue $ReplayQueue
            }
            "2" {
                Add-HIAVaultEntryInteractive -ProjectRoot $ProjectRoot -ReplayQueue $ReplayQueue
                Pause-HIAVault -ReplayQueue $ReplayQueue
            }
            "3" {
                Show-HIAVaultList -ProjectRoot $ProjectRoot

                $index = Read-HIAVaultIndex -ProjectRoot $ProjectRoot
                $entries = @($index.entries)

                if ($entries.Count -eq 0) {
                    Pause-HIAVault -ReplayQueue $ReplayQueue
                    continue
                }

                $pick = (Read-HIAVaultInput -Prompt " Numero de entrada a ver (X para cancelar): " -ReplayQueue $ReplayQueue).Trim()
                if ($pick.ToUpperInvariant() -eq "X") { continue }
                if ($pick -match '^\d+$') {
                    Show-HIAVaultEntryDetail -ProjectRoot $ProjectRoot -Index ([int]$pick)
                }
                else {
                    Write-Host "  Entrada inválida." -ForegroundColor Yellow
                }
                Pause-HIAVault -ReplayQueue $ReplayQueue
            }
            default {
                Write-Host "  Seleccion invalida. Usa 1-3, F1 o 0." -ForegroundColor Yellow
                Pause-HIAVault -ReplayQueue $ReplayQueue
            }
        }
    }
}
