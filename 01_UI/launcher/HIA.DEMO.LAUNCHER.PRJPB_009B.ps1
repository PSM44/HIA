<# 
ID_UNICO..........: PRJPB_009B.ONE_CLICK_DEMO_LAUNCHER
VERSION...........: v0.1
FECHA.............: 2026-06-04
CIUDAD............: Santiago, Chile
PROYECTO..........: PRJ_0001_HIA.PRODUCT
PROPOSITO.........: Abrir dashboard HIA v0.2 y mostrar comandos de apoyo para demo interna.
#>

$ErrorActionPreference = "Stop"

$Root = "C:\01. GitHub\Wings3.0\01_PROJECTS\HIA"
$ProjectId = "PRJ_0001_HIA.PRODUCT"
$Dashboard = Join-Path $Root "01_UI\web\HIA.MANAGEMENT.DASHBOARD.v0.2.html"
$Delivery = Join-Path $Root "04_PROJECTS\$ProjectId\DELIVERY"

Write-Host "========== HIA DEMO LAUNCHER / PRJPB_009B =========="
Write-Host "ROOT.............: $Root"
Write-Host "PROJECT_ID.......: $ProjectId"
Write-Host "DASHBOARD........: $Dashboard"
Write-Host "DELIVERY.........: $Delivery"
Write-Host "===================================================="
Write-Host ""

if (-not (Test-Path -LiteralPath $Dashboard)) {
    throw "Dashboard not found: $Dashboard"
}

Start-Process -FilePath $Dashboard

Write-Host "Dashboard abierto."
Write-Host ""
Write-Host "Comandos sugeridos para demo live:"
Write-Host "cd `"$Root`""
Write-Host ".\01_UI\terminal\hia.ps1 project status $ProjectId"
Write-Host ".\01_UI\terminal\hia.ps1 project continue $ProjectId"
Write-Host ".\01_UI\terminal\hia.ps1 project session status $ProjectId"
Write-Host ""
Write-Host "Entrega PRJPB_009B:"
Get-ChildItem -LiteralPath $Delivery -Filter "PRJPB_009B.*.txt" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 10 |
    ForEach-Object { Write-Host ("- " + $_.FullName) }

Write-Host ""
Write-Host "========== HIA DEMO LAUNCHER / END =========="
