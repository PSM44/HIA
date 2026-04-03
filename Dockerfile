# HIA minimal runtime (PowerShell) for terminal CLI inside Docker
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

WORKDIR /app

# Copy repository contents
COPY . /app

# Default entrypoint to HIA CLI; commands passed to docker will be forwarded
ENTRYPOINT ["pwsh","-NoLogo","-File","/app/01_UI/terminal/hia.ps1"]
