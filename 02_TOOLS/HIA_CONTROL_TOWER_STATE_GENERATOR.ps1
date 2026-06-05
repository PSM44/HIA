param(
    [string]$ProjectId = "PRJ_0001_HIA.PRODUCT",
    [string]$RepoRoot = (Get-Location).Path,
    [string]$OutputPath = "01_UI/web/control-tower-shell/assets/hia.state.js",
    [switch]$Write,
    [switch]$Refresh,
    [switch]$ForceRefresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-JsString {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return "" }
    return (($Value -replace "\\", "\\") -replace '"', '\"')
}

function Get-LineValue {
    param(
        [string[]]$Lines,
        [string]$Prefix
    )

    $line = $Lines | Where-Object { $_ -like "$Prefix*" } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($line)) { return "N/A" }
    return ($line -replace ("^" + [regex]::Escape($Prefix) + "\s*"), "").Trim()
}

function Get-FileBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    return (Get-Item -LiteralPath $Path).Length
}

function Get-CurrentStatePayload {
    param([string]$Path)

    $result = [ordered]@{
        status = "MISSING"
        warning = "CURRENT_STATE missing"
        payload = $null
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $result
    }

    try {
        $payload = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $result.status = "INVALID"
        $result.warning = "CURRENT_STATE invalid JSON"
        return $result
    }

    if ([string]$payload.schema -ne "HIA_CURRENT_STATE.v1") {
        $result.status = "INVALID"
        $result.warning = "CURRENT_STATE schema mismatch"
        return $result
    }

    if ([string]::IsNullOrWhiteSpace([string]$payload.project_id) -or [string]$payload.project_id -ne $ProjectId) {
        $result.status = "INVALID"
        $result.warning = "CURRENT_STATE project_id mismatch"
        return $result
    }

    if ([string]::IsNullOrWhiteSpace([string]$payload.next_action.id) -or [string]::IsNullOrWhiteSpace([string]$payload.next_action.raw)) {
        $result.status = "INVALID"
        $result.warning = "CURRENT_STATE next_action incomplete"
        return $result
    }

    $result.status = "VALID"
    $result.warning = "N/A"
    $result.payload = $payload
    return $result
}

function Get-WriteMode {
    if ($ForceRefresh.IsPresent) { return "FORCE_REFRESH" }
    if ($Write.IsPresent -or $Refresh.IsPresent) { return "WRITE" }
    return "CHECK"
}

function New-SemanticPayload {
    param(
        [string]$ProjectIdValue,
        [string]$ProjectRootRelative,
        [string]$CurrentStateRelative,
        [string]$NextAction,
        [string]$ResumeRecommendation,
        [string]$EvidenceState,
        [string]$EvidenceConsistency,
        [string]$SessionStatus,
        [string]$ResolverStatus,
        [string]$ContinuitySource,
        [string]$CurrentStateStatus,
        [string]$FallbackWarning,
        [string]$Branch,
        [string]$Minibattle
    )

    # Semantic fields drive writes. Volatile fields such as timestamps, git head
    # capture, and live RADAR byte counts are intentionally excluded so default
    # check mode and repeated write runs do not dirty the repo on no-op refreshes.
    return [ordered]@{
        project = [ordered]@{
            id = $ProjectIdValue
            root_wsl = "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA"
            root_win = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
            branch = $Branch
        }
        continuity = [ordered]@{
            next_action = $NextAction
            resume_recommendation = $ResumeRecommendation
            evidence_state = $EvidenceState
            evidence_consistency = $EvidenceConsistency
            session_status = $SessionStatus
            resolver_status = $ResolverStatus
            source = $ContinuitySource
            current_state_source = $ContinuitySource
            current_state_status = $CurrentStateStatus
            current_state_path = $CurrentStateRelative
            fallback_warning = $FallbackWarning
        }
        ui = [ordered]@{
            shell_file = "01_UI/web/control-tower-shell/index.html"
            state_file = "01_UI/web/control-tower-shell/assets/hia.state.js"
            generator_file = "02_TOOLS/HIA_CONTROL_TOWER_STATE_GENERATOR.ps1"
            mode = "read-only generated snapshot"
            minibattle = $Minibattle
        }
        warnings = @(
            "Este estado es snapshot visible read-only; no reemplaza CURRENT_STATE, BATON, BACKLOG ni RADAR.",
            "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
            "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto mientras exista fallback heuristico."
        )
    }
}

function Get-ExistingSemanticPayload {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    try {
        $lines = @(Get-Content -LiteralPath $Path -ErrorAction Stop)
    }
    catch {
        return $null
    }

    $values = @{
        project_id = Get-LineValue -Lines $lines -Prefix '    id:'
        branch = Get-LineValue -Lines $lines -Prefix '    branch:'
        next_action = Get-LineValue -Lines $lines -Prefix '    next_action:'
        resume_recommendation = Get-LineValue -Lines $lines -Prefix '    resume_recommendation:'
        evidence_state = Get-LineValue -Lines $lines -Prefix '    evidence_state:'
        evidence_consistency = Get-LineValue -Lines $lines -Prefix '    evidence_consistency:'
        session_status = Get-LineValue -Lines $lines -Prefix '    session_status:'
        resolver_status = Get-LineValue -Lines $lines -Prefix '    resolver_status:'
        source = Get-LineValue -Lines $lines -Prefix '    source:'
        current_state_source = Get-LineValue -Lines $lines -Prefix '    current_state_source:'
        current_state_status = Get-LineValue -Lines $lines -Prefix '    current_state_status:'
        current_state_path = Get-LineValue -Lines $lines -Prefix '    current_state_path:'
        fallback_warning = Get-LineValue -Lines $lines -Prefix '    fallback_warning:'
        generator_file = Get-LineValue -Lines $lines -Prefix '    generator_file:'
        minibattle = Get-LineValue -Lines $lines -Prefix '    minibattle:'
    }

    foreach ($key in @($values.Keys)) {
        $text = [string]$values[$key]
        $text = $text.Trim().TrimEnd(",")
        if ($text.StartsWith('"') -and $text.EndsWith('"')) {
            $text = $text.Substring(1, $text.Length - 2)
        }
        $values[$key] = $text
    }

    $warnings = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $trimmed = ([string]$line).Trim()
        if ($trimmed.StartsWith('"Este estado') -or $trimmed.StartsWith('"Si hay conflicto') -or $trimmed.StartsWith('"TD_BATON')) {
            $text = $trimmed.TrimEnd(",")
            if ($text.StartsWith('"') -and $text.EndsWith('"')) {
                $text = $text.Substring(1, $text.Length - 2)
            }
            $warnings.Add($text) | Out-Null
        }
    }

    return [ordered]@{
        project = [ordered]@{
            id = $values.project_id
            root_wsl = "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA"
            root_win = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
            branch = $values.branch
        }
        continuity = [ordered]@{
            next_action = $values.next_action
            resume_recommendation = $values.resume_recommendation
            evidence_state = $values.evidence_state
            evidence_consistency = $values.evidence_consistency
            session_status = $values.session_status
            resolver_status = $values.resolver_status
            source = $values.source
            current_state_source = $values.current_state_source
            current_state_status = $values.current_state_status
            current_state_path = $values.current_state_path
            fallback_warning = $values.fallback_warning
        }
        ui = [ordered]@{
            shell_file = "01_UI/web/control-tower-shell/index.html"
            state_file = "01_UI/web/control-tower-shell/assets/hia.state.js"
            generator_file = $values.generator_file
            mode = "read-only generated snapshot"
            minibattle = $values.minibattle
        }
        warnings = @($warnings)
    }
}

function Convert-SemanticPayloadToJson {
    param($Payload)
    return ($Payload | ConvertTo-Json -Depth 8 -Compress)
}

function Get-StringSha256 {
    param([string]$Value)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return ([System.BitConverter]::ToString($hashBytes)).Replace("-", "")
}

function Get-ExistingSemanticHash {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ""
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    }
    catch {
        return ""
    }

    $match = [regex]::Match($raw, 'SEMANTIC_HASH\.*:\s*(?<value>[A-Fa-f0-9]+)')
    if ($match.Success) {
        return $match.Groups['value'].Value.ToUpperInvariant()
    }

    return ""
}

Push-Location $RepoRoot
try {
    $writeMode = Get-WriteMode
    $generatedLocal = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
    $generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    $branch = (& git branch --show-current).Trim()
    $headShort = (& git rev-parse --short HEAD).Trim()
    $headMessage = (& git log -1 --pretty=%s).Trim()

    $projectRootRelative = "04_PROJECTS/$ProjectId"
    $currentStateRelative = "$projectRootRelative/STATE/CURRENT_STATE.json"
    $currentStatePath = Join-Path $RepoRoot $currentStateRelative
    $hia = Join-Path $RepoRoot "01_UI/terminal/hia.ps1"

    if (-not (Test-Path -LiteralPath $hia)) {
        throw "Missing HIA CLI: $hia"
    }

    $stateInfo = Get-CurrentStatePayload -Path $currentStatePath
    $fallbackUsed = $false
    $fallbackWarning = "N/A"

    if ($stateInfo.status -eq "VALID") {
        $payload = $stateInfo.payload
        $nextAction = [string]$payload.next_action.raw
        $resumeRecommendation = [string]$payload.next_action.raw
        $evidenceState = [string]$payload.evidence.state
        $evidenceConsistency = [string]$payload.evidence.consistency
        $sessionStatus = [string]$payload.session.status
        $minibattle = [string]$payload.next_action.id
        $continuitySource = "CURRENT_STATE"
        $resolverStatus = "CURRENT_STATE_PRIMARY"
    }
    else {
        $fallbackUsed = $true
        $fallbackWarning = [string]$stateInfo.warning

        $continueOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$RepoRoot'; .\01_UI\terminal\hia.ps1 project continue $ProjectId"
        $statusOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$RepoRoot'; .\01_UI\terminal\hia.ps1 project status $ProjectId"

        $continueLines = @($continueOut | ForEach-Object { [string]$_ })
        $statusLines = @($statusOut | ForEach-Object { [string]$_ })

        $nextAction = Get-LineValue -Lines $continueLines -Prefix "NEXT_ACTION:"
        $resumeRecommendation = Get-LineValue -Lines $continueLines -Prefix "RESUME_RECOMMENDATION:"
        $evidenceState = Get-LineValue -Lines $continueLines -Prefix "EVIDENCE_STATE:"
        $evidenceConsistency = Get-LineValue -Lines $continueLines -Prefix "EVIDENCE_CONSISTENCY:"
        $sessionStatus = Get-LineValue -Lines $statusLines -Prefix "LAST_SESSION_STATUS:"
        $continuitySource = "FALLBACK_CLI"
        $resolverStatus = "CURRENT_STATE_FALLBACK_TO_CLI"
        $minibattle = "N/A"
        if ($nextAction -match '(PRJPB_[A-Za-z0-9_\-]+)') {
            $minibattle = $Matches[1]
        }
    }

    $semanticPayload = New-SemanticPayload `
        -ProjectIdValue $ProjectId `
        -ProjectRootRelative $projectRootRelative `
        -CurrentStateRelative $currentStateRelative `
        -NextAction $nextAction `
        -ResumeRecommendation $resumeRecommendation `
        -EvidenceState $evidenceState `
        -EvidenceConsistency $evidenceConsistency `
        -SessionStatus $sessionStatus `
        -ResolverStatus $resolverStatus `
        -ContinuitySource $continuitySource `
        -CurrentStateStatus $stateInfo.status `
        -FallbackWarning $fallbackWarning `
        -Branch $branch `
        -Minibattle $minibattle

    $intendedSemanticJson = Convert-SemanticPayloadToJson -Payload $semanticPayload
    $intendedSemanticHash = Get-StringSha256 -Value $intendedSemanticJson
    $existingSemanticHash = Get-ExistingSemanticHash -Path $OutputPath
    $semanticChanged = ($intendedSemanticHash -ne $existingSemanticHash)
    $wouldWrite = $semanticChanged -or $ForceRefresh.IsPresent
    $wroteFile = $false
    $noWriteNeeded = $false

    if ($writeMode -eq "CHECK") {
        $noWriteNeeded = (-not $wouldWrite)
    }
    else {
        if ($wouldWrite) {
            $radarLite = "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt"
            $radarIndex = "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt"
            $radarCore = "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt"

            $outDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path -LiteralPath $outDir)) {
                New-Item -ItemType Directory -Path $outDir -Force | Out-Null
            }

            $warningList = @($semanticPayload.warnings)
            if ($fallbackUsed) {
                $warningList += ("FALLBACK_ACTIVE: {0}" -f $fallbackWarning)
            }

            $js = @"
// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009Q_CURRENT_STATE_PRIMARY_CONTROL_TOWER_GENERATOR
// GENERATED_AT......: $generatedLocal
// GENERATED_UTC.....: $generatedUtc
// SEMANTIC_HASH.....: $intendedSemanticHash
// SOURCE............: CURRENT_STATE primary with CLI fallback
// MODE..............: READ_ONLY_SNAPSHOT
// WRITE_MODE........: $writeMode
// DO_NOT_USE_AS_CANON: YES
// ==============================================

window.HIA_REAL_STATE = Object.freeze({
  project: Object.freeze({
    id: "$(ConvertTo-JsString $ProjectId)",
    root_wsl: "/mnt/c/01. GitHub/Wings3.0/01_PROJECTS/HIA",
    root_win: "C:\\01. GitHub\\Wings3.0\\01_PROJECTS\\HIA",
    branch: "$(ConvertTo-JsString $branch)",
    generated_from_head_before_commit: "$(ConvertTo-JsString $headShort)",
    generated_from_head_message_before_commit: "$(ConvertTo-JsString $headMessage)"
  }),
  continuity: Object.freeze({
    next_action: "$(ConvertTo-JsString $nextAction)",
    resume_recommendation: "$(ConvertTo-JsString $resumeRecommendation)",
    evidence_state: "$(ConvertTo-JsString $evidenceState)",
    evidence_consistency: "$(ConvertTo-JsString $evidenceConsistency)",
    session_status: "$(ConvertTo-JsString $sessionStatus)",
    generated_local: "$(ConvertTo-JsString $generatedLocal)",
    generated_utc: "$(ConvertTo-JsString $generatedUtc)",
    resolver_status: "$(ConvertTo-JsString $resolverStatus)",
    source: "$(ConvertTo-JsString $continuitySource)",
    current_state_source: "$(ConvertTo-JsString $continuitySource)",
    current_state_status: "$(ConvertTo-JsString $stateInfo.status)",
    current_state_path: "$(ConvertTo-JsString $currentStateRelative)",
    fallback_warning: "$(ConvertTo-JsString $fallbackWarning)"
  }),
  radar: Object.freeze({
    lite_path: "$radarLite",
    lite_bytes: $(Get-FileBytes $radarLite),
    index_path: "$radarIndex",
    index_bytes: $(Get-FileBytes $radarIndex),
    core_path: "$radarCore",
    core_bytes: $(Get-FileBytes $radarCore)
  }),
  ui: Object.freeze({
    shell_file: "01_UI/web/control-tower-shell/index.html",
    state_file: "$(ConvertTo-JsString $OutputPath)",
    generator_file: "02_TOOLS/HIA_CONTROL_TOWER_STATE_GENERATOR.ps1",
    mode: "read-only generated snapshot",
    minibattle: "$(ConvertTo-JsString $minibattle)"
  }),
  warnings: Object.freeze([
    "$(($warningList | ForEach-Object { ConvertTo-JsString $_ }) -join '",' + "`n    `"")"
  ])
});
"@

            $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
            [System.IO.File]::WriteAllText((Join-Path $RepoRoot $OutputPath), $js, $utf8NoBom)
            $wroteFile = $true
        }
        else {
            $noWriteNeeded = $true
        }
    }

    Write-Host ("OUTPUT_PATH: {0}" -f $OutputPath)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("CURRENT_STATE_STATUS: {0}" -f $stateInfo.status)
    Write-Host ("CURRENT_STATE_SOURCE: {0}" -f $continuitySource)
    Write-Host ("WRITE_MODE: {0}" -f $writeMode)
    Write-Host ("WOULD_WRITE: {0}" -f ($(if ($wouldWrite) { "YES" } else { "NO" })))
    Write-Host ("WROTE_FILE: {0}" -f ($(if ($wroteFile) { "YES" } else { "NO" })))
    Write-Host ("NO_WRITE_NEEDED: {0}" -f ($(if ($noWriteNeeded) { "YES" } else { "NO" })))
    Write-Host ("FALLBACK_WARNING: {0}" -f $fallbackWarning)
}
finally {
    Pop-Location
}
