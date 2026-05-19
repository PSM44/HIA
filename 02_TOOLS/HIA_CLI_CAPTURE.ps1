<#
FILE: HIA_CLI_CAPTURE.ps1
PURPOSE:
  Reusable transcript-backed capture helper for HIA CLI validations.

WHY:
  Several HIA commands print through Write-Host. Plain pipeline capture such as
  Out-String or 2>&1 can miss host-visible output. Start-Transcript captures
  what the operator sees and is safer for acceptance validation.

CONTRACT:
  Invoke-HIACliCapture -CommandLabel <string> -ScriptBlock <scriptblock>
                       -ExpectedPatterns <string[]> -RejectedPatterns <string[]>
                       -LogDir <path>

RETURNS:
  [pscustomobject] with:
    Status
    ExitCode
    TranscriptPath
    RawTranscript
    MissingExpectedPatterns
    MatchedRejectedPatterns
    ExpectedPatterns
    RejectedPatterns
#>

Set-StrictMode -Version Latest

function Invoke-HIACliCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLabel,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedPatterns = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$RejectedPatterns = @(),

        [Parameter(Mandatory = $true)]
        [string]$LogDir
    )

    if ([string]::IsNullOrWhiteSpace($CommandLabel)) {
        throw "CommandLabel is required."
    }

    if ([string]::IsNullOrWhiteSpace($LogDir)) {
        throw "LogDir is required."
    }

    if (-not (Test-Path -LiteralPath $LogDir -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    }

    $safeLabel = ($CommandLabel -replace '[^A-Za-z0-9_.-]+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($safeLabel)) {
        $safeLabel = "HIA_COMMAND"
    }

    if ($safeLabel.Length -gt 80) {
        $safeLabel = $safeLabel.Substring(0, 80).Trim('_')
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $transcriptPath = Join-Path $LogDir ("HIA_CLI_CAPTURE.{0}.{1}.transcript.txt" -f $safeLabel, $stamp)

    $exitCode = 0
    $rawTranscript = ""
    $missingExpected = New-Object System.Collections.Generic.List[string]
    $matchedRejected = New-Object System.Collections.Generic.List[string]

    try {
        Start-Transcript -LiteralPath $transcriptPath -Force | Out-Null

        try {
            & $ScriptBlock
            $lastExit = Get-Variable -Name LASTEXITCODE -Scope Global -ValueOnly -ErrorAction SilentlyContinue
            if ($null -eq $lastExit) {
                $exitCode = 0
            }
            else {
                $exitCode = [int]$lastExit
            }
        }
        catch {
            $exitCode = 1
            Write-Host ("HIA_CLI_CAPTURE_SCRIPTBLOCK_ERROR: {0}" -f $_.Exception.Message)
        }
        finally {
            Stop-Transcript | Out-Null
        }

        if (Test-Path -LiteralPath $transcriptPath -PathType Leaf) {
            $rawTranscript = Get-Content -LiteralPath $transcriptPath -Raw
        }
        else {
            $rawTranscript = ""
        }

        foreach ($pattern in $ExpectedPatterns) {
            if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
            if ($rawTranscript -notmatch $pattern) {
                $missingExpected.Add($pattern) | Out-Null
            }
        }

        foreach ($pattern in $RejectedPatterns) {
            if ([string]::IsNullOrWhiteSpace($pattern)) { continue }
            if ($rawTranscript -match $pattern) {
                $matchedRejected.Add($pattern) | Out-Null
            }
        }

        $status = "OK"
        if ($exitCode -ne 0 -or $missingExpected.Count -gt 0 -or $matchedRejected.Count -gt 0) {
            $status = "FAIL"
        }

        return [pscustomobject]@{
            Status                  = $status
            ExitCode                = $exitCode
            TranscriptPath          = $transcriptPath
            RawTranscript           = $rawTranscript
            MissingExpectedPatterns = @($missingExpected)
            MatchedRejectedPatterns = @($matchedRejected)
            ExpectedPatterns        = @($ExpectedPatterns)
            RejectedPatterns        = @($RejectedPatterns)
        }
    }
    catch {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Transcript may not be active. Ignore cleanup failure.
        }

        throw
    }
}

function Assert-HIACliCaptureOk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$CaptureResult
    )

    if ($null -eq $CaptureResult) {
        throw "CaptureResult is null."
    }

    if ([string]$CaptureResult.Status -ne "OK") {
        Write-Host "HIA CLI CAPTURE FAILED" -ForegroundColor Red
        Write-Host ("STATUS..........: {0}" -f $CaptureResult.Status)
        Write-Host ("EXIT_CODE.......: {0}" -f $CaptureResult.ExitCode)
        Write-Host ("TRANSCRIPT_PATH.: {0}" -f $CaptureResult.TranscriptPath)

        if ($CaptureResult.MissingExpectedPatterns.Count -gt 0) {
            Write-Host "MISSING_EXPECTED_PATTERNS:" -ForegroundColor Yellow
            $CaptureResult.MissingExpectedPatterns | ForEach-Object {
                Write-Host ("- {0}" -f $_)
            }
        }

        if ($CaptureResult.MatchedRejectedPatterns.Count -gt 0) {
            Write-Host "MATCHED_REJECTED_PATTERNS:" -ForegroundColor Yellow
            $CaptureResult.MatchedRejectedPatterns | ForEach-Object {
                Write-Host ("- {0}" -f $_)
            }
        }

        throw "HIA CLI capture assertion failed."
    }

    return $true
}
