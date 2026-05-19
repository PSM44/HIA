Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PlainText {
    param([Parameter(ValueFromPipeline=$true)]$InputObject)
    process {
        if ($null -eq $InputObject) { return }
        if ($InputObject -is [string]) { $text = $InputObject } else { $text = ($InputObject | Out-String -Width 500) }
        # Strip ANSI escapes + control chars except CR/LF/TAB
        $text = [regex]::Replace($text, "`e\[[0-9;?]*[A-Za-z]", "")
        $text = [regex]::Replace($text, "[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]", "")
        $text
    }
}

function Test-HIAProjectSessionActive {
    param([string]$ProjectId,[string]$SessionFilePath)

    $plain = ''
    if (Test-Path -LiteralPath $SessionFilePath) {
        try {
            $json = Get-Content -LiteralPath $SessionFilePath -Raw | ConvertFrom-Json
            $status = [string]$json.status
            $closed = [string]$json.closed_utc
            if ($status -match '^(?i)active$' -and [string]::IsNullOrWhiteSpace($closed)) {
                return @{ IsActive = $true; Source='session-file'; Text=$plain }
            }
        } catch {
        }
    }

    return @{ IsActive = $false; Source='none'; Text=$plain }
}

$ProjectId = 'PRJ_0001_HIA.PRODUCT'
$projectRoot = Join-Path -Path (Get-Location) -ChildPath ("04_PROJECTS\{0}" -f $ProjectId)
$taskDir = Join-Path $projectRoot 'ARTIFACTS\TASKS'
$logDir = Join-Path $projectRoot 'ARTIFACTS\LOGS'
$sessionFile = Join-Path $projectRoot 'ARTIFACTS\SESSION.ACTIVE.json'

New-Item -ItemType Directory -Path $taskDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$sessionCheck = Test-HIAProjectSessionActive -ProjectId $ProjectId -SessionFilePath $sessionFile
if (-not $sessionCheck.IsActive) {
    throw "Project session is not active. Start session before PRJPB_008A."
}

$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
$demoPath = Join-Path $taskDir 'PRJPB_008A.FUNCTIONAL_DEMO_PACKAGE.txt'
$nextPath = Join-Path $taskDir 'PRJPB_008A.NEXT_ACTION.txt'
$logPath = Join-Path $logDir 'PRJPB_008A.FUNCTIONAL_DEMO_PACKAGE.log'

$demoContent = @(
'PRJPB_008A — FUNCTIONAL DEMO PACKAGE',
"PROJECT_ID: $ProjectId",
"GENERATED_AT: $timestamp",
"SESSION_CHECK_SOURCE: $($sessionCheck.Source)",
'',
'PACKAGE_SCOPE:',
'- Portfolio API contract clean (success/data/meta).',
'- Active Project continuity surface operational.',
'- AI Stack surface available with honest state signaling.',
'',
'NEXT_ACTION:',
'PRJPB_008B | ejecutar smoke demo end-to-end y capturar evidencia para demo gerencial | ready'
) -join "`n"

$nextContent = @(
'PRJPB_008A -> PRJPB_008B HANDOFF',
"PROJECT_ID: $ProjectId",
"GENERATED_AT: $timestamp",
'',
'NEXT_ACTION:',
'PRJPB_008B | ejecutar smoke demo end-to-end y capturar evidencia para demo gerencial | ready'
) -join "`n"

$logContent = @(
"[$timestamp] PRJPB_008A start",
"[$timestamp] session_active=true source=$($sessionCheck.Source)",
"[$timestamp] wrote=$demoPath",
"[$timestamp] wrote=$nextPath",
"[$timestamp] result=ok"
) -join "`n"

[System.IO.File]::WriteAllText($demoPath, $demoContent + "`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($nextPath, $nextContent + "`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($logPath, $logContent + "`n", [System.Text.UTF8Encoding]::new($false))

Write-Host "PRJPB_008A_OK"
Write-Host "SESSION_SOURCE=$($sessionCheck.Source)"
Write-Host "DEMO_PATH=$demoPath"
Write-Host "NEXT_PATH=$nextPath"
Write-Host "LOG_PATH=$logPath"

