$inputLines = @("11","PRJ_EVID_FRESH_OK","readiness","n")
$inputLines | ./01_UI/terminal/hia.ps1 menu
Write-Host ("EXITCODE=" + $LASTEXITCODE)
