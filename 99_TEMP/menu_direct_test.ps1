. ./01_UI/terminal/hia.ps1
Remove-Variable -Name HIA_EXIT_CODE -Scope Global -ErrorAction SilentlyContinue
$global:HIA_EXIT_CODE = $null
$code = Invoke-HIAMenuCommand -Cmd 'ai' -CmdArgs @('plan','UNKNOWN_PROJECT_X','--preset','readiness')
Write-Host ("MENU_DIRECT_EXIT={0}" -f $code)
Write-Host ("HIA_EXIT_CODE={0}" -f $global:HIA_EXIT_CODE)
