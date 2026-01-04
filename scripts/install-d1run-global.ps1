<#
.SYNOPSIS
    Installs d1run globally.
#>
param(
    [string]$InstallPath = "C:\Program Files\d1run",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Write-Success {
    param($Text)
    Write-Host "[SUCCESS] $Text" -ForegroundColor Green
}

function Write-Err {
    param($Text)
    Write-Host "[ERROR] $Text" -ForegroundColor Red
}

function Write-Info {
    param($Text)
    Write-Host "[INFO] $Text" -ForegroundColor Cyan
}

function Write-Warn {
    param($Text)
    Write-Host "[WARN] $Text" -ForegroundColor Yellow
}

# Check Admin
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "Must run as Administrator!"
    Write-Warn "Please restart PowerShell as Administrator."
    exit 1
}

# Functions
function Add-ToPath {
    param([string]$Path)
    
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    
    # Check
    if (";$current;".ToLower() -like "*;$($Path.ToLower());*") {
        Write-Info "Already in PATH."
        return
    }
    
    $new = "$current;$Path"
    [Environment]::SetEnvironmentVariable("Path", $new, "Machine")
    $env:Path += ";$Path"
    Write-Success "Added to PATH."
}

function Remove-FromPath {
    param([string]$Path)
    
    $current = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $parts = $current -split ";"
    $newParts = @()
    foreach ($p in $parts) {
        if ($p.Trim().ToLower() -ne $Path.ToLower()) {
            $newParts += $p
        }
    }
    $new = $newParts -join ";"
    [Environment]::SetEnvironmentVariable("Path", $new, "Machine")
    Write-Success "Removed from PATH."
}

# Uninstall Mode
if ($Uninstall) {
    if (Test-Path $InstallPath) {
        Remove-FromPath -Path $InstallPath
        Remove-Item $InstallPath -Recurse -Force
        Write-Success "Uninstalled from $InstallPath"
    }
    else {
        Write-Warn "$InstallPath not found."
    }
    exit 0
}

# Install Mode
Write-Host "Installing d1run..." -ForegroundColor Cyan

$ScriptDir = $PSScriptRoot
$d1runImpl = Join-Path $ScriptDir "d1run-impl.ps1"
$d1runCmd = Join-Path $ScriptDir "d1run.cmd"

if (-not (Test-Path $d1runImpl)) { throw "Missing d1run-impl.ps1" }
if (-not (Test-Path $d1runCmd)) { throw "Missing d1run.cmd" }

if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

if (Test-Path (Join-Path $InstallPath "d1run.ps1")) {
    Remove-Item (Join-Path $InstallPath "d1run.ps1") -Force
}

Copy-Item $d1runImpl $InstallPath -Force
Copy-Item $d1runCmd $InstallPath -Force

Write-Success "Files copied."

Add-ToPath -Path $InstallPath

Write-Success "d1run installed successfully!"
Write-Info "You can run 'd1run' from any terminal."
