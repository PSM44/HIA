<#
========================================================================
00.00_METADATOS_DEL_SCRIPT
========================================================================

ID_UNICO..........: HIA.TOOL.RADAR.0001
NOMBRE_SUGERIDO...: RADAR.ps1
VERSION...........: v3.1-DRAFT
FECHA.............: 2026-03-10
HORA..............: HH:MM (America/Santiago)
CIUDAD............: Santiago, Chile
UBICACION_SISTEMA.: C:\01. GitHub\Wings3.0\01_PROJECTS\HIA\02_TOOLS\RADAR.ps1
AUTOR_HUMANO......: PABLO (ADMIN)
AUTOR_IA..........: GPT-5.4 Thinking

OBJETIVO
- Generar el RADAR canónico de HIA.
- Producir solamente:
  1) Radar.Index.ACTIVE.txt
  2) Radar.Core.ACTIVE.txt
  3) Radar.Lite.ACTIVE.txt
- No generar FULL canónico.
- No truncar contenido fuente en CORE.
- No usar Get-ChildItem -Recurse.

COMO_EJECUTAR
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1
pwsh -NoProfile -File .\02_TOOLS\RADAR.ps1 -RootPath "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"

NOTAS DURAS
- RADAR.ps1 = runner canónico.
- RADAR.DEV.ps1 = laboratorio.
- Este script observa y copia. No corrige, no decide y no aplica cambios.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RootPath = $null,

    [Parameter(Mandatory = $false)]
    [string]$RadarOutDirRel = "03_ARTIFACTS\RADAR",

    [Parameter(Mandatory = $false)]
    [ValidateSet("None", "Text", "All")]
    [string]$HashMode = "Text",

    [Parameter(Mandatory = $false)]
    [long]$MaxOutputBytes = 8388608
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ========================================================================
# 01.00_FUNCIONES_BASE
# ========================================================================

function Get-RunStamp {
    return (Get-Date -Format "yyyyMMdd_HHmmss")
}

function New-DirectoryIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not [System.IO.Directory]::Exists($Path)) {
        [void][System.IO.Directory]::CreateDirectory($Path)
    }
}

function Get-FullPathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path)
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $root = (Get-FullPathSafe -Path $RootPath).TrimEnd('\')
    $full = Get-FullPathSafe -Path $FullPath

    if ($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring($root.Length).TrimStart('\')
    }

    return $full
}

function Get-Sha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

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
        ".ps1",".psm1",".psd1",
        ".py",".js",".ts",".tsx",".jsx",".java",".cs",".go",".rs",".rb",".php",".sh",".bat",".cmd",
        ".sql",".csv"
    ) | ForEach-Object { [void]$set.Add($_) }

    return $set
}

function Get-HashAllowlistNameSet {
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    @(
        ".gitignore",
        ".gitattributes",
        ".editorconfig",
        ".npmrc",
        ".yarnrc",
        ".prettierrc",
        ".eslintrc"
    ) | ForEach-Object { [void]$set.Add($_) }

    return $set
}

function Get-CoreIncludeRootSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $roots = New-Object System.Collections.Generic.List[string]

    $candidateRelPaths = @(
        "HUMAN.README",
        "02_TOOLS",
        "BATON",
        "BACKLOG",
        "BACKLOGS",
        "SKILLS",
        "00_FRAMEWORK\BATON",
        "00_FRAMEWORK\BACKLOG",
        "00_FRAMEWORK\BACKLOGS"
    )

    foreach ($rel in $candidateRelPaths) {
        $full = Join-Path $ProjectRoot $rel

        if ([System.IO.Directory]::Exists($full)) {
            $roots.Add((Get-FullPathSafe -Path $full)) | Out-Null
        }
        elseif ([System.IO.File]::Exists($full)) {
            $roots.Add((Get-FullPathSafe -Path $full)) | Out-Null
        }
    }

    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $final = New-Object System.Collections.Generic.List[string]

    foreach ($r in $roots) {
        if ($seen.Add($r)) {
            $final.Add($r) | Out-Null
        }
    }

    return $final
}

function Test-ExcludedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath,
        [Parameter(Mandatory = $true)]
        [string[]]$ExcludedContains
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
        [Parameter(Mandatory = $true)]
        [string]$FullPath,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$AllowlistNameSet
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

function Get-LogicalType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$AllowlistNameSet
    )

    if (Test-TextEligiblePath -FullPath $FullPath -TextExtSet $TextExtSet -AllowlistNameSet $AllowlistNameSet) {
        return "text"
    }

    $ext = [System.IO.Path]::GetExtension($FullPath)
    if ([string]::IsNullOrWhiteSpace($ext)) {
        return "no_ext"
    }

    $binaryLike = @(".exe",".dll",".png",".jpg",".jpeg",".webp",".gif",".pdf",".xlsx",".xls",".pptx",".docx",".zip",".7z",".rar",".bin")
    if ($binaryLike -contains $ext.ToLowerInvariant()) {
        return "binary"
    }

    return "other"
}

function Convert-BytesToText {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($Bytes, 3, $Bytes.Length - 3)
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($Bytes, 2, $Bytes.Length - 2)
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString($Bytes, 2, $Bytes.Length - 2)
    }
    if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE -and $Bytes[2] -eq 0x00 -and $Bytes[3] -eq 0x00) {
        return [System.Text.Encoding]::UTF32.GetString($Bytes, 4, $Bytes.Length - 4)
    }

    try {
        return [System.Text.Encoding]::UTF8.GetString($Bytes)
    }
    catch {
        return [System.Text.Encoding]::Default.GetString($Bytes)
    }
}

function Get-FileTextSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        return Convert-BytesToText -Bytes $bytes
    }
    catch {
        return "[READ_FAIL: " + $_.Exception.Message + "]"
    }
}

function Get-FileEntryListDeterministic {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$ExcludedContains,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$TextExtSet,
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.HashSet[string]]$AllowlistNameSet,
        [Parameter(Mandatory = $true)]
        [string]$HashMode
    )

    $options = New-Object System.IO.EnumerationOptions
    $options.RecurseSubdirectories = $true
    $options.IgnoreInaccessible = $true
    $options.ReturnSpecialDirectories = $false
    $options.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint

    $records = New-Object System.Collections.Generic.List[object]

    foreach ($full in [System.IO.Directory]::EnumerateFiles($ProjectRoot, "*", $options)) {
        if (Test-ExcludedPath -FullPath $full -ExcludedContains $ExcludedContains) {
            continue
        }

        $info = [System.IO.FileInfo]::new($full)
        $rel  = Get-RelativePathSafe -RootPath $ProjectRoot -FullPath $full
        $ext  = $info.Extension.ToLowerInvariant()
        $type = Get-LogicalType -FullPath $full -TextExtSet $TextExtSet -AllowlistNameSet $AllowlistNameSet

        $sha = ""
        if ($HashMode -eq "All") {
            $sha = Get-Sha256Hex -Path $full
        }
        elseif ($HashMode -eq "Text" -and $type -eq "text") {
            $sha = Get-Sha256Hex -Path $full
        }

        $records.Add([pscustomobject]@{
            RelPath     = $rel
            FullPath    = $full
            Ext         = $ext
            Type        = $type
            Size        = [int64]$info.Length
            ModifiedUtc = $info.LastWriteTimeUtc.ToString("o")
            Sha256      = $sha
        }) | Out-Null
    }

    return @($records.ToArray() | Sort-Object -Property RelPath)
}

function Write-SegmentedTextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActivePath,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [long]$MaxBytes
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

function Move-ActiveFileToArchiveIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$ArchiveDir,
        [Parameter(Mandatory = $true)]
        [string]$RunStamp
    )

    if (-not [System.IO.File]::Exists($Path)) {
        return
    }

    New-DirectoryIfMissing -Path $ArchiveDir

    $name = [System.IO.Path]::GetFileName($Path)
    $archivedName = $name.Replace(".ACTIVE", "." + $RunStamp)
    $target = Join-Path $ArchiveDir $archivedName
    [System.IO.File]::Move($Path, $target)
}

function Remove-LegacyRadarOutputs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RadarDir
    )

    $legacy = @(
        "HIA_RAD_INDEX.ALL.ACTIVE.txt",
        "HIA_RAD_0004_FULL.FULL.ACTIVE.txt",
        "HIA_RAD_INDEX.REPO.ACTIVE.txt",
        "HIA_RAD_0003_CORE.ACTIVE.txt",
        "HIA_RAD_0001_LITE.ACTIVE.txt"
    )

    foreach ($name in $legacy) {
        $path = Join-Path $RadarDir $name
        if ([System.IO.File]::Exists($path)) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Get-IndexMapFromFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $map = @{}

    if (-not [System.IO.File]::Exists($Path)) {
        return $map
    }

    $lines = [System.IO.File]::ReadAllLines($Path)
    foreach ($rawLine in $lines) {
        $line = $rawLine.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.StartsWith("RADAR_INDEX")) { continue }
        if ($line.StartsWith("STAMP_UTC:")) { continue }
        if ($line.StartsWith("ROOT:")) { continue }
        if ($line.StartsWith("HASH_MODE:")) { continue }
        if ($line.StartsWith("EXCLUDED_CONTAINS:")) { continue }
        if ($line.StartsWith("FILES_COUNT:")) { continue }
        if ($line.StartsWith("FIELDS:")) { continue }
        if ($line -notmatch '\|') { continue }

        $parts = $line.Split('|') | ForEach-Object { $_.Trim() }
        if ($parts.Count -lt 6) { continue }

        $rel = $parts[0]
        $map[$rel] = [pscustomobject]@{
            RelPath     = $parts[0]
            Type        = $parts[1]
            Ext         = $parts[2]
            Size        = $parts[3]
            ModifiedUtc = $parts[4]
            Sha256      = $parts[5]
        }
    }

    return $map
}

# ========================================================================
# 02.00_RESOLUCION_DE_ROOT_Y_PATHS
# ========================================================================

if (-not $RootPath) {
    try {
        $RootPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    }
    catch {
        throw "No se pudo resolver RootPath desde PSScriptRoot. Error=" + $_.Exception.Message
    }
}

$RootPath = Get-FullPathSafe -Path $RootPath

if ($RootPath -match '<PROJECT_ROOT>' -or $RootPath -match '^\s*<.*>\s*$') {
    throw "RootPath contiene placeholder inválido. Debe ser una ruta real del proyecto."
}

$RadarDir = Join-Path $RootPath $RadarOutDirRel
$OldDir   = Join-Path $RadarDir "old"
$RunStamp = Get-RunStamp

New-DirectoryIfMissing -Path $RadarDir
New-DirectoryIfMissing -Path $OldDir

$LiteActive  = Join-Path $RadarDir "Radar.Lite.ACTIVE.txt"
$IndexActive = Join-Path $RadarDir "Radar.Index.ACTIVE.txt"
$CoreActive  = Join-Path $RadarDir "Radar.Core.ACTIVE.txt"

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
    "\03_ARTIFACTS\",
    "\Raw\",
    "\DeadHistory\",
    "\archive\",
    "\DnD\",
    "\bin\",
    "\obj\"
)

$CoreIncludeRoots = Get-CoreIncludeRootSet -ProjectRoot $RootPath

# ========================================================================
# 03.00_ROTACION_Y_LIMPIEZA
# ========================================================================

$BaselineIndexPath = $null
if ([System.IO.File]::Exists($IndexActive)) {
    $BaselineIndexPath = Join-Path $OldDir ("Radar.Index.BASELINE." + $RunStamp + ".txt")
    [System.IO.File]::Copy($IndexActive, $BaselineIndexPath, $true)
}

$OldRunDir = Join-Path $OldDir $RunStamp
New-DirectoryIfMissing -Path $OldRunDir

Move-ActiveFileToArchiveIfExists -Path $LiteActive  -ArchiveDir $OldRunDir -RunStamp $RunStamp
Move-ActiveFileToArchiveIfExists -Path $IndexActive -ArchiveDir $OldRunDir -RunStamp $RunStamp
Move-ActiveFileToArchiveIfExists -Path $CoreActive  -ArchiveDir $OldRunDir -RunStamp $RunStamp

Remove-LegacyRadarOutputs -RadarDir $RadarDir

# ========================================================================
# 04.00_ENUMERACION_DETERMINISTA
# ========================================================================

$Records = Get-FileEntryListDeterministic `
    -ProjectRoot $RootPath `
    -ExcludedContains $ExcludedContains `
    -TextExtSet $TextExtSet `
    -AllowlistNameSet $AllowlistNameSet `
    -HashMode $HashMode

# ========================================================================
# 05.00_INDEX
# ========================================================================

$IndexLines = New-Object System.Collections.Generic.List[string]
$IndexLines.Add("RADAR_INDEX — HIA") | Out-Null
$IndexLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$IndexLines.Add("ROOT: " + $RootPath) | Out-Null
$IndexLines.Add("HASH_MODE: " + $HashMode) | Out-Null
$IndexLines.Add("EXCLUDED_CONTAINS: " + ($ExcludedContains -join " | ")) | Out-Null
$IndexLines.Add("FILES_COUNT: " + $Records.Count) | Out-Null
$IndexLines.Add("") | Out-Null
$IndexLines.Add("FIELDS: relpath | type | ext | size | modified_utc | sha256") | Out-Null
$IndexLines.Add("") | Out-Null

foreach ($r in $Records) {
    $IndexLines.Add($r.RelPath + " | " + $r.Type + " | " + $r.Ext + " | " + $r.Size + " | " + $r.ModifiedUtc + " | " + $r.Sha256) | Out-Null
}

$IndexContent = $IndexLines -join "`r`n"
[void](Write-SegmentedTextFile -ActivePath $IndexActive -Content $IndexContent -MaxBytes $MaxOutputBytes)

# ========================================================================
# 06.00_CORE
# ========================================================================

$CoreLines = New-Object System.Collections.Generic.List[string]
$CoreLines.Add("RADAR_CORE — HIA") | Out-Null
$CoreLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$CoreLines.Add("ROOT: " + $RootPath) | Out-Null
$CoreLines.Add("POLICY: HUMAN.README + 02_TOOLS + BATON/BACKLOG/SKILLS if present") | Out-Null
$CoreLines.Add("EXCLUDED_CONTAINS: " + ($ExcludedContains -join " | ")) | Out-Null
$CoreLines.Add("") | Out-Null

foreach ($r in $Records) {
    if ($r.Type -ne "text") {
        continue
    }

    $includedByPolicy = $false
    foreach ($root in $CoreIncludeRoots) {
        if ($r.FullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
            $includedByPolicy = $true
            break
        }
        if ($r.FullPath.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
            $includedByPolicy = $true
            break
        }
    }

    if (-not $includedByPolicy) {
        continue
    }

    $CoreLines.Add("======================================================================") | Out-Null
    $CoreLines.Add("INICIO_ARCHIVO_INCLUIDO") | Out-Null
    $CoreLines.Add("ARCHIVO: " + [System.IO.Path]::GetFileName($r.FullPath)) | Out-Null
    $CoreLines.Add("RUTA: " + $r.RelPath) | Out-Null
    $CoreLines.Add("SIZE: " + $r.Size) | Out-Null
    $CoreLines.Add("MODIFIED_UTC: " + $r.ModifiedUtc) | Out-Null
    $CoreLines.Add("SHA256: " + $r.Sha256) | Out-Null
    $CoreLines.Add("======================================================================") | Out-Null
    $CoreLines.Add("") | Out-Null

    $CoreLines.Add((Get-FileTextSafe -Path $r.FullPath)) | Out-Null
    $CoreLines.Add("") | Out-Null

    $CoreLines.Add("======================================================================") | Out-Null
    $CoreLines.Add("FIN_ARCHIVO_INCLUIDO") | Out-Null
    $CoreLines.Add("ARCHIVO: " + [System.IO.Path]::GetFileName($r.FullPath)) | Out-Null
    $CoreLines.Add("RUTA: " + $r.RelPath) | Out-Null
    $CoreLines.Add("======================================================================") | Out-Null
    $CoreLines.Add("") | Out-Null
}

$CoreContent = $CoreLines -join "`r`n"
[void](Write-SegmentedTextFile -ActivePath $CoreActive -Content $CoreContent -MaxBytes $MaxOutputBytes)

# ========================================================================
# 07.00_LITE
# ========================================================================

$NewMap  = Get-IndexMapFromFile -Path $IndexActive
$BaseMap = @{}
if ($BaselineIndexPath) {
    $BaseMap = Get-IndexMapFromFile -Path $BaselineIndexPath
}

$LiteLines = New-Object System.Collections.Generic.List[string]
$LiteLines.Add("RADAR_LITE — HIA") | Out-Null
$LiteLines.Add("STAMP_UTC: " + (Get-Date).ToUniversalTime().ToString("o")) | Out-Null
$LiteLines.Add("ROOT: " + $RootPath) | Out-Null
$LiteLines.Add("BASELINE_INDEX: " + $(if ($BaselineIndexPath) { $BaselineIndexPath } else { "[NONE]" })) | Out-Null
$LiteLines.Add("NEW_INDEX: " + $IndexActive) | Out-Null
$LiteLines.Add("") | Out-Null

if (-not $BaselineIndexPath) {
    $LiteLines.Add("NO_BASELINE: primera ejecución o baseline no disponible.") | Out-Null
    $LiteLines.Add("NEW_FILES_COUNT: " + $NewMap.Count) | Out-Null
    $LiteLines.Add("") | Out-Null
    $LiteLines.Add("NEW_FILES:") | Out-Null

    foreach ($k in ($NewMap.Keys | Sort-Object)) {
        $LiteLines.Add(" + " + $k) | Out-Null
    }
}
else {
    $Created = New-Object System.Collections.Generic.List[string]
    $Deleted = New-Object System.Collections.Generic.List[string]
    $Edited  = New-Object System.Collections.Generic.List[string]
    $Moved   = New-Object System.Collections.Generic.List[string]

    $BaseHash = @{}
    foreach ($k in $BaseMap.Keys) {
        $h = $BaseMap[$k].Sha256
        if ([string]::IsNullOrWhiteSpace($h)) { continue }
        if (-not $BaseHash.ContainsKey($h)) {
            $BaseHash[$h] = New-Object System.Collections.Generic.List[string]
        }
        $BaseHash[$h].Add($k) | Out-Null
    }

    $NewHash = @{}
    foreach ($k in $NewMap.Keys) {
        $h = $NewMap[$k].Sha256
        if ([string]::IsNullOrWhiteSpace($h)) { continue }
        if (-not $NewHash.ContainsKey($h)) {
            $NewHash[$h] = New-Object System.Collections.Generic.List[string]
        }
        $NewHash[$h].Add($k) | Out-Null
    }

    foreach ($k in $NewMap.Keys) {
        if (-not $BaseMap.ContainsKey($k)) {
            $Created.Add($k) | Out-Null
            continue
        }

        $b = $BaseMap[$k]
        $n = $NewMap[$k]

        if (-not [string]::IsNullOrWhiteSpace($n.Sha256) -and -not [string]::IsNullOrWhiteSpace($b.Sha256)) {
            if ($n.Sha256 -ne $b.Sha256) {
                $Edited.Add($k) | Out-Null
            }
        }
        elseif (($n.Size -ne $b.Size) -or ($n.ModifiedUtc -ne $b.ModifiedUtc)) {
            $Edited.Add($k) | Out-Null
        }
    }

    foreach ($k in $BaseMap.Keys) {
        if (-not $NewMap.ContainsKey($k)) {
            $Deleted.Add($k) | Out-Null
        }
    }

    foreach ($h in $BaseHash.Keys) {
        if (-not $NewHash.ContainsKey($h)) { continue }

        foreach ($from in $BaseHash[$h]) {
            foreach ($to in $NewHash[$h]) {
                if ($from -ne $to -and ($Deleted -contains $from) -and ($Created -contains $to)) {
                    $Moved.Add($from + " -> " + $to) | Out-Null
                }
            }
        }
    }

    foreach ($mv in @($Moved)) {
        $pair = $mv.Split('->') | ForEach-Object { $_.Trim() }
        if ($pair.Count -eq 2) {
            [void]$Deleted.Remove($pair[0])
            [void]$Created.Remove($pair[1])
        }
    }

    $LiteLines.Add("CREATED_FILES_COUNT: " + $Created.Count) | Out-Null
    $LiteLines.Add("EDITED_FILES_COUNT: " + $Edited.Count) | Out-Null
    $LiteLines.Add("DELETED_FILES_COUNT: " + $Deleted.Count) | Out-Null
    $LiteLines.Add("MOVED_FILES_COUNT: " + $Moved.Count) | Out-Null
    $LiteLines.Add("") | Out-Null

    $LiteLines.Add("CREATED_FILES:") | Out-Null
    foreach ($x in ($Created | Sort-Object)) { $LiteLines.Add(" + " + $x) | Out-Null }
    $LiteLines.Add("") | Out-Null

    $LiteLines.Add("EDITED_FILES:") | Out-Null
    foreach ($x in ($Edited | Sort-Object)) { $LiteLines.Add(" ~ " + $x) | Out-Null }
    $LiteLines.Add("") | Out-Null

    $LiteLines.Add("DELETED_FILES:") | Out-Null
    foreach ($x in ($Deleted | Sort-Object)) { $LiteLines.Add(" - " + $x) | Out-Null }
    $LiteLines.Add("") | Out-Null

    $LiteLines.Add("MOVED_FILES:") | Out-Null
    foreach ($x in ($Moved | Sort-Object)) { $LiteLines.Add(" > " + $x) | Out-Null }
}

$LiteContent = $LiteLines -join "`r`n"
[void](Write-SegmentedTextFile -ActivePath $LiteActive -Content $LiteContent -MaxBytes $MaxOutputBytes)

# ========================================================================
# 08.00_SALIDA_FINAL
# ========================================================================

Write-Host "OK: RADAR HIA generado correctamente."
Write-Host ("OUTPUTS: " + $LiteActive + "; " + $IndexActive + "; " + $CoreActive)
exit 0