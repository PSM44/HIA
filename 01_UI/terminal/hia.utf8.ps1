# =============================================================================
# FILE: hia.utf8.ps1
# PROJECT: HIA
# TYPE: CLI WRAPPER
# PURPOSE: WSL2/Windows PowerShell 5.1 UTF-8 output wrapper.
# NOTE: Do not put business logic here. This wrapper only hardens encoding and
# delegates to hia.ps1.
# =============================================================================

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassThruArgs
)

try {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = $utf8NoBom
    $OutputEncoding = $utf8NoBom
}
catch {
    # Non-blocking. Wrapper must still attempt to delegate.
}

$entrypoint = Join-Path $PSScriptRoot "hia.ps1"
if (-not (Test-Path -LiteralPath $entrypoint)) {
    throw "hia.ps1 entrypoint not found."
}

& $entrypoint @PassThruArgs
exit $LASTEXITCODE
