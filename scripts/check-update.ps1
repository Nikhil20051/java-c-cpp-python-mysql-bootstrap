# ========================================================================
# Auto-Update Script for Universal Bootstrap - dmj.one
# Copyright (c) 2026 dmj.one | Created by Nikhil Bhardwaj
# Licensed under the MIT License
# ========================================================================
#
# This script checks for updates from GitHub and updates the local files
# without requiring Git to be installed. Uses GitHub's REST API and raw
# file downloads.
#
# ========================================================================

param(
    [switch]$CheckOnly,      # Only check for updates, don't install
    [switch]$Force,          # Force update even if up-to-date
    [switch]$Silent          # Suppress prompts, auto-accept updates
)

# Configuration
$script:GITHUB_REPO = "Nikhil20051/java-c-cpp-python-mysql-bootstrap"
$script:GITHUB_RAW_BASE = "https://raw.githubusercontent.com/$script:GITHUB_REPO/main"
$script:GITHUB_API_BASE = "https://api.github.com/repos/$script:GITHUB_REPO"
$script:LOCAL_VERSION_FILE = Join-Path $PSScriptRoot "..\VERSION"
$script:PROJECT_ROOT = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# Colors for output
function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]
        [string]$Type = "Info"
    )
    
    $prefix = switch ($Type) {
        "Info" { "[INFO]"; break }
        "Success" { "[SUCCESS]"; break }
        "Warning" { "[WARN]"; break }
        "Error" { "[ERROR]"; break }
        "Header" { ""; break }
    }
    
    $color = switch ($Type) {
        "Info" { "Cyan"; break }
        "Success" { "Green"; break }
        "Warning" { "Yellow"; break }
        "Error" { "Red"; break }
        "Header" { "White"; break }
    }
    
    if ($prefix) {
        Write-Host "  $prefix " -ForegroundColor $color -NoNewline
        Write-Host $Message
    }
    else {
        Write-Host $Message -ForegroundColor $color
    }
}

function Show-Banner {
    Write-Host ""
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host "    UNIVERSAL BOOTSTRAP - AUTO UPDATE" -ForegroundColor Cyan
    Write-Host "    dmj.one Initiative | Created by Nikhil Bhardwaj" -ForegroundColor DarkCyan
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Get local version from VERSION file
function Get-LocalVersion {
    if (Test-Path $script:LOCAL_VERSION_FILE) {
        $versionContent = Get-Content $script:LOCAL_VERSION_FILE -Raw -ErrorAction SilentlyContinue
        if ($versionContent) {
            $versionContent = $versionContent.Trim()
            return $versionContent
        }
    }
    return $null
}

# Get remote version from GitHub
function Get-RemoteVersion {
    try {
        $versionUrl = "$script:GITHUB_RAW_BASE/VERSION"
        Write-ColorOutput "Fetching remote version from GitHub..." "Info"
        
        # Use TLS 1.2 for HTTPS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $response = Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
        $remoteVersion = $response.Content.Trim()
        return $remoteVersion
    }
    catch {
        Write-ColorOutput "Could not fetch remote version: $($_.Exception.Message)" "Warning"
        return $null
    }
}

# Get latest commit SHA from GitHub API
function Get-LatestCommitSha {
    try {
        $apiUrl = "$script:GITHUB_API_BASE/commits/main"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $headers = @{
            "Accept"     = "application/vnd.github.v3+json"
            "User-Agent" = "UniversalBootstrap-UpdateChecker"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        return $response.sha
    }
    catch {
        Write-ColorOutput "Could not fetch latest commit: $($_.Exception.Message)" "Warning"
        return $null
    }
}

# Get list of files to update from GitHub
function Get-RemoteFileList {
    try {
        $apiUrl = "$script:GITHUB_API_BASE/git/trees/main?recursive=1"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $headers = @{
            "Accept"     = "application/vnd.github.v3+json"
            "User-Agent" = "UniversalBootstrap-UpdateChecker"
        }
        
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 60 -ErrorAction Stop
        
        # Filter out directories and .git folder
        $files = $response.tree | Where-Object { 
            $_.type -eq "blob" -and 
            -not $_.path.StartsWith(".git/") -and
            $_.path -ne ".git"
        }
        
        return $files
    }
    catch {
        Write-ColorOutput "Could not fetch file list: $($_.Exception.Message)" "Error"
        return $null
    }
}

# Download a single file from GitHub
function Download-RemoteFile {
    param(
        [string]$RelativePath,
        [string]$DestinationPath
    )
    
    try {
        $url = "$script:GITHUB_RAW_BASE/$RelativePath"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Ensure directory exists
        $destDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Download file
        Invoke-WebRequest -Uri $url -OutFile $DestinationPath -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        return $true
    }
    catch {
        Write-ColorOutput "Failed to download $RelativePath : $($_.Exception.Message)" "Warning"
        return $false
    }
}

# Create backup of current files
function Backup-CurrentFiles {
    $backupDir = Join-Path $script:PROJECT_ROOT ".update-backup"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $backupDir $timestamp
    
    Write-ColorOutput "Creating backup at: $backupPath" "Info"
    
    try {
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        # Copy important files to backup
        $filesToBackup = @(
            "start.bat",
            "scripts",
            "database",
            "VERSION"
        )
        
        foreach ($item in $filesToBackup) {
            $sourcePath = Join-Path $script:PROJECT_ROOT $item
            if (Test-Path $sourcePath) {
                $destPath = Join-Path $backupPath $item
                if (Test-Path $sourcePath -PathType Container) {
                    Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                else {
                    $destDir = Split-Path $destPath -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        Write-ColorOutput "Backup created successfully!" "Success"
        return $backupPath
    }
    catch {
        Write-ColorOutput "Backup failed: $($_.Exception.Message)" "Warning"
        return $null
    }
}

# Main update function
function Update-FromGitHub {
    param(
        [switch]$SkipBackup
    )
    
    Write-ColorOutput "Starting update process..." "Info"
    Write-Host ""
    
    # Create backup unless skipped
    if (-not $SkipBackup) {
        $backupPath = Backup-CurrentFiles
    }
    
    # Get file list from GitHub
    Write-ColorOutput "Fetching file list from repository..." "Info"
    $remoteFiles = Get-RemoteFileList
    
    if (-not $remoteFiles) {
        Write-ColorOutput "Failed to get file list. Update aborted." "Error"
        return $false
    }
    
    $totalFiles = $remoteFiles.Count
    $updatedFiles = 0
    $failedFiles = 0
    $skippedFiles = 0
    
    Write-ColorOutput "Found $totalFiles files to sync..." "Info"
    Write-Host ""
    
    # Progress tracking
    $i = 0
    
    foreach ($file in $remoteFiles) {
        $i++
        $relativePath = $file.path
        $localPath = Join-Path $script:PROJECT_ROOT $relativePath
        
        # Skip .git and .github folders for user's local repo
        if ($relativePath.StartsWith(".git/") -or $relativePath -eq ".git") {
            $skippedFiles++
            continue
        }
        
        # Show progress
        $percentComplete = [math]::Round(($i / $totalFiles) * 100)
        Write-Progress -Activity "Updating files..." -Status "$relativePath" -PercentComplete $percentComplete
        
        # Download and update file
        $success = Download-RemoteFile -RelativePath $relativePath -DestinationPath $localPath
        
        if ($success) {
            $updatedFiles++
        }
        else {
            $failedFiles++
        }
    }
    
    Write-Progress -Activity "Updating files..." -Completed
    
    Write-Host ""
    Write-Host "  --------------------------------------------------------" -ForegroundColor Cyan
    Write-ColorOutput "Update Summary:" "Header"
    Write-Host "  --------------------------------------------------------" -ForegroundColor Cyan
    Write-ColorOutput "Files updated: $updatedFiles" "Success"
    if ($skippedFiles -gt 0) {
        Write-ColorOutput "Files skipped: $skippedFiles (system files)" "Info"
    }
    if ($failedFiles -gt 0) {
        Write-ColorOutput "Files failed: $failedFiles" "Warning"
    }
    Write-Host ""
    
    if ($failedFiles -eq 0) {
        Write-ColorOutput "Update completed successfully!" "Success"
        return $true
    }
    else {
        Write-ColorOutput "Update completed with some errors." "Warning"
        return $true
    }
}

# Compare versions and determine if update is needed
function Test-UpdateAvailable {
    $localVersion = Get-LocalVersion
    $remoteVersion = Get-RemoteVersion
    
    Write-Host ""
    
    if (-not $localVersion) {
        Write-ColorOutput "Local version not found (fresh install or VERSION file missing)" "Info"
        Write-ColorOutput "Local: Not available" "Info"
    }
    else {
        Write-ColorOutput "Local version:  $localVersion" "Info"
    }
    
    if (-not $remoteVersion) {
        Write-ColorOutput "Could not check remote version (no internet or repo issue)" "Warning"
        return $null
    }
    
    Write-ColorOutput "Remote version: $remoteVersion" "Info"
    Write-Host ""
    
    # Parse versions - format expected: MAJOR.MINOR.PATCH or commit hash
    if (-not $localVersion) {
        return @{
            UpdateAvailable = $true
            LocalVersion    = "Unknown"
            RemoteVersion   = $remoteVersion
            Reason          = "No local version found"
        }
    }
    
    if ($localVersion -ne $remoteVersion) {
        return @{
            UpdateAvailable = $true
            LocalVersion    = $localVersion
            RemoteVersion   = $remoteVersion
            Reason          = "Version mismatch"
        }
    }
    
    return @{
        UpdateAvailable = $false
        LocalVersion    = $localVersion
        RemoteVersion   = $remoteVersion
        Reason          = "Already up to date"
    }
}

# Main entry point
function Main {
    Show-Banner
    
    # Check for internet connectivity
    Write-ColorOutput "Checking internet connectivity..." "Info"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $testUrl = "https://github.com"
        $null = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 10 -Method Head -ErrorAction Stop
        Write-ColorOutput "Internet connection verified." "Success"
    }
    catch {
        Write-ColorOutput "No internet connection available." "Error"
        Write-ColorOutput "Please check your network connection and try again." "Info"
        Write-Host ""
        return $false
    }
    
    # Check for updates
    $updateStatus = Test-UpdateAvailable
    
    if ($null -eq $updateStatus) {
        Write-ColorOutput "Could not determine update status." "Error"
        return $false
    }
    
    if (-not $updateStatus.UpdateAvailable -and -not $Force) {
        Write-ColorOutput "Your software is up to date! (Version: $($updateStatus.LocalVersion))" "Success"
        Write-Host ""
        return $true
    }
    
    if ($updateStatus.UpdateAvailable) {
        Write-Host "  --------------------------------------------------------" -ForegroundColor Yellow
        Write-ColorOutput "UPDATE AVAILABLE!" "Warning"
        Write-Host "  --------------------------------------------------------" -ForegroundColor Yellow
        Write-ColorOutput "Current: $($updateStatus.LocalVersion)" "Info"
        Write-ColorOutput "Latest:  $($updateStatus.RemoteVersion)" "Info"
        Write-Host ""
    }
    
    if ($CheckOnly) {
        Write-ColorOutput "Check complete. Run without -CheckOnly to install update." "Info"
        Write-Host ""
        return $updateStatus.UpdateAvailable
    }
    
    # Prompt for confirmation unless silent mode
    if (-not $Silent) {
        Write-Host ""
        Write-Host "  Do you want to download and install the update? (Y/N): " -ForegroundColor Cyan -NoNewline
        $confirmation = Read-Host
        
        if ($confirmation -notmatch "^[Yy]") {
            Write-ColorOutput "Update cancelled by user." "Info"
            Write-Host ""
            return $false
        }
    }
    
    Write-Host ""
    
    # Perform update
    $success = Update-FromGitHub
    
    if ($success) {
        Write-Host ""
        Write-ColorOutput "Please restart any running scripts for changes to take effect." "Info"
        Write-Host ""
    }
    
    return $success
}

# Run main function
$result = Main
exit $(if ($result) { 0 } else { 1 })
