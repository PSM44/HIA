<#
HIA Interactive Shell
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CLI = Join-Path $ScriptDir "hia.ps1"

function Show-Banner {

Write-Host ""
Write-Host "===================================="
Write-Host " HIA — Human Intelligence Amplifier"
Write-Host " Interactive Shell"
Write-Host "===================================="
Write-Host ""

}

Show-Banner

while ($true)
{

$cmd = Read-Host "HIA >"

if ($cmd -eq "exit")
{
    break
}

if ($cmd -eq "")
{
    continue
}

$args = $cmd.Split(" ")

$command = $args[0]

$arg1 = $null
$arg2 = $null

if ($args.Count -ge 2)
{
    $arg1 = $args[1]
}

if ($args.Count -ge 3)
{
    $arg2 = $args[2]
}

& $CLI $command $arg1 $arg2

}