<#
    Copyright (c) 2026 dmj.one
    
    This software is part of the dmj.one initiative.
    Created by Nikhil Bhardwaj.
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Ensures all required configuration files exist for the development environment.
    This script creates missing gitignored files that are needed for the project to function.

.DESCRIPTION
    On a fresh installation (clone/download), certain files are gitignored and won't exist.
    This script ensures they are created with proper defaults or generated credentials.

.PARAMETER Force
    Force regeneration of all config files even if they exist

.EXAMPLE
    .\ensure-config-files.ps1
    .\ensure-config-files.ps1 -Force
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor Yellow
}

function Write-Success($text) {
    Write-Host "[SUCCESS] $text" -ForegroundColor Green
}

function Write-ErrorMsg($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Write-Header($text) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

Write-Header "Ensuring Configuration Files Exist"

$filesCreated = 0
$filesExisted = 0

# ============================================
# 1. Create logs directory
# ============================================
$logsDir = Join-Path $ProjectRoot "logs"
if (!(Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Success "Created: logs/"
    $filesCreated++
}
else {
    Write-Info "Exists: logs/"
    $filesExisted++
}

# ============================================
# 2. Create auto-push-monitor runtime files directory
# ============================================
$monitorDir = Join-Path $ProjectRoot "scripts\auto-push-monitor"
if (!(Test-Path $monitorDir)) {
    New-Item -ItemType Directory -Path $monitorDir -Force | Out-Null
    Write-Success "Created: scripts/auto-push-monitor/"
    $filesCreated++
}

# Monitor PID file (placeholder - will be created when monitor runs)
$pidFile = Join-Path $monitorDir "monitor.pid"
if (!(Test-Path $pidFile)) {
    "" | Out-File $pidFile -Encoding UTF8
    Write-Success "Created: scripts/auto-push-monitor/monitor.pid (placeholder)"
    $filesCreated++
}

# Monitor log file (placeholder)
$monitorLog = Join-Path $monitorDir "monitor.log"
if (!(Test-Path $monitorLog)) {
    "# Auto-push monitor log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $monitorLog -Encoding UTF8
    Write-Success "Created: scripts/auto-push-monitor/monitor.log"
    $filesCreated++
}

# ============================================
# 3. Create .credentials-backup directory
# ============================================
$backupDir = Join-Path $ProjectRoot ".credentials-backup"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Success "Created: .credentials-backup/"
    $filesCreated++
}
else {
    Write-Info "Exists: .credentials-backup/"
    $filesExisted++
}

# ============================================
# 4. Create/Initialize .credentials.json
# ============================================
$credentialsFile = Join-Path $ProjectRoot ".credentials.json"
if (!(Test-Path $credentialsFile) -or $Force) {
    Write-Info "Initializing credentials..."
    
    # Call the credentials manager to initialize
    $credManager = Join-Path $PSScriptRoot "credentials-manager.ps1"
    if (Test-Path $credManager) {
        if ($Force) {
            & $credManager -Action Init -Force
        }
        else {
            & $credManager -Action Init
        }
        $filesCreated++
    }
    else {
        Write-ErrorMsg "credentials-manager.ps1 not found!"
    }
}
else {
    Write-Info "Exists: .credentials.json"
    $filesExisted++
    
    # Verify credentials are valid and in sync
    $credManager = Join-Path $PSScriptRoot "credentials-manager.ps1"
    if (Test-Path $credManager) {
        & $credManager -Action Verify
    }
}

# ============================================
# 5. Create .env file if missing
# ============================================
$envFile = Join-Path $ProjectRoot ".env"
if (!(Test-Path $envFile)) {
    Write-Info ".env file missing - will be created by credentials manager"
    
    # If credentials exist, create .env from them
    $credentialsFile = Join-Path $ProjectRoot ".credentials.json"
    if (Test-Path $credentialsFile) {
        try {
            $creds = Get-Content $credentialsFile | ConvertFrom-Json
            $envContent = @"
# Database Configuration (Auto-generated - DO NOT COMMIT)
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

DB_HOST=localhost
DB_PORT=3306
DB_NAME=$($creds.database)
DB_USER=$($creds.username)
DB_PASSWORD=$($creds.password)
DB_ROOT_USER=root
DB_ROOT_PASSWORD=

# For Java
MYSQL_USER=$($creds.username)
MYSQL_PASSWORD=$($creds.password)
MYSQL_DATABASE=$($creds.database)
"@
            $envContent | Out-File $envFile -Encoding UTF8
            Write-Success "Created: .env"
            $filesCreated++
        }
        catch {
            Write-ErrorMsg "Failed to read credentials: $_"
        }
    }
}
else {
    Write-Info "Exists: .env"
    $filesExisted++
}

# ============================================
# 6. Create .update-backup directory
# ============================================
$updateBackupDir = Join-Path $ProjectRoot ".update-backup"
if (!(Test-Path $updateBackupDir)) {
    New-Item -ItemType Directory -Path $updateBackupDir -Force | Out-Null
    Write-Success "Created: .update-backup/"
    $filesCreated++
}
else {
    Write-Info "Exists: .update-backup/"
    $filesExisted++
}

# ============================================
# 7. Create venv directory placeholder (.gitkeep)
# ============================================
$venvDir = Join-Path $ProjectRoot "venv"
# Don't create venv itself, just ensure it's noted as possible

# ============================================
# Summary
# ============================================
Write-Header "Configuration Files Check Complete"

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files/Directories Created: $filesCreated" -ForegroundColor Green
Write-Host "  Files/Directories Existed: $filesExisted" -ForegroundColor White
Write-Host ""

if ($filesCreated -gt 0) {
    Write-Host "New configuration files have been created." -ForegroundColor Yellow
    Write-Host "These files are gitignored and will not be uploaded to the repository." -ForegroundColor Yellow
}
Write-Host ""
