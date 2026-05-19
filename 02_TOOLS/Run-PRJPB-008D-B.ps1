Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Get-Location
$uxEvalDir = Join-Path $root '04_PROJECTS\PRJ_0001_HIA.PRODUCT\UX_EVAL'
$files = @(
    'README.UX_EVAL.txt',
    'UX_UI.EVALUATION.LOG.txt',
    'UX_UI.EVALUATION.CHECKLIST.txt',
    'UX_UI.ISSUES.BACKLOG.txt',
    'UX_UI.DECISIONS.LOG.txt'
) | ForEach-Object { Join-Path $uxEvalDir $_ }

Write-Host '== git status --short =='
git status --short

if (-not (Test-Path -LiteralPath $uxEvalDir)) {
    throw "UX_EVAL folder not found: $uxEvalDir"
}

Write-Host "== UX_EVAL files =="
$missing = @()
foreach ($f in $files) {
    if (Test-Path -LiteralPath $f) {
        $item = Get-Item -LiteralPath $f
        Write-Host ("OK {0} ({1} bytes)" -f $item.FullName, $item.Length)
    } else {
        $missing += $f
    }
}
if ($missing.Count -gt 0) {
    throw ("Missing UX_EVAL files: {0}" -f ($missing -join ', '))
}

Write-Host "== git check-ignore -v (diagnostic) =="
foreach ($f in $files) {
    $output = @(git check-ignore -v -- $f 2>&1)
    $lines = @($output | Where-Object { $_ -and ($_ -notmatch '^warning: unable to access ') })
    if ($LASTEXITCODE -eq 0 -and $lines.Count -gt 0) {
        $lines | ForEach-Object { Write-Host $_ }
        if (($lines -join "`n") -notmatch '!04_PROJECTS/PRJ_0001_HIA\.PRODUCT/UX_EVAL/\*\.txt') {
            throw "Unexpected ignore rule for $f -> $($lines -join ' | ')"
        }
    } else {
        Write-Host ("NO_MATCH {0}" -f $f)
    }
}

Write-Host '== git add --dry-run UX_EVAL/*.txt =='
$dry = git add --dry-run -- 04_PROJECTS/PRJ_0001_HIA.PRODUCT/UX_EVAL/*.txt 2>&1
$dry | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw 'git add --dry-run failed for UX_EVAL files'
}

Write-Host 'PRJPB_008D-B_CHECK_OK'
