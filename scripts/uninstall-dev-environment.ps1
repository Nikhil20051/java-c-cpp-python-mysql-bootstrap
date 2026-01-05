<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Uninstalls development environment components installed by this bootstrap.

.DESCRIPTION
    This script safely removes only the components installed by install-dev-environment.ps1:
    - Java (Eclipse Temurin JDK)
    - Apache Maven
    - Gradle
    - MinGW-w64 (GCC/G++ Compiler)
    - Python 3.12
    - MySQL Server and Workbench
    - Git
    - Visual Studio Code
    - Python packages (mysql-connector-python, pymysql)
    - Environment variables (JAVA_HOME, M2_HOME, MYSQL_INCLUDE, MYSQL_LIB)
    - Test database (testdb)
    - Downloaded connectors in lib folder

.PARAMETER All
    Uninstall all components without prompting for each.

.PARAMETER KeepData
    Keep MySQL databases and user data.

.PARAMETER Component
    Specify a single component to uninstall: java, mingw, python, mysql, git, vscode, all

.EXAMPLE
    .\uninstall-dev-environment.ps1
    .\uninstall-dev-environment.ps1 -All
    .\uninstall-dev-environment.ps1 -Component mysql
    .\uninstall-dev-environment.ps1 -All -KeepData
#>

param(
    [switch]$All,
    [switch]$KeepData,
    [ValidateSet("java", "maven", "gradle", "mingw", "python", "mysql", "git", "vscode", "envvars", "connectors", "d1run", "all")]
    [string]$Component = ""
)

# Self-elevation: Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ============================================
# CONFIGURATION
# ============================================
$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Color output helpers
function Write-Header($text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  $text" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
}

function Write-SubHeader($text) {
    Write-Host ""
    Write-Host "--- $text ---" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "[REMOVED] $text" -ForegroundColor Green
}

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor Cyan
}

function Write-Warn($text) {
    Write-Host "[WARN] $text" -ForegroundColor Yellow
}

function Write-Err($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Write-Skip($text) {
    Write-Host "[SKIPPED] $text" -ForegroundColor Gray
}

function Confirm-Action($message) {
    if ($All) { return $true }
    
    $response = Read-Host "$message (Y/N)"
    return ($response -eq 'Y' -or $response -eq 'y' -or $response -eq 'yes')
}

# Safe function to remove ONLY specific paths from system PATH
# This is critical to prevent system corruption
function Remove-FromSystemPath {
    param(
        [string[]]$PathsToRemove
    )
    
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    if ([string]::IsNullOrWhiteSpace($currentPath)) {
        Write-Warn "System PATH is empty or could not be read. Skipping PATH cleanup."
        return
    }
    
    # Backup the current PATH before any modifications
    $backupFile = "$ProjectRoot\logs\path-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    if (!(Test-Path "$ProjectRoot\logs")) {
        New-Item -ItemType Directory -Path "$ProjectRoot\logs" -Force | Out-Null
    }
    $currentPath | Out-File -FilePath $backupFile -Encoding UTF8
    Write-Info "PATH backup saved to: $backupFile"
    
    $parts = $currentPath -split ";"
    $newParts = @()
    $removedCount = 0
    
    foreach ($part in $parts) {
        $partTrimmed = $part.Trim()
        if ([string]::IsNullOrWhiteSpace($partTrimmed)) {
            continue  # Skip empty entries
        }
        
        $shouldRemove = $false
        foreach ($pathToRemove in $PathsToRemove) {
            if ($partTrimmed.ToLower() -eq $pathToRemove.ToLower()) {
                $shouldRemove = $true
                Write-Info "Removing from PATH: $partTrimmed"
                $removedCount++
                break
            }
        }
        
        if (-not $shouldRemove) {
            $newParts += $partTrimmed
        }
    }
    
    if ($removedCount -gt 0) {
        # Validate the new PATH before saving
        $newPath = $newParts -join ";"
        
        # Safety check: ensure we're not leaving an empty or too-short PATH
        if ($newPath.Length -lt 50) {
            Write-Err "SAFETY CHECK FAILED: New PATH would be too short. Aborting PATH modification."
            Write-Warn "PATH was NOT modified. Please clean up manually if needed."
            return
        }
        
        # Safety check: ensure critical Windows paths are still there
        $criticalPaths = @("\Windows\system32", "\Windows", "\System32\Wbem")
        $hasCritical = $false
        foreach ($critical in $criticalPaths) {
            if ($newPath -like "*$critical*") {
                $hasCritical = $true
                break
            }
        }
        
        if (-not $hasCritical) {
            Write-Err "SAFETY CHECK FAILED: Critical Windows paths would be missing. Aborting PATH modification."
            Write-Warn "PATH was NOT modified. Please clean up manually if needed."
            return
        }
        
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Success "Removed $removedCount path(s) from system PATH"
    }
    else {
        Write-Skip "No paths to remove from system PATH"
    }
}

# ============================================
# CHOCOLATEY CHECK
# ============================================
$chocoInstalled = Test-Path "$env:ProgramData\chocolatey\choco.exe"
if (-not $chocoInstalled) {
    Write-Err "Chocolatey is not installed. Cannot uninstall packages."
    Write-Info "Components may have been installed manually or via a different method."
    exit 1
}

# ============================================
# MAIN SCRIPT
# ============================================
Write-Header "Development Environment Uninstaller"

Write-Host @"
WARNING: This script will PERMANENTLY REMOVE development tools!

This uninstaller will remove ONLY components installed by this bootstrap:
  - Java (OpenJDK / Eclipse Temurin)
  - Apache Maven and Gradle (Java build tools)
  - MinGW-w64 (C/C++ Compiler)
  - Python (any version installed by this setup) and its packages
  - MySQL Server and Workbench (if installed)
  - Git
  - Visual Studio Code
  - d1run (Universal Code Runner)
  - Environment variables set by this installer
  - Downloaded MySQL connectors
  - PATH entries added by installer

"@ -ForegroundColor Yellow

if (-not $All -and $Component -eq "") {
    Write-Host "Do you want to proceed with the uninstallation?" -ForegroundColor Red
    $confirm = Read-Host "Type 'UNINSTALL' to confirm"
    if ($confirm -ne 'UNINSTALL') {
        Write-Host "Uninstallation cancelled." -ForegroundColor Green
        exit 0
    }
}

# Track what we're uninstalling
$uninstallJava = ($Component -eq "" -or $Component -eq "java" -or $Component -eq "all")
$uninstallMaven = ($Component -eq "" -or $Component -eq "maven" -or $Component -eq "all")
$uninstallGradle = ($Component -eq "" -or $Component -eq "gradle" -or $Component -eq "all")
$uninstallMingw = ($Component -eq "" -or $Component -eq "mingw" -or $Component -eq "all")
$uninstallPython = ($Component -eq "" -or $Component -eq "python" -or $Component -eq "all")
$uninstallMySQL = ($Component -eq "" -or $Component -eq "mysql" -or $Component -eq "all")
$uninstallGit = ($Component -eq "" -or $Component -eq "git" -or $Component -eq "all")
$uninstallVSCode = ($Component -eq "" -or $Component -eq "vscode" -or $Component -eq "all")
$uninstallEnvVars = ($Component -eq "" -or $Component -eq "envvars" -or $Component -eq "all")
$uninstallConnectors = ($Component -eq "" -or $Component -eq "connectors" -or $Component -eq "all")
$uninstallD1Run = ($Component -eq "" -or $Component -eq "d1run" -or $Component -eq "all")

# ============================================
# STEP 1: Stop MySQL Service
# ============================================
if ($uninstallMySQL) {
    Write-SubHeader "Step 1: Stopping MySQL Service"
    
    $mysqlService = Get-Service -Name "MySQL*" -ErrorAction SilentlyContinue
    if ($mysqlService) {
        if ($mysqlService.Status -eq "Running") {
            Write-Info "Stopping MySQL service..."
            Stop-Service $mysqlService.Name -Force -ErrorAction SilentlyContinue
            Write-Success "MySQL service stopped"
        }
        
        # Remove MySQL service
        Write-Info "Removing MySQL service..."
        & sc.exe delete $mysqlService.Name 2>$null
        Write-Success "MySQL service removed"
    }
    else {
        Write-Skip "MySQL service not found"
    }
    
    # Drop test database if not keeping data
    if (-not $KeepData) {
        Write-Info "Attempting to drop test database..."
        $mysql = Get-Command mysql -ErrorAction SilentlyContinue
        if ($mysql) {
            # Try without password first
            & mysql -u root -e "DROP DATABASE IF EXISTS testdb; DROP USER IF EXISTS 'testuser'@'localhost';" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Test database 'testdb' and user 'testuser' removed"
            }
            else {
                Write-Warn "Could not connect to MySQL to drop database. You may need to do this manually."
            }
        }
    }
    else {
        Write-Skip "Keeping MySQL data (--KeepData specified)"
    }
}

# ============================================
# STEP 2: Uninstall Python Packages
# ============================================
if ($uninstallPython) {
    Write-SubHeader "Step 2: Uninstalling Python Packages"
    
    $pythonExe = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*WindowsApps*" }
    if ($pythonExe) {
        Write-Info "Removing mysql-connector-python..."
        & python -m pip uninstall mysql-connector-python -y 2>$null
        Write-Info "Removing pymysql..."
        & python -m pip uninstall pymysql -y 2>$null
        Write-Success "Python MySQL packages removed"
    }
    else {
        Write-Skip "Python not found, skipping package removal"
    }
}

# ============================================
# STEP 3: Uninstall Chocolatey Packages
# ============================================
Write-SubHeader "Step 3: Uninstalling Chocolatey Packages"

# Refresh PATH to ensure choco is accessible
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Java
if ($uninstallJava) {
    if ($All -or (Confirm-Action "Uninstall Java (Eclipse Temurin)?")) {
        Write-Info "Uninstalling Java..."
        & choco uninstall temurin21 temurin -y 2>$null
        & choco uninstall openjdk21 openjdk -y 2>$null
        Write-Success "Java uninstalled"
    }
    else {
        Write-Skip "Java"
    }
}

# Maven
if ($uninstallMaven) {
    if ($All -or (Confirm-Action "Uninstall Apache Maven?")) {
        Write-Info "Uninstalling Maven..."
        & choco uninstall maven -y 2>$null
        Write-Success "Maven uninstalled"
    }
    else {
        Write-Skip "Maven"
    }
}

# Gradle
if ($uninstallGradle) {
    if ($All -or (Confirm-Action "Uninstall Gradle?")) {
        Write-Info "Uninstalling Gradle..."
        & choco uninstall gradle -y 2>$null
        Write-Success "Gradle uninstalled"
    }
    else {
        Write-Skip "Gradle"
    }
}

# MinGW (C/C++)
if ($uninstallMingw) {
    if ($All -or (Confirm-Action "Uninstall MinGW (C/C++ Compiler)?")) {
        Write-Info "Uninstalling MinGW..."
        & choco uninstall mingw -y 2>$null
        Write-Success "MinGW uninstalled"
    }
    else {
        Write-Skip "MinGW"
    }
}

# Python
if ($uninstallPython) {
    if ($All -or (Confirm-Action "Uninstall Python?")) {
        Write-Info "Uninstalling Python..."
        # Cover all Python versions we might have installed
        & choco uninstall python python3 python38 python39 python310 python311 python312 python313 -y 2>$null
        Write-Success "Python uninstalled"
    }
    else {
        Write-Skip "Python"
    }
}

# MySQL
if ($uninstallMySQL) {
    if ($All -or (Confirm-Action "Uninstall MySQL Server and Workbench?")) {
        Write-Info "Uninstalling MySQL..."
        & choco uninstall mysql mysql.workbench -y 2>$null
        
        # Clean up MySQL data directory if not keeping data
        if (-not $KeepData) {
            $mysqlDataPaths = @(
                "C:\tools\mysql",
                "C:\ProgramData\MySQL",
                "$env:APPDATA\MySQL"
            )
            foreach ($path in $mysqlDataPaths) {
                if (Test-Path $path) {
                    Write-Info "Removing $path..."
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
        Write-Success "MySQL uninstalled"
    }
    else {
        Write-Skip "MySQL"
    }
}

# Git
if ($uninstallGit) {
    if ($All -or (Confirm-Action "Uninstall Git?")) {
        Write-Info "Uninstalling Git..."
        & choco uninstall git -y 2>$null
        Write-Success "Git uninstalled"
    }
    else {
        Write-Skip "Git"
    }
}

# VS Code
if ($uninstallVSCode) {
    if ($All -or (Confirm-Action "Uninstall Visual Studio Code?")) {
        Write-Info "Uninstalling VS Code..."
        & choco uninstall vscode -y 2>$null
        Write-Success "VS Code uninstalled"
    }
    else {
        Write-Skip "VS Code"
    }
}

# ============================================
# STEP 4: Remove Environment Variables
# ============================================
if ($uninstallEnvVars) {
    Write-SubHeader "Step 4: Removing Environment Variables"
    
    $envVarsToRemove = @("JAVA_HOME", "M2_HOME", "MYSQL_INCLUDE", "MYSQL_LIB")
    
    foreach ($var in $envVarsToRemove) {
        $currentValue = [System.Environment]::GetEnvironmentVariable($var, "Machine")
        if ($currentValue) {
            Write-Info "Removing $var..."
            [System.Environment]::SetEnvironmentVariable($var, $null, "Machine")
            Write-Success "$var removed"
        }
        else {
            Write-Skip "$var (not set)"
        }
    }
}

# ============================================
# STEP 5: Remove Downloaded Connectors
# ============================================
if ($uninstallConnectors) {
    Write-SubHeader "Step 5: Removing Downloaded Connectors"
    
    $libPath = "$ProjectRoot\lib"
    if (Test-Path $libPath) {
        $connectorFolders = @(
            "$libPath\mysql-connector-j",
            "$libPath\mysql-connector-c"
        )
        
        foreach ($folder in $connectorFolders) {
            if (Test-Path $folder) {
                Write-Info "Removing $folder..."
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
                Write-Success "$(Split-Path $folder -Leaf) removed"
            }
        }
    }
    else {
        Write-Skip "lib folder not found"
    }
}

# ============================================
# STEP 6: Clean Up Logs
# ============================================
Write-SubHeader "Step 6: Cleaning Up Logs"

$logsPath = "$ProjectRoot\logs"
if (Test-Path $logsPath) {
    Write-Info "Removing logs directory..."
    Remove-Item -Path $logsPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "Logs directory removed"
}
else {
    Write-Skip "Logs directory not found"
}

# ============================================
# STEP 7: Uninstall d1run (Global Installation)
# ============================================
if ($uninstallD1Run) {
    Write-SubHeader "Step 7: Uninstalling d1run"
    
    $d1runPath = "C:\Program Files\d1run"
    
    if (Test-Path $d1runPath) {
        if ($All -or (Confirm-Action "Uninstall d1run (global code runner)?")) {
            Write-Info "Removing d1run installation..."
            
            # Remove d1run from PATH safely
            Remove-FromSystemPath -PathsToRemove @($d1runPath)
            
            # Remove the d1run directory
            Remove-Item -Path $d1runPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Success "d1run uninstalled"
        }
        else {
            Write-Skip "d1run"
        }
    }
    else {
        Write-Skip "d1run not installed at $d1runPath"
    }
}

# ============================================
# STEP 8: Clean Known PATH Entries (SAFE)
# ============================================
Write-SubHeader "Step 8: Cleaning PATH Entries (Added by Installer)"

# ONLY remove paths that we know were added by this installer
# This is a whitelist approach - we will NEVER touch unknown paths
$knownPathsToRemove = @()

if ($uninstallMingw) {
    $knownPathsToRemove += @(
        "C:\ProgramData\mingw64\mingw64\bin",
        "C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin"
    )
}

if ($uninstallD1Run) {
    $knownPathsToRemove += @(
        "C:\Program Files\d1run"
    )
}

# Only attempt removal if we have paths to remove
if ($knownPathsToRemove.Count -gt 0) {
    Remove-FromSystemPath -PathsToRemove $knownPathsToRemove
}
else {
    Write-Skip "No installer-added PATH entries to clean"
}

# ============================================
# SUMMARY
# ============================================
Write-Header "Uninstallation Complete"

Write-Host @"
The following components have been processed:

  - Java (Eclipse Temurin / OpenJDK)
  - Apache Maven and Gradle (Java build tools)
  - MinGW-w64 (C/C++ Compiler)
  - Python and packages
  - MySQL Server and Workbench (if installed)
  - Git
  - Visual Studio Code
  - d1run (Universal Code Runner)
  - Environment variables (JAVA_HOME, M2_HOME, MYSQL_INCLUDE, MYSQL_LIB)
  - Downloaded MySQL connectors
  - Installation logs
  - PATH entries added by installer

"@ -ForegroundColor White

Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  1. Restart your computer to complete the uninstallation" -ForegroundColor White
Write-Host "  2. Chocolatey itself was NOT removed (it may be used by other software)" -ForegroundColor White
Write-Host "  3. Any projects you created using these tools are NOT affected" -ForegroundColor White
Write-Host "  4. System PATH backup was saved to logs folder before any modifications" -ForegroundColor White
Write-Host ""

if (-not $KeepData) {
    Write-Host "  Note: MySQL data directories have been removed." -ForegroundColor Yellow
}
else {
    Write-Host "  Note: MySQL data was preserved (--KeepData was specified)." -ForegroundColor Green
}

Write-Host ""
Write-Host "To reinstall, run: start.bat and choose Option 1" -ForegroundColor Cyan
Write-Host ""

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

