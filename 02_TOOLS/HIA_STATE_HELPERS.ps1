Set-StrictMode -Version Latest

function Normalize-HIANextActionLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return "N/A" }

    $value = ([string]$Line).Trim()
    $value = $value -replace '^[\-\*\s]+', ''
    $value = $value -replace '^NEXT_ACTION\s*:\s*', ''

    if ($value -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*:\s*READY\s*[—-]\s*(?<desc>.+)$') {
        return ("{0} | {1} | ready" -f $Matches['id'], $Matches['desc'].Trim())
    }

    if ($value -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*\|\s*(?<desc>.+?)\s*\|\s*ready\.?$') {
        return ("{0} | {1} | ready" -f $Matches['id'], $Matches['desc'].Trim())
    }

    if ($value -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*\|\s*(?<desc>.+)$') {
        return ("{0} | {1}" -f $Matches['id'], $Matches['desc'].Trim())
    }

    if ($value -match '^(?<id>PRJPB_[0-9A-Z\-_]+)\s*:\s*(?<desc>.+)$') {
        return ("{0} | {1}" -f $Matches['id'], $Matches['desc'].Trim())
    }

    return $value
}

function Test-HIAOperationalNextActionHeader {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return $false }

    $trimmed = ([string]$Line).Trim()
    return ($trimmed -match '^(04|05|06)\.00_(NEXT_ACTION|PROXIMA_ACCION|SIGUIENTE_ACCION)$')
}

function Test-HIAActionableNextActionLine {
    param([string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return $false }

    $trimmed = ([string]$Line).Trim()

    if ($trimmed -notmatch 'PRJPB_[0-9A-Z\-_]+') { return $false }

    if ($trimmed -match 'DONE|DONE_WITH_WARNINGS|DONE_WITH_NO_GO|STATUS\.+:|PURPOSE\.+:|ID_UNICO\.+:|Reporte?:|Evidencia\s*:|Delivery\s*:|Commit\s*:|ANTES|DESPUES|before|after') {
        return $false
    }

    if ($trimmed -match 'READY|ready|NEXT_ACTION') { return $true }

    return $false
}

function Get-HIALatestSectionalNextAction {
    param([string[]]$Lines)

    if ($null -eq $Lines -or $Lines.Count -eq 0) { return "N/A" }

    for ($i = $Lines.Count - 1; $i -ge 0; $i--) {
        if (-not (Test-HIAOperationalNextActionHeader -Line ([string]$Lines[$i]))) {
            continue
        }

        for ($j = $i + 1; $j -lt $Lines.Count; $j++) {
            $candidate = [string]$Lines[$j]
            $trimmed = $candidate.Trim()

            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
            if ($trimmed -match '^=+$|^[0-9]{2}\.[0-9]{2}_') { break }

            if (Test-HIAActionableNextActionLine -Line $candidate) {
                $normalized = Normalize-HIANextActionLine -Line $candidate
                if (-not [string]::IsNullOrWhiteSpace($normalized) -and $normalized -ne "N/A") {
                    return $normalized
                }
            }
        }
    }

    return "N/A"
}

function Get-HIABatonValueByHeaders {
    param(
        [string]$BatonPath,
        [string[]]$Headers
    )

    if (-not (Test-Path -LiteralPath $BatonPath)) {
        return "N/A"
    }

    try {
        $lines = @(Get-Content -LiteralPath $BatonPath -ErrorAction Stop)
    }
    catch {
        return "N/A"
    }

    if ($null -eq $lines -or $lines.Count -eq 0) {
        return "N/A"
    }

    $isNextActionLookup = $false
    foreach ($header in $Headers) {
        if ([string]$header -match 'NEXT_ACTION|PROXIMA_ACCION|SIGUIENTE_ACCION|NEXT_MINIBATTLE|SIGUIENTE_MINIBATTLE') {
            $isNextActionLookup = $true
            break
        }
    }

    if ($isNextActionLookup) {
        $sectional = Get-HIALatestSectionalNextAction -Lines $lines
        if (-not [string]::IsNullOrWhiteSpace($sectional) -and $sectional -ne "N/A") {
            return $sectional
        }
    }

    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $line = [string]$lines[$i]
        foreach ($header in $Headers) {
            if ($line.Trim().Equals($header, [System.StringComparison]::OrdinalIgnoreCase)) {
                for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                    $value = [string]$lines[$j]
                    if ([string]::IsNullOrWhiteSpace($value)) { continue }
                    if ($value.Trim() -match '^[0-9]{2}\.[0-9]{2}_|^=+$') { break }
                    $clean = $value.Trim() -replace '^[\-\*\s]+', ''
                    if (-not [string]::IsNullOrWhiteSpace($clean)) {
                        return $clean
                    }
                }
            }
        }
    }

    return "N/A"
}

function Get-HIANextReadyBacklogItem {
    param([string]$BacklogPath)

    if (-not (Test-Path -LiteralPath $BacklogPath)) {
        return "N/A"
    }

    try {
        $backlogLines = Get-Content -LiteralPath $BacklogPath
        foreach ($line in $backlogLines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
            if (-not $trimmed.Contains("|")) { continue }

            $parts = $trimmed -split '\|', 7
            $parts = @($parts | ForEach-Object { $_.Trim() })
            if ($parts.Count -ne 7) { continue }

            if (
                $parts[0].ToUpperInvariant() -eq "ID" -and
                $parts[1].ToUpperInvariant() -eq "TYPE" -and
                $parts[2].ToUpperInvariant() -eq "PRIORITY"
            ) {
                continue
            }

            if ($parts[6].ToLowerInvariant() -eq "ready") {
                return ("{0} | {1} | {2}" -f $parts[0], $parts[3], $parts[6])
            }
        }
    }
    catch {
        return "N/A"
    }

    return "N/A"
}
