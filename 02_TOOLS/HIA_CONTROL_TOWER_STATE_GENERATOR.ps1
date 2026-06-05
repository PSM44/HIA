param(
    [string]$ProjectId = "PRJ_0001_HIA.PRODUCT",
    [string]$RepoRoot = (Get-Location).Path,
    [string]$OutputPath = "01_UI/web/control-tower-shell/assets/hia.state.js"
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

Push-Location $RepoRoot
try {
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

    $radarLite = "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt"
    $radarIndex = "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt"
    $radarCore = "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt"

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $warningList = @(
        "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
        "Si hay conflicto, manda CURRENT_STATE valido; si no existe, manda fallback CLI/BATON/BACKLOG.",
        "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto mientras exista fallback heuristico."
    )
    if ($fallbackUsed) {
        $warningList += ("FALLBACK_ACTIVE: {0}" -f $fallbackWarning)
    }

    $js = @"
// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009Q_CURRENT_STATE_PRIMARY_CONTROL_TOWER_GENERATOR
// GENERATED_AT......: $generatedLocal
// GENERATED_UTC.....: $generatedUtc
// SOURCE............: CURRENT_STATE primary with CLI fallback
// MODE..............: READ_ONLY_SNAPSHOT
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

    Set-Content -LiteralPath $OutputPath -Value $js -Encoding UTF8

    Write-Host ("OUTPUT_PATH: {0}" -f $OutputPath)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("CURRENT_STATE_STATUS: {0}" -f $stateInfo.status)
    Write-Host ("CURRENT_STATE_SOURCE: {0}" -f $continuitySource)
    Write-Host ("CURRENT_STATE_PATH: {0}" -f $currentStateRelative)
    Write-Host ("FALLBACK_WARNING: {0}" -f $fallbackWarning)
}
finally {
    Pop-Location
}
