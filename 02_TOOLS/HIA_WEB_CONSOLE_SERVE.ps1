<#
===============================================================================
MODULE: HIA_WEB_CONSOLE_SERVE.ps1
SYSTEM: HIA - Human Intelligence Amplifier
TYPE: WEB CONSOLE SERVER

OBJETIVO
Servir 01_UI\web en localhost sin dependencias externas.
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,

    [Parameter(Mandatory = $false)]
    [string]$WebRoot,

    [Parameter(Mandatory = $false)]
    [switch]$RunExport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HIAProjectRoot {
    $current = $PSScriptRoot
    while ($true) {
        if (Test-Path -LiteralPath (Join-Path $current "02_TOOLS")) {
            return $current
        }

        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            throw "PROJECT_ROOT not found."
        }

        $current = $parent
    }
}

function Get-HIAContentType {
    param([string]$FilePath)

    switch ([IO.Path]::GetExtension($FilePath).ToLowerInvariant()) {
        ".html" { return "text/html; charset=utf-8" }
        ".css" { return "text/css; charset=utf-8" }
        ".js" { return "application/javascript; charset=utf-8" }
        ".json" { return "application/json; charset=utf-8" }
        ".txt" { return "text/plain; charset=utf-8" }
        ".svg" { return "image/svg+xml" }
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".gif" { return "image/gif" }
        default { return "application/octet-stream" }
    }
}

function Send-HIAHttpResponse {
    param(
        [System.IO.Stream]$Stream,
        [int]$StatusCode,
        [string]$StatusText,
        [string]$ContentType,
        [byte[]]$Body,
        [string]$Method
    )

    if ($null -eq $Body) {
        $Body = [byte[]]::new(0)
    }

    $writer = [System.IO.StreamWriter]::new($Stream, [Text.Encoding]::ASCII, 1024, $true)
    $writer.NewLine = "`r`n"
    $writer.WriteLine(("HTTP/1.1 {0} {1}" -f @($StatusCode, $StatusText)))
    $writer.WriteLine("Content-Type: {0}" -f $ContentType)
    $writer.WriteLine("Content-Length: {0}" -f $Body.Length)
    $writer.WriteLine("Cache-Control: no-store")
    $writer.WriteLine("Connection: close")
    $writer.WriteLine("")
    $writer.Flush()

    if ($Method -eq "GET" -and $Body.Length -gt 0) {
        $Stream.Write($Body, 0, $Body.Length)
        $Stream.Flush()
    }
}

$projectRoot = Get-HIAProjectRoot
if (-not $WebRoot) {
    $WebRoot = Join-Path $projectRoot "01_UI\web"
}

$resolvedWebRoot = (Resolve-Path -LiteralPath $WebRoot).Path
if (-not (Test-Path -LiteralPath $resolvedWebRoot -PathType Container)) {
    throw "Web root not found: $resolvedWebRoot"
}

if ($RunExport) {
    $exportScript = Join-Path $projectRoot "02_TOOLS\HIA_WEB_CONSOLE_EXPORT.ps1"
    if (-not (Test-Path -LiteralPath $exportScript)) {
        throw "Export script not found: $exportScript"
    }

    & $exportScript
    if ($LASTEXITCODE -ne 0) {
        throw "Export script failed with exit code $LASTEXITCODE."
    }
}
else {
    Write-Host "TIP: Refresh data before browser reload with:" -ForegroundColor Yellow
    Write-Host "  pwsh -NoProfile -File `"$projectRoot\\02_TOOLS\\HIA_WEB_CONSOLE_EXPORT.ps1`""
    Write-Host ""
}

$listener = $null
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::IPv6Any, $Port)
    $listener.Server.DualMode = $true
    $listener.Start()
}
catch {
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
    }
    catch {
        throw "Cannot start localhost server on http://localhost:$Port/. Details: $($_.Exception.Message)"
    }
}

Write-Host "HIA WEB CONSOLE SERVER RUNNING" -ForegroundColor Green
Write-Host ("ROOT: {0}" -f $resolvedWebRoot)
Write-Host ("URL:  http://localhost:{0}/" -f $Port)
Write-Host "Press Ctrl+C to stop."
Write-Host ""

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 8192, $true)

            $requestLine = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($requestLine)) {
                Write-Host "WARN: Empty request line received."
                continue
            }

            $parts = $requestLine.Split(" ")
            if ($parts.Count -lt 2) {
                $body = [Text.Encoding]::UTF8.GetBytes("Bad Request")
                Send-HIAHttpResponse -Stream $stream -StatusCode 400 -StatusText "Bad Request" -ContentType "text/plain; charset=utf-8" -Body $body -Method "GET"
                continue
            }

            $method = $parts[0].ToUpperInvariant()
            $path = $parts[1]

            while ($true) {
                $headerLine = $reader.ReadLine()
                if ($null -eq $headerLine -or $headerLine -eq "") {
                    break
                }
            }

            if ($method -ne "GET" -and $method -ne "HEAD") {
                $body = [Text.Encoding]::UTF8.GetBytes("Method Not Allowed")
                Send-HIAHttpResponse -Stream $stream -StatusCode 405 -StatusText "Method Not Allowed" -ContentType "text/plain; charset=utf-8" -Body $body -Method $method
                continue
            }

            $cleanPath = [System.Uri]::UnescapeDataString($path.Split("?")[0].TrimStart("/"))
            if ([string]::IsNullOrWhiteSpace($cleanPath)) {
                $cleanPath = "index.html"
            }

            $relativePath = $cleanPath.Replace('/', [IO.Path]::DirectorySeparatorChar)
            $candidatePath = Join-Path $resolvedWebRoot $relativePath
            $fullPath = [IO.Path]::GetFullPath($candidatePath)

            if (-not $fullPath.StartsWith($resolvedWebRoot, [StringComparison]::OrdinalIgnoreCase)) {
                $body = [Text.Encoding]::UTF8.GetBytes("Forbidden")
                Send-HIAHttpResponse -Stream $stream -StatusCode 403 -StatusText "Forbidden" -ContentType "text/plain; charset=utf-8" -Body $body -Method $method
                continue
            }

            if (Test-Path -LiteralPath $fullPath -PathType Container) {
                $fullPath = Join-Path $fullPath "index.html"
            }

            if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
                $body = [Text.Encoding]::UTF8.GetBytes("Not Found")
                Send-HIAHttpResponse -Stream $stream -StatusCode 404 -StatusText "Not Found" -ContentType "text/plain; charset=utf-8" -Body $body -Method $method
                continue
            }

            $bytes = [IO.File]::ReadAllBytes($fullPath)
            $contentType = Get-HIAContentType -FilePath $fullPath
            Send-HIAHttpResponse -Stream $stream -StatusCode 200 -StatusText "OK" -ContentType $contentType -Body $bytes -Method $method
        }
        catch {
            Write-Host ("ERROR: Request handling failed - {0}" -f $_.Exception.Message)
            try {
                $errStream = $client.GetStream()
                $body = [Text.Encoding]::UTF8.GetBytes("Internal Server Error")
                Send-HIAHttpResponse -Stream $errStream -StatusCode 500 -StatusText "Internal Server Error" -ContentType "text/plain; charset=utf-8" -Body $body -Method "GET"
            }
            catch {
                # no-op
            }
        }
        finally {
            if ($client) {
                $client.Close()
            }
        }
    }
}
finally {
    if ($listener) {
        $listener.Stop()
    }
}
