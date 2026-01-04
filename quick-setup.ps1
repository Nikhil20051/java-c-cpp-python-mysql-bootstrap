<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Quick setup script for copying to new systems

.DESCRIPTION
    Minimal script that downloads and runs the full installer.
    Copy this single file to any Windows system and run it.
#>

# Self-elevation
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Quick Development Environment Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Install Chocolatey if not present
if (!(Test-Path "$env:ProgramData\chocolatey\choco.exe")) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Enable global confirmation
choco feature enable -n allowGlobalConfirmation

Write-Host "`nInstalling development tools..." -ForegroundColor Yellow

# Install all tools
$packages = @(
    "openjdk21",      # Java
    "mingw",          # C/C++
    "python312",      # Python
    "mysql",          # MySQL Server
    "mysql.workbench",# MySQL Workbench
    "git",            # Git
    "vscode"          # VS Code
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Cyan
    choco install $pkg -y
}

# Install Python MySQL package
Write-Host "`nInstalling Python packages..." -ForegroundColor Yellow
python -m pip install --upgrade pip 2>$null
python -m pip install mysql-connector-python pymysql 2>$null

# Set environment variables
$javaPath = "C:\Program Files\OpenJDK\jdk-21"
if (Test-Path $javaPath) {
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "Machine")
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed: Java, C/C++, Python, MySQL, Git, VS Code" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Restart your computer now!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart:" -ForegroundColor White
Write-Host "  1. Initialize MySQL: mysqld --initialize-insecure" -ForegroundColor Gray
Write-Host "  2. Install service: mysqld --install" -ForegroundColor Gray
Write-Host "  3. Start MySQL: net start mysql" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"

