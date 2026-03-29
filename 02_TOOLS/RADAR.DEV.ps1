<#
========================================================================
00.00_METADATOS_DEL_SCRIPT
========================================================================

ID_UNICO..........: HIA.TOOL.RADAR.DEV.0001
NOMBRE_SUGERIDO...: RADAR.DEV.ps1
VERSION...........: v3.1-DRAFT
FECHA.............: 2026-03-10
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Santiago, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\RADAR.DEV.ps1
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.4 Thinking

OBJETIVO
- Laboratorio RADAR de HIA.
- Generar salidas por target sin contaminar outputs canónicos.
- Permitir exploración de carpetas específicas.
- Opcionalmente producir un RADAR.Full DEV_ONLY.

REGLAS DURAS
- Este script NO es runner canónico.
- Este script NO debe ser invocado por triggers canónicos.
- Este script NO reemplaza RADAR.ps1.

COMO_EJECUTAR
pwsh -NoProfile -File .\02_TOOLS\RADAR.DEV.ps1
pwsh -NoProfile -File .\02_TOOLS\RADAR.DEV.ps1 -Targets "HUMAN.README","02_TOOLS","00_FRAMEWORK"
pwsh -NoProfile -File .\02_TOOLS\RADAR.DEV.ps1 -IncludeFull
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = $null,

    [Parameter(Mandatory = $false)]
    [string]$OutDirRel = "03_ARTIFACTS\RADAR",

    [Parameter(Mandatory = $false)]
    [string[]]$Targets = @("HUMAN.README", "02_TOOLS", "05_Triggers", "00_FRAMEWORK", "04_PROJECTS", "DragnDrop"),

    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Text", "All")]
    [string]$HashMode = "Text",

    [Parameter(Mandatory = $false)]
    [long]$MaxOutputBytes = 8388608,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeFull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ========================================================================
# 01.00_FUNCIONES_BASE
# ========================================================================

function New-DirectoryIfMissing {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not [System.IO.Directory]::Exists($Path)) {
        [void][System.IO.Directory]::CreateDirectory($Path)
    }
}

function Get-FullPathSafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$RootPath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    $root = (Get-FullPathSafe -Path $RootPath).TrimEnd('\')
    $full = Get-FullPathSafe -Path $FullPath

    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart('\')
    }

    return $full
}

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Path)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $hash = $sha.ComputeHash($fs)
            return ([BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
        }
        finally {
            $fs.Dispose()
        }
    }
    finally {
        $sha.Dispose()
    }
}

function Get-TextExtensionSet {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    @(
        ".txt",".md",".json",".yaml",".yml",".xml",".ini",".cfg",".conf",".toml",".env",
        ".ps1",".psm1",".psd1",".py",".js",".ts",".tsx",".jsx",".java",".cs",".go",".rs",".rb",".php",".sh",".bat",".cmd",
        ".sql",".csv"
    ) | ForEach-Object { [void]$set.Add($_) }

    return $set
}

function Get-HashAllowlistNameSet {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    @(".gitignore",".gitattributes",".editorconfig",".npmrc",".yarnrc",".prettierrc",".eslintrc") | ForEach-Object { [void]$set.Add($_) }

    return $set
}

function Test-ExcludedPath {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][string[]]$ExcludedContains
    )

    $normalized = $FullPath.Replace('/', '\')

    foreach ($frag in $ExcludedContains) {
        if ($normalized.IndexOf($frag, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Test-TextEligiblePath {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AllowlistNameSet
    )

    $leaf = [System.IO.Path]::GetFileName($FullPath)

    if ($AllowlistNameSet.Contains($leaf)) {
        return $true
    }

    $ext = [System.IO.Path]::GetExtension($leaf)
    if ([string]::IsNullOrWhiteSpace($ext)) {
        return $false
    }

    return $TextExtSet.Contains($ext)
}

function Convert-BytesToText {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3)
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($Bytes, 2, $Bytes.Length - 2)
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($Bytes, 2, $Bytes.Length - 2)
    }

    try {
        return [System.Text.Encoding]::UTF8.GetString($Bytes)
    }
    catch {
        return [System.Text.Encoding]::Default.GetString($Bytes)
    }
}

function Get-FileTextSafe {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        return Convert-BytesToText -Bytes $bytes
    }
    catch {
        return "[READ_FAIL: " + $_.Exception.Message + "]"
    }
}

function Get-LogicalType {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AllowlistNameSet
    )

    if (Test-TextEligiblePath -FullPath $FullPath -TextExtSet $TextExtSet -AllowlistNameSet $AllowlistNameSet) {
        return "text"
    }

    $ext = [System.IO.Path]::GetExtension($FullPath)
    if ([string]::IsNullOrWhiteSpace($ext)) { return "no_ext" }

    $binaryLike = @(".exe",".dll",".png",".jpg",".jpeg",".webp",".gif",".pdf",".xlsx",".xls",".pptx",".docx",".zip",".7z",".rar",".bin")
    if ($binaryLike -contains $ext.ToLowerInvariant()) { return "binary" }

    return "other"
}

function Get-FileEntryListDeterministic {
    param(
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string[]]$ExcludedContains,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AllowlistNameSet,
        [Parameter(Mandatory = $true)][string]$HashMode
    )

    $options = New-Object System.IO.EnumerationOptions
    $options.RecurseSubdirectories = $true
    $options.IgnoreInaccessible = $true
    $options.ReturnSpecialDirectories = $false
    $options.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint

    $records = New-Object System.Collections.Generic.List[object]

    foreach ($full in [System.IO.Directory]::EnumerateFiles($TargetRoot, "*", $options)) {
        if (Test-ExcludedPath -FullPath $full -ExcludedContains $ExcludedContains) {
            continue
        }

        $info = [System.IO.FileInfo]::new($full)
        $type = Get-LogicalType -FullPath $full -TextExtSet $TextExtSet -AllowlistNameSet $AllowlistNameSet

        if ($type -ne "text") {
            continue
        }

        $sha = ""
        if ($HashMode -eq "All" -or $HashMode -eq "Text") {
            $sha = Get-Sha256Hex -Path $full
        }

        $records.Add([pscustomobject]@{
            RelPath     = Get-RelativePathSafe -RootPath $TargetRoot -FullPath $full
            FullPath    = $full
            Size        = [int64]$info.Length
            ModifiedUtc = $info.LastWriteTimeUtc.ToString("o")
            Sha256      = $sha
        }) | Out-Null
    }

    return @($records.ToArray() | Sort-Object -Property RelPath)
}

function Write-SegmentedTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$ActivePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][long]$MaxBytes
    )

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8.GetBytes($Content)

    if ($bytes.Length -le $MaxBytes) {
        [System.IO.File]::WriteAllText($ActivePath, $Content, $utf8)
        return @($ActivePath)
    }

    $dir = Split-Path -Parent $ActivePath
    $base = [System.IO.Path]::GetFileNameWithoutExtension($ActivePath)
    $ext  = [System.IO.Path]::GetExtension($ActivePath)

    $segments = New-Object System.Collections.Generic.List[string]
    $lines = $Content -split "`r?`n"
    $builder = New-Object System.Text.StringBuilder
    $segmentIndex = 1

    foreach ($line in $lines) {
        $candidate = if ($builder.Length -eq 0) { $line } else { $builder.ToString() + "`r`n" + $line }
        $candidateBytes = $utf8.GetByteCount($candidate)

        if ($candidateBytes -gt $MaxBytes -and $builder.Length -gt 0) {
            $segPath = Join-Path $dir ($base + ".seg." + $segmentIndex.ToString("000") + $ext)
            [System.IO.File]::WriteAllText($segPath, $builder.ToString(), $utf8)
            $segments.Add($segPath) | Out-Null
            $builder.Clear() | Out-Null
            [void]$builder.Append($line)
            $segmentIndex++
        }
        else {
            $builder.Clear() | Out-Null
            [void]$builder.Append($candidate)
        }
    }

    if ($builder.Length -gt 0) {
        $segPath = Join-Path $dir ($base + ".seg." + $segmentIndex.ToString("000") + $ext)
        [System.IO.File]::WriteAllText($segPath, $builder.ToString(), $utf8)
        $segments.Add($segPath) | Out-Null
    }

    $pointer = New-Object System.Collections.Generic.List[string]
    $pointer.Add("RADAR_SEGMENTED_OUTPUT") | Out-Null
    $pointer.Add("ACTIVE_FILE: " + $ActivePath) | Out-Null
    $pointer.Add("SEGMENT_COUNT: " + $segments.Count) | Out-Null
    $pointer.Add("SEGMENTS:") | Out-Null
    foreach ($p in $segments) {
        $pointer.Add(" - " + $p) | Out-Null
    }

    [System.IO.File]::WriteAllText($ActivePath, ($pointer -join "`r`n"), $utf8)
    return @($ActivePath) + @($segments.ToArray())
}

function Write-DevTargetOutput {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$OutFilePath,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string[]]$ExcludedContains,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$AllowlistNameSet,
        [Parameter(Mandatory = $true)][string]$HashMode,
        [Parameter(Mandatory = $true)][long]$MaxBytes
    )

    if (-not [System.IO.Directory]::Exists($TargetRoot)) {
        throw "TargetRoot no existe: " + $TargetRoot
    }

    $records = Get-FileEntryListDeterministic `
        -TargetRoot $TargetRoot `
        -ExcludedContains $ExcludedContains `
        -TextExtSet $TextExtSet `
        -AllowlistNameSet $AllowlistNameSet `
        -HashMode $HashMode

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("RADAR_DEV_OUTPUT — HIA") | Out-Null
    $lines.Add("LABEL: " + $Label) | Out-Null
    $lines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
    $lines.Add("PROJECT_ROOT: " + $ProjectRoot) | Out-Null
    $lines.Add("TARGET_ROOT: " + $TargetRoot) | Out-Null
    $lines.Add("FILES_COUNT: " + $records.Count) | Out-Null
    $lines.Add("MODE: DEV_ONLY") | Out-Null
    $lines.Add("") | Out-Null

    if ($Label -eq "00_FRAMEWORK") {
        $lines.Add("SECTION: AGILE_SCOPE") | Out-Null
        $lines.Add("CANONICAL_HUMAN_SOURCES:") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0000_PRODUCT.VISION.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0003_PRODUCT.BACKLOG.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0008_DEFINITION.OF.DONE.txt") | Out-Null
        $lines.Add("DERIVED_OUTPUTS:") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0001_ROADMAP.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0002_RELEASE.PLAN.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0004_KANBAN.ACTIVE.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0005_MINIBATTLES.ACTIVE.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0006_VAULT.IDEAS.txt") | Out-Null
        $lines.Add(" - AGILE\\HIA_AGL_0007_WARNINGS.ACTIVE.txt") | Out-Null
        $lines.Add("") | Out-Null
    }

    $lines.Add("SECTION: FILE_INDEX") | Out-Null
    $lines.Add("FIELDS: relpath | size | modified_utc | sha256") | Out-Null
    $lines.Add("") | Out-Null

    foreach ($r in $records) {
        $line = $r.RelPath + " | " + $r.Size + " | " + $r.ModifiedUtc + " | " + $r.Sha256
        $lines.Add($line) | Out-Null
    }

    $lines.Add("") | Out-Null
    $lines.Add("SECTION: CONTENT") | Out-Null
    $lines.Add("") | Out-Null

    foreach ($r in $records) {
        $lines.Add("======================================================================") | Out-Null
        $lines.Add("INICIO_ARCHIVO_INCLUIDO") | Out-Null
        $lines.Add("ARCHIVO: " + [System.IO.Path]::GetFileName($r.FullPath)) | Out-Null
        $lines.Add("RUTA_TARGET_REL: " + $r.RelPath) | Out-Null
        $lines.Add("RUTA_PROJECT_REL: " + (Get-RelativePathSafe -RootPath $ProjectRoot -FullPath $r.FullPath)) | Out-Null
        $lines.Add("SIZE: " + $r.Size) | Out-Null
        $lines.Add("MODIFIED_UTC: " + $r.ModifiedUtc) | Out-Null
        $lines.Add("SHA256: " + $r.Sha256) | Out-Null
        $lines.Add("======================================================================") | Out-Null
        $lines.Add("") | Out-Null

        $lines.Add((Get-FileTextSafe -Path $r.FullPath)) | Out-Null
        $lines.Add("") | Out-Null

        $lines.Add("======================================================================") | Out-Null
        $lines.Add("FIN_ARCHIVO_INCLUIDO") | Out-Null
        $lines.Add("ARCHIVO: " + [System.IO.Path]::GetFileName($r.FullPath)) | Out-Null
        $lines.Add("RUTA_TARGET_REL: " + $r.RelPath) | Out-Null
        $lines.Add("======================================================================") | Out-Null
        $lines.Add("") | Out-Null
    }

    $content = $lines -join "`r`n"
    [void](Write-SegmentedTextFile -ActivePath $OutFilePath -Content $content -MaxBytes $MaxBytes)
}

function Remove-LegacyDevOutputs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutDir
    )

    $legacy = @(
        "Radar.Human.txt",
        "Radar.Tools.txt",
        "Radar.05_Triggers.txt",
        "Radar.00_FRAMEWORK.txt",
        "Radar.04_PROJECTS.txt",
        "Radar.DragnDrop.txt",
        "Radar.DEV.Agile.ACTIVE.txt",
        "Radar.DEV.Full.ACTIVE.txt"
    )

    foreach ($name in $legacy) {
        $path = Join-Path $OutDir $name
        if ([System.IO.File]::Exists($path)) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

# ========================================================================
# 02.00_RESOLUCION_BASE
# ========================================================================

if (-not $ProjectRoot) {
    try {
        $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    }
    catch {
        throw "No se pudo resolver ProjectRoot desde PSScriptRoot. Error=" + $_.Exception.Message
    }
}

$ProjectRoot = Get-FullPathSafe -Path $ProjectRoot
$OutDir = Join-Path $ProjectRoot $OutDirRel

New-DirectoryIfMissing -Path $OutDir
Remove-LegacyDevOutputs -OutDir $OutDir

$TextExtSet       = Get-TextExtensionSet
$AllowlistNameSet = Get-HashAllowlistNameSet

$ExcludedContains = @(
    "\.git\",
    "\node_modules\",
    "\dist\",
    "\build\",
    "\__pycache__\",
    "\.venv\",
    "\.pytest_cache\",
    "\Raw\",
    "\DeadHistory\",
    "\03_ARTIFACTS\DeadHistory\",
    "\archive\",
    "\bin\",
    "\obj\"
)

Write-Host ("[RADAR.DEV] RUN_START ProjectRoot=" + $ProjectRoot)

$TargetTable = @{}
$TargetTable["HUMAN.README"] = @{ Root = (Join-Path $ProjectRoot "HUMAN.README"); Out = (Join-Path $OutDir "Radar.DEV.Human.ACTIVE.txt") }
$TargetTable["02_TOOLS"]     = @{ Root = (Join-Path $ProjectRoot "02_TOOLS");     Out = (Join-Path $OutDir "Radar.DEV.Tools.ACTIVE.txt") }
$TargetTable["05_Triggers"]  = @{ Root = (Join-Path $ProjectRoot "05_Triggers");  Out = (Join-Path $OutDir "Radar.DEV.Triggers.ACTIVE.txt") }
$TargetTable["00_FRAMEWORK"] = @{ Root = (Join-Path $ProjectRoot "00_FRAMEWORK"); Out = (Join-Path $OutDir "Radar.DEV.Framework.ACTIVE.txt") }
$TargetTable["04_PROJECTS"]  = @{ Root = (Join-Path $ProjectRoot "04_PROJECTS");  Out = (Join-Path $OutDir "Radar.DEV.Projects.ACTIVE.txt") }
$TargetTable["DragnDrop"]    = @{ Root = (Join-Path $ProjectRoot "DragnDrop");    Out = (Join-Path $OutDir "Radar.DEV.DragnDrop.ACTIVE.txt") }

$GeneratedDevOutputs = New-Object System.Collections.Generic.List[string]

foreach ($targetName in $Targets) {
    if (-not $TargetTable.ContainsKey($targetName)) {
        Write-Host ("[RADAR.DEV] WARN target_unknown=" + $targetName)
        continue
    }

    $target = $TargetTable[$targetName]
    $root   = $target.Root
    $out    = $target.Out

    Write-Host ("[RADAR.DEV] TARGET " + $targetName + " -> " + $out)

    try {
        Write-DevTargetOutput `
            -ProjectRoot $ProjectRoot `
            -TargetRoot $root `
            -OutFilePath $out `
            -Label $targetName `
            -ExcludedContains $ExcludedContains `
            -TextExtSet $TextExtSet `
            -AllowlistNameSet $AllowlistNameSet `
            -HashMode $HashMode `
            -MaxBytes $MaxOutputBytes

        $GeneratedDevOutputs.Add($out) | Out-Null
    }
    catch {
        Write-Host ("[RADAR.DEV] WARN target_failed=" + $targetName + " err=" + $_.Exception.Message)
        continue
    }
}

if ($IncludeFull) {
    $fullPath = Join-Path $OutDir "Radar.DEV.Full.ACTIVE.txt"

    $fullLines = New-Object System.Collections.Generic.List[string]
    $fullLines.Add("RADAR_DEV_FULL — HIA") | Out-Null
    $fullLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
    $fullLines.Add("MODE: DEV_ONLY") | Out-Null
    $fullLines.Add("") | Out-Null
    $fullLines.Add("GENERATED_OUTPUTS:") | Out-Null

    foreach ($p in $GeneratedDevOutputs) {
        $fullLines.Add(" - " + $p) | Out-Null
    }

    $fullLines.Add("") | Out-Null

    foreach ($p in $GeneratedDevOutputs) {
        $fullLines.Add("======================================================================") | Out-Null
        $fullLines.Add("INICIO_DEV_OUTPUT") | Out-Null
        $fullLines.Add("RUTA: " + $p) | Out-Null
        $fullLines.Add("======================================================================") | Out-Null
        $fullLines.Add("") | Out-Null

        $fullLines.Add((Get-FileTextSafe -Path $p)) | Out-Null
        $fullLines.Add("") | Out-Null

        $fullLines.Add("======================================================================") | Out-Null
        $fullLines.Add("FIN_DEV_OUTPUT") | Out-Null
        $fullLines.Add("RUTA: " + $p) | Out-Null
        $fullLines.Add("======================================================================") | Out-Null
        $fullLines.Add("") | Out-Null
    }

    $fullContent = $fullLines -join "`r`n"
    [void](Write-SegmentedTextFile -ActivePath $fullPath -Content $fullContent -MaxBytes $MaxOutputBytes)
    $GeneratedDevOutputs.Add($fullPath) | Out-Null
}

Write-Host "[RADAR.DEV] RUN_END OK"
Write-Host ("[RADAR.DEV] OUTPUTS: " + ($GeneratedDevOutputs -join "; "))
exit 0
