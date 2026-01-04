<#
.SYNOPSIS
    Installs d1run for the current user (no admin required).
    
.DESCRIPTION
    This script installs d1run to the user's local AppData folder and adds it
    to the user's PATH. No administrator privileges are required.
    
    For system-wide installation, use install-d1run-global.ps1 instead.
    
.EXAMPLE
    .\install-d1run-user.ps1
    
.EXAMPLE
    .\install-d1run-user.ps1 -Uninstall
#>
param(
    [string]$InstallPath = "$env:LOCALAPPDATA\d1run",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Success { param($Text) Write-Host "[SUCCESS] $Text" -ForegroundColor Green }
function Write-Err { param($Text) Write-Host "[ERROR] $Text" -ForegroundColor Red }
function Write-Info { param($Text) Write-Host "[INFO] $Text" -ForegroundColor Cyan }
function Write-Warn { param($Text) Write-Host "[WARN] $Text" -ForegroundColor Yellow }

function Add-ToUserPath {
    param([string]$Path)
    
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if (";$current;".ToLower() -like "*;$($Path.ToLower());*") {
        Write-Info "Already in user PATH."
        return
    }
    
    $new = if ($current) { "$current;$Path" } else { $Path }
    [Environment]::SetEnvironmentVariable("Path", $new, "User")
    $env:Path += ";$Path"
    Write-Success "Added to user PATH."
}

function Remove-FromUserPath {
    param([string]$Path)
    
    $current = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = $current -split ";"
    $newParts = @()
    foreach ($p in $parts) {
        if ($p.Trim().ToLower() -ne $Path.ToLower()) {
            $newParts += $p
        }
    }
    $new = $newParts -join ";"
    [Environment]::SetEnvironmentVariable("Path", $new, "User")
    Write-Success "Removed from user PATH."
}

# Uninstall Mode
if ($Uninstall) {
    if (Test-Path $InstallPath) {
        Remove-FromUserPath -Path $InstallPath
        Remove-Item $InstallPath -Recurse -Force
        Write-Success "Uninstalled from $InstallPath"
    }
    else {
        Write-Warn "$InstallPath not found."
    }
    exit 0
}

# Install Mode
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  d1run User Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Info "Installing to: $InstallPath"
Write-Host ""

$ScriptDir = $PSScriptRoot
$d1runImpl = Join-Path $ScriptDir "d1run-impl.ps1"
$d1runCmd = Join-Path $ScriptDir "d1run.cmd"

if (-not (Test-Path $d1runImpl)) { throw "Missing d1run-impl.ps1 in $ScriptDir" }
if (-not (Test-Path $d1runCmd)) { throw "Missing d1run.cmd in $ScriptDir" }

# Create install directory
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Copy files
Copy-Item $d1runImpl $InstallPath -Force
Copy-Item $d1runCmd $InstallPath -Force

Write-Success "Files copied."

# Add to PATH
Add-ToUserPath -Path $InstallPath

Write-Host ""
Write-Success "d1run installed successfully!"
Write-Host ""
Write-Info "You can now run 'd1run' from any NEW terminal window."
Write-Info "To use in the current terminal, run:"
Write-Host ""
Write-Host '  $env:Path += ";' + $InstallPath + '"' -ForegroundColor Yellow
Write-Host ""
