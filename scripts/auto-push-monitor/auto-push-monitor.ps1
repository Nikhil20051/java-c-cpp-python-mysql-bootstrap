<#
.SYNOPSIS
    Auto-Push Monitor - Automatically pushes changes to GitHub when they exceed a threshold
    
.DESCRIPTION
    This script monitors a git repository folder and automatically pushes changes 
    to GitHub when the total line changes exceed a configurable threshold.
    
    The automatic pushes are made using a distinct bot identity, making them
    easily distinguishable from manual pushes while preserving your global git config.
    
.NOTES
    Author: Auto-Push Monitor Module
    Version: 1.0.0
    
    PORTABLE MODULE: Copy this entire auto-push-monitor folder to any project.
    
.EXAMPLE
    # Start monitoring (uses config.json settings)
    .\auto-push-monitor.ps1 -Start
    
    # Start monitoring a specific folder
    .\auto-push-monitor.ps1 -Start -TargetFolder D:\MyProject
    
    # Stop monitoring
    .\auto-push-monitor.ps1 -Stop
    
    # Check status
    .\auto-push-monitor.ps1 -Status
    
    # Configure settings
    .\auto-push-monitor.ps1 -Configure
#>

[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'Start')]
    [switch]$Start,
    
    [Parameter(ParameterSetName = 'Stop')]
    [switch]$Stop,
    
    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,
    
    [Parameter(ParameterSetName = 'Configure')]
    [switch]$Configure,
    
    [Parameter(ParameterSetName = 'Start')]
    [string]$TargetFolder,
    
    [Parameter(ParameterSetName = 'Start')]
    [int]$LineThreshold,
    
    [Parameter(ParameterSetName = 'Start')]
    [int]$CheckIntervalSeconds
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigFile = Join-Path $ScriptDir "config.json"
$PidFile = Join-Path $ScriptDir "monitor.pid"
$LogFile = Join-Path $ScriptDir "monitor.log"

# Default configuration
$DefaultConfig = @{
    TargetFolder         = (Split-Path -Parent (Split-Path -Parent $ScriptDir))
    LineThreshold        = 500
    CheckIntervalSeconds = 30
    Enabled              = $true
    ExcludePatterns      = @("*.log", "*.pid", "node_modules/*", ".git/*", "*.tmp")
    BotName              = "Code Preservation Bot"
    BotEmail             = "preservation-bot@dmj.one"
}

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

function Get-Config {
    if (Test-Path $ConfigFile) {
        try {
            $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
            foreach ($key in $DefaultConfig.Keys) {
                if (-not (Get-Member -InputObject $config -Name $key -MemberType Properties)) {
                    $config | Add-Member -NotePropertyName $key -NotePropertyValue $DefaultConfig[$key]
                }
            }
            return $config
        }
        catch {
            Write-Log "Failed to read config, using defaults: $_" "WARNING"
            return [PSCustomObject]$DefaultConfig
        }
    }
    return [PSCustomObject]$DefaultConfig
}

function Save-Config {
    param([PSCustomObject]$Config)
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8
    Write-Log "Configuration saved to $ConfigFile" "SUCCESS"
}

function Get-UnstagedChanges {
    param([string]$RepoPath)
    
    Push-Location $RepoPath
    try {
        $diffOutput = git diff --numstat 2>$null
        
        $totalAdded = 0
        $totalRemoved = 0
        $changedFiles = @()
        
        if ($diffOutput) {
            foreach ($line in $diffOutput) {
                if ($line -match '^(\d+|-)\s+(\d+|-)\s+(.+)$') {
                    $added = if ($matches[1] -eq '-') { 0 } else { [int]$matches[1] }
                    $removed = if ($matches[2] -eq '-') { 0 } else { [int]$matches[2] }
                    $file = $matches[3]
                    
                    $totalAdded += $added
                    $totalRemoved += $removed
                    $changedFiles += @{
                        File    = $file
                        Added   = $added
                        Removed = $removed
                    }
                }
            }
        }
        
        $untrackedFiles = git ls-files --others --exclude-standard 2>$null
        foreach ($file in $untrackedFiles) {
            if ($file -and (Test-Path (Join-Path $RepoPath $file))) {
                $lineCount = (Get-Content (Join-Path $RepoPath $file) -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
                if ($lineCount -gt 0) {
                    $totalAdded += $lineCount
                    $changedFiles += @{
                        File    = $file
                        Added   = $lineCount
                        Removed = 0
                        IsNew   = $true
                    }
                }
            }
        }
        
        return @{
            TotalAdded   = $totalAdded
            TotalRemoved = $totalRemoved
            TotalChanges = $totalAdded + $totalRemoved
            ChangedFiles = $changedFiles
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-AutoPush {
    param(
        [string]$RepoPath,
        [int]$TotalChanges,
        [array]$ChangedFiles,
        [string]$BotName,
        [string]$BotEmail
    )
    
    Push-Location $RepoPath
    try {
        Write-Log "Detected $TotalChanges line changes - initiating auto-push..." "WARNING"
        
        git add -A 2>$null
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Use a temporary file for the commit message
        $msgFile = [System.IO.Path]::GetTempFileName()
        
        try {
            # 1. Concise Header (Reviewable at a glance)
            "[AUTO-PRESERVE] Saved $TotalChanges lines across $($ChangedFiles.Count) files" | Set-Content $msgFile -Encoding UTF8
            "" | Add-Content $msgFile
            "Automated snapshot triggered by high-volume change." | Add-Content $msgFile
            "Timestamp: $timestamp" | Add-Content $msgFile
            "" | Add-Content $msgFile
            
            # 2. File Summary (The meaningful info)
            "CHANGED FILES:" | Add-Content $msgFile
            "--------------" | Add-Content $msgFile
            $stat = git diff --cached --stat 2>&1
            if ($stat) { 
                $stat | Add-Content $msgFile 
            }
            
            # 4. Commit using the file
            $commitResult = git -c "user.name=$BotName" -c "user.email=$BotEmail" commit -F $msgFile 2>&1
        }
        finally {
            if (Test-Path $msgFile) { Remove-Item $msgFile -Force -ErrorAction SilentlyContinue }
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Created commit with bot identity: $BotName" "SUCCESS"
            
            $pushResult = git push origin HEAD 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully pushed to remote repository" "SUCCESS"
                return $true
            }
            else {
                Write-Log "Failed to push: $pushResult" "ERROR"
                git reset --soft HEAD~1 2>$null
                return $false
            }
        }
        else {
            Write-Log "Failed to commit (may have no changes): $commitResult" "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Auto-push failed: $_" "ERROR"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Find-GitRoot {
    param([string]$StartPath)
    $current = $StartPath
    while ($current -and (Test-Path $current)) {
        if (Test-Path (Join-Path $current ".git")) {
            return $current
        }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break } # Root of drive
        $current = $parent
    }
    return $null
}

function Verify-GitSetup {
    param([string]$TargetFolder)
    
    if (-not (Test-Path (Join-Path $TargetFolder ".git"))) {
        Write-Host ""
        Write-Host "Warning: Git is not initialized in '$TargetFolder'" -ForegroundColor Yellow
        $choice = Read-Host "Do you want to initialize Git here? (Y/N)"
        
        if ($choice -match "^[Yy]") {
            Push-Location $TargetFolder
            try {
                git init
                Write-Host "Git initialized." -ForegroundColor Green
                
                $remoteUrl = Read-Host "Enter remote repository URL (or press Enter to skip)"
                if ($remoteUrl -and $remoteUrl.Trim().Length -gt 0) {
                    git remote add origin $remoteUrl
                    Write-Host "Remote 'origin' added." -ForegroundColor Green
                }
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "Cannot monitor a non-git folder. Aborting." -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function Start-Monitoring {
    param(
        [string]$Folder,
        [int]$Threshold,
        [int]$Interval
    )
    
    $config = Get-Config
    $ScriptLocation = $PSScriptRoot

    # 1. AUTO-DETECT LOGIC
    # If no folder passed, and config invalid (or we just suspect it might be stale), try to detect.
    # We prefer detection relative to THIS script to ensure portability.
    $detectedRoot = Find-GitRoot -StartPath $ScriptLocation
    
    # If detection failed, default to parent of script (common case: script inside repo)
    if (-not $detectedRoot) { 
        $detectedRoot = (Split-Path -Parent $ScriptLocation) 
    }

    # Determine candidate folder
    $candidateFolder = if ($Folder) { $Folder } else { $detectedRoot }
    
    # Get Remote URL for verification
    $remoteUrl = "No remote configured"
    if (Test-Path (Join-Path $candidateFolder ".git")) {
        $remoteUrl = git -C $candidateFolder remote get-url origin 2>$null
        if (-not $remoteUrl) { $remoteUrl = "No 'origin' remote found" }
    }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           AUTO-PUSH MONITOR - Setup                            " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "Auto-Detected Project Root:" -ForegroundColor Gray
    Write-Host "  Folder: $candidateFolder" -ForegroundColor Yellow
    Write-Host "  Remote: $remoteUrl" -ForegroundColor Yellow
    Write-Host ""
    
    # 2. USER CONFIRMATION
    $confirm = Read-Host "Is this the correct folder to monitor? (Y/n)"
    if ($confirm -match "^[Nn]") {
        $candidateFolder = Read-Host "Please enter the full path to the project root"
        if (-not (Test-Path $candidateFolder)) {
            Write-Host "Error: Path does not exist." -ForegroundColor Red
            return
        }
    }
    
    # Update config with confirmed folder
    $config.TargetFolder = $candidateFolder
    
    # 3. GIT VERIFICATION & SETUP WIZARD
    if (-not (Verify-GitSetup -TargetFolder $config.TargetFolder)) {
        return
    }

    # Apply other overrides
    if ($Threshold -gt 0) { $config.LineThreshold = $Threshold }
    if ($Interval -gt 0) { $config.CheckIntervalSeconds = $Interval }
    
    # Save validated config
    Save-Config $config

    # Check for existing instance and force restart
    if (Test-Path $PidFile) {
        $existingPid = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($existingPid) {
            $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
            if ($existingProcess) {
                Write-Host "Stopping existing monitor instance (PID: $existingPid)..." -ForegroundColor Yellow
                Stop-Process -Id $existingPid -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
            }
        }
        # Always remove stale or just-killed PID file
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           CODE PRESERVATION SYSTEM - Starting...               " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Target Folder : $($config.TargetFolder)" -ForegroundColor White
    Write-Host "  Line Threshold: $($config.LineThreshold)" -ForegroundColor White
    Write-Host "  Check Interval: $($config.CheckIntervalSeconds) seconds" -ForegroundColor White
    Write-Host "  Bot Identity  : $($config.BotName) <$($config.BotEmail)>" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $PID | Set-Content $PidFile
    
    Write-Log "Monitor started - watching $($config.TargetFolder)" "SUCCESS"
    
    try {
        while ($true) {
            $changes = Get-UnstagedChanges -RepoPath $config.TargetFolder
            
            if ($changes.TotalChanges -ge $config.LineThreshold) {
                Write-Log "Threshold exceeded! $($changes.TotalChanges) >= $($config.LineThreshold)" "WARNING"
                
                $result = Invoke-AutoPush -RepoPath $config.TargetFolder `
                    -TotalChanges $changes.TotalChanges `
                    -ChangedFiles $changes.ChangedFiles `
                    -BotName $config.BotName `
                    -BotEmail $config.BotEmail
                
                if ($result) {
                    Write-Log "Auto-push completed successfully" "SUCCESS"
                }
            }
            else {
                $timestamp = Get-Date -Format "HH:mm:ss"
                Write-Host "[$timestamp] Monitoring... Current changes: $($changes.TotalChanges) lines (threshold: $($config.LineThreshold))" -ForegroundColor Gray
            }
            
            Start-Sleep -Seconds $config.CheckIntervalSeconds
        }
    }
    finally {
        if (Test-Path $PidFile) {
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Monitor stopped" "WARNING"
    }
}

function Stop-Monitoring {
    if (Test-Path $PidFile) {
        $existingPid = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($existingPid) {
            $process = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
            if ($process) {
                Stop-Process -Id $existingPid -Force
                Write-Log "Monitor stopped (PID: $existingPid)" "SUCCESS"
            }
            else {
                Write-Log "Monitor process not found (stale PID file)" "WARNING"
            }
        }
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Log "No monitor is currently running" "WARNING"
    }
}

function Show-Status {
    $config = Get-Config
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           AUTO-PUSH MONITOR - Status                           " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    $isRunning = $false
    $existingPid = $null
    if (Test-Path $PidFile) {
        $existingPid = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
            $isRunning = $true
        }
    }
    
    if ($isRunning) {
        Write-Host "  Status        : RUNNING (PID: $existingPid)" -ForegroundColor Green
    }
    else {
        Write-Host "  Status        : STOPPED" -ForegroundColor Red
    }
    
    Write-Host "  Target Folder : $($config.TargetFolder)" -ForegroundColor White
    Write-Host "  Line Threshold: $($config.LineThreshold)" -ForegroundColor White
    Write-Host "  Check Interval: $($config.CheckIntervalSeconds) seconds" -ForegroundColor White
    Write-Host "  Bot Identity  : $($config.BotName) <$($config.BotEmail)>" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    
    if (Test-Path $config.TargetFolder) {
        $changes = Get-UnstagedChanges -RepoPath $config.TargetFolder
        Write-Host "  Current Changes: $($changes.TotalChanges) lines" -ForegroundColor White
        Write-Host "  Files Changed  : $($changes.ChangedFiles.Count)" -ForegroundColor White
        
        if ($changes.TotalChanges -ge $config.LineThreshold) {
            Write-Host "  Would Trigger  : YES - Would trigger auto-push!" -ForegroundColor Yellow
        }
        else {
            Write-Host "  Would Trigger  : No" -ForegroundColor White
        }
    }
    
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Commands:" -ForegroundColor Gray
    Write-Host "    -Start              Start monitoring" -ForegroundColor Gray
    Write-Host "    -Stop               Stop monitoring" -ForegroundColor Gray
    Write-Host "    -Configure          Interactive configuration" -ForegroundColor Gray
    Write-Host "    -Start -TargetFolder <path>  Monitor specific folder" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-Configure {
    $config = Get-Config
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "           AUTO-PUSH MONITOR - Configuration                    " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Current target folder: " -NoNewline
    Write-Host $config.TargetFolder -ForegroundColor Yellow
    $newFolder = Read-Host "Enter new folder path (or press Enter to keep current)"
    if ($newFolder -and (Test-Path $newFolder)) {
        $config.TargetFolder = $newFolder
    }
    elseif ($newFolder) {
        Write-Host "Invalid path, keeping current value" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Current line threshold: " -NoNewline
    Write-Host $config.LineThreshold -ForegroundColor Yellow
    $newThreshold = Read-Host "Enter new threshold (or press Enter to keep current)"
    if ($newThreshold -match '^\d+$') {
        $config.LineThreshold = [int]$newThreshold
    }
    
    Write-Host ""
    Write-Host "Current check interval: " -NoNewline
    Write-Host "$($config.CheckIntervalSeconds) seconds" -ForegroundColor Yellow
    $newInterval = Read-Host "Enter new interval in seconds (or press Enter to keep current)"
    if ($newInterval -match '^\d+$') {
        $config.CheckIntervalSeconds = [int]$newInterval
    }
    
    # Bot Name
    Write-Host ""
    Write-Host "Current Bot Name: " -NoNewline
    Write-Host "$($config.BotName)" -ForegroundColor Yellow
    $newName = Read-Host "Enter new Bot Name (or press Enter to keep current)"
    if ($newName -and $newName.Trim().Length -gt 0) {
        $config.BotName = $newName
    }
    
    # Bot Email
    Write-Host ""
    Write-Host "Current Bot Email: " -NoNewline
    Write-Host "$($config.BotEmail)" -ForegroundColor Yellow
    $newEmail = Read-Host "Enter new Bot Email (or press Enter to keep current)"
    if ($newEmail -and $newEmail.Trim().Length -gt 0) {
        $config.BotEmail = $newEmail
    }
    
    Save-Config $config
    
    Write-Host ""
    Write-Host "Configuration updated successfully!" -ForegroundColor Green
    Show-Status
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if (-not (Test-Path $ScriptDir)) {
    New-Item -ItemType Directory -Path $ScriptDir -Force | Out-Null
}

switch ($PSCmdlet.ParameterSetName) {
    'Start' {
        Start-Monitoring -Folder $TargetFolder -Threshold $LineThreshold -Interval $CheckIntervalSeconds
    }
    'Stop' {
        Stop-Monitoring
    }
    'Configure' {
        Invoke-Configure
    }
    default {
        Show-Status
    }
}
