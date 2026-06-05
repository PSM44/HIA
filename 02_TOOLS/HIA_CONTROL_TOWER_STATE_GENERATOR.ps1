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

Push-Location $RepoRoot
try {
    $hia = Join-Path $RepoRoot "01_UI/terminal/hia.ps1"
    if (-not (Test-Path -LiteralPath $hia)) {
        throw "Missing HIA CLI: $hia"
    }

    $continueOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$RepoRoot'; .\01_UI\terminal\hia.ps1 project continue $ProjectId"
    $statusOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '$RepoRoot'; .\01_UI\terminal\hia.ps1 project status $ProjectId"

    $continueLines = @($continueOut | ForEach-Object { [string]$_ })
    $statusLines = @($statusOut | ForEach-Object { [string]$_ })

    $nextAction = Get-LineValue -Lines $continueLines -Prefix "NEXT_ACTION:"
    $resumeRecommendation = Get-LineValue -Lines $continueLines -Prefix "RESUME_RECOMMENDATION:"
    $evidenceState = Get-LineValue -Lines $continueLines -Prefix "EVIDENCE_STATE:"
    $evidenceConsistency = Get-LineValue -Lines $continueLines -Prefix "EVIDENCE_CONSISTENCY:"
    $sessionStatus = Get-LineValue -Lines $statusLines -Prefix "LAST_SESSION_STATUS:"

    $branch = (& git branch --show-current).Trim()
    $headShort = (& git rev-parse --short HEAD).Trim()
    $headMessage = (& git log -1 --pretty=%s).Trim()

    $radarLite = "03_ARTIFACTS/RADAR/Radar.Lite.ACTIVE.txt"
    $radarIndex = "03_ARTIFACTS/RADAR/Radar.Index.ACTIVE.txt"
    $radarCore = "03_ARTIFACTS/RADAR/Radar.Core.ACTIVE.txt"

    function Get-FileBytes {
        param([string]$Path)
        if (-not (Test-Path -LiteralPath $Path)) { return 0 }
        return (Get-Item -LiteralPath $Path).Length
    }

    $generatedLocal = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"

    $outDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $js = @"
// ========== HIA CONTROL TOWER REAL READ-ONLY STATE ==========
// ID_UNICO..........: PRJPB_009O_HARDENED_GENERATED_STATE
// GENERATED_AT......: $generatedLocal
// SOURCE............: HIA_CONTROL_TOWER_STATE_GENERATOR.ps1 + HIA CLI + Git + RADAR
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
    resolver_status: "CLI_RESOLVER_ALIGNED_CONTINUE_STATUS_REVIEW",
    source: "HIA CLI project continue/status"
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
    minibattle: "PRJPB_009O"
  }),
  warnings: Object.freeze([
    "Este estado es snapshot visible read-only; no reemplaza BATON, BACKLOG ni RADAR.",
    "Si hay conflicto, manda CLI/BATON/RADAR vivo.",
    "TD_BATON_APPEND_ONLY_STATE_001/P1 sigue abierto: crear CURRENT_STATE machine-readable."
  ])
});
"@

    Set-Content -LiteralPath $OutputPath -Value $js -Encoding UTF8

    Write-Host ("OUTPUT_PATH: {0}" -f $OutputPath)
    Write-Host ("NEXT_ACTION: {0}" -f $nextAction)
    Write-Host ("EVIDENCE_STATE: {0}" -f $evidenceState)
    Write-Host ("EVIDENCE_CONSISTENCY: {0}" -f $evidenceConsistency)
}
finally {
    Pop-Location
}
