<#
.SYNOPSIS
    Installs the Auto-Push Monitor globally for easy access from any location
    
.DESCRIPTION
    This script creates a global command 'apm' (Auto-Push Monitor) that can be
    run from any directory to manage monitoring for that repository.
#>

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetDir = "$env:USERPROFILE\.auto-push-monitor"
$BinDir = "$env:USERPROFILE\.local\bin"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "     AUTO-PUSH MONITOR - Global Installation                    " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Create directories
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}
if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

# Copy main script
Copy-Item (Join-Path $ScriptDir "auto-push-monitor.ps1") $TargetDir -Force
Write-Host "[OK] Copied main script" -ForegroundColor Green

# Create wrapper command
$WrapperContent = @'
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.auto-push-monitor\auto-push-monitor.ps1" %*
'@

Set-Content -Path "$BinDir\apm.cmd" -Value $WrapperContent -Encoding ASCII
Write-Host "[OK] Created 'apm' command" -ForegroundColor Green

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$BinDir", "User")
    Write-Host "[OK] Added to PATH" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: Please restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor White
Write-Host "  apm              - Show status for current directory" -ForegroundColor Gray
Write-Host "  apm -Start       - Start monitoring current directory" -ForegroundColor Gray
Write-Host "  apm -Stop        - Stop monitoring" -ForegroundColor Gray
Write-Host "  apm -Configure   - Configure settings" -ForegroundColor Gray
Write-Host ""
