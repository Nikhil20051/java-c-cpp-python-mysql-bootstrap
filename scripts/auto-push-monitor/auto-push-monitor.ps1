<#
.SYNOPSIS
    Auto-Push Monitor - Automatically pushes changes to GitHub when they exceed a threshold
    
.DESCRIPTION
    This script monitors a git repository folder and automatically pushes changes 
    to GitHub when the total line changes exceed a configurable threshold.
    
    The automatic pushes are made using a distinct bot identity, making them
    easily distinguishable from manual pushes while preserving your global git config.
    
.NOTES
    Author: Nikhil Bhardwaj
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
    LineThreshold        = 250
    CheckIntervalSeconds = 10
    Enabled              = $true
    ExcludePatterns      = @("*.log", "*.pid", "node_modules/*", ".git/*", "*.tmp")
    BotName              = "Code Preservation Bot"
    BotEmail             = "preservation-bot@dmj.one"
    AutoSync             = $true
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

function Update-ProjectVersion {
    param([string]$RepoPath)
    
    $versionFile = Join-Path $RepoPath "VERSION"
    $newVersionString = $null
    
    if (Test-Path $versionFile) {
        try {
            $content = Get-Content $versionFile -Raw
            # Match standard SemVer X.Y.Z
            if ($content -match "(\d+)\.(\d+)\.(\d+)") {
                $major = [int]$matches[1]
                $minor = [int]$matches[2]
                $patch = [int]$matches[3]
                
                # Increment with rollover logic (0-9)
                $patch++
                
                if ($patch -ge 10) {
                    $patch = 0
                    $minor++
                }
                
                if ($minor -ge 10) {
                    $minor = 0
                    $major++
                }
                
                $newVersionString = "$major.$minor.$patch"
                
                # Write back to file accurately
                Set-Content $versionFile -Value $newVersionString -NoNewline
                
                Write-Log "Bumped project version to $newVersionString" "SUCCESS"
            }
        }
        catch {
            Write-Log "Failed to update VERSION file: $_" "WARNING"
        }
    }
    return $newVersionString
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
        
        # HOOK: Run Workspace Cleanup
        # We clean the workspace before pushing to ensure no binaries/artifacts are committed
        $cleanupScript = Join-Path (Split-Path -Parent $ScriptDir) "clean-workspace.ps1"
        if (Test-Path $cleanupScript) {
            Write-Log "Running workspace cleanup before push..." "INFO"
            # Run cleanup and capture output to log if needed, or suppress
            try {
                & $cleanupScript *>$null
                Write-Log "Workspace cleanup completed." "SUCCESS"
            }
            catch {
                Write-Log "Workspace cleanup failed: $_" "WARNING"
            }
        }

        # HOOK: Update Project Statistics
        $statsScript = Join-Path (Split-Path -Parent $ScriptDir) "count_lines.py"
        if (Test-Path $statsScript) {
            Write-Log "Updating project statistics..." "INFO"
            try {
                $pyCmd = if (Get-Command "python" -ErrorAction SilentlyContinue) { "python" } elseif (Get-Command "python3" -ErrorAction SilentlyContinue) { "python3" } else { $null }
                
                if ($pyCmd) {
                    & $pyCmd "$statsScript" *>$null
                    Write-Log "Project statistics updated." "SUCCESS"
                }
                else {
                    Write-Log "Python not found. Skipping stats update." "WARNING"
                }
            }
            catch {
                Write-Log "Statistics update failed: $_" "WARNING"
            }
        }

        # Update version before adding files
        $currentVersion = Update-ProjectVersion -RepoPath $RepoPath
        
        git add -A 2>$null
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $versionTag = if ($currentVersion) { "[v$currentVersion]" } else { "" }
        
        # Use a temporary file for the commit message
        $msgFile = [System.IO.Path]::GetTempFileName()
        
        try {
            # 1. Concise Header (Reviewable at a glance)
            "[AUTO-PRESERVE] $versionTag Saved $TotalChanges lines across $($ChangedFiles.Count) files" | Set-Content $msgFile -Encoding UTF8
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
            elseif ($pushResult -match "refusing to allow .* workflow") {
                Write-Log "PERMISSION ISSUE: Token lacks 'workflow' scope. Excluding workflow files..." "WARNING"
                
                # Undo the failed commit
                git reset --soft HEAD~1 2>$null
                
                # Unstage workflow files
                git reset HEAD .github/workflows 2>$null
                
                # Check for remaining changes
                $remainingChanges = git diff --cached --name-only
                
                if ($remainingChanges) {
                    # Re-commit safe files
                    $safeMsg = "Auto-push (workflow files excluded due to permissions)`n`nOriginal trigger: $TotalChanges lines changed."
                    $safeMsgFile = [System.IO.Path]::GetTempFileName()
                    Set-Content $safeMsgFile -Value $safeMsg
                    
                    git -c "user.name=$BotName" -c "user.email=$BotEmail" commit -F $safeMsgFile >$null 2>&1
                    Remove-Item $safeMsgFile -Force -ErrorAction SilentlyContinue
                    
                    # Retry Push
                    $retryResult = git push origin HEAD 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "Successfully pushed changes (workflow files excluded)" "SUCCESS"
                        return $true
                    }
                    else {
                        Write-Log "Retry failed: $retryResult" "ERROR"
                        git reset --soft HEAD~1 2>$null
                        return $false
                    }
                }
                else {
                    Write-Log "Only workflow files changed. Cannot push without permissions." "WARNING"
                    return $false
                }
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

function Invoke-AutoSync {
    param([string]$RepoPath)
    
    Push-Location $RepoPath
    try {
        # Get current branch
        $branch = git branch --show-current
        if (-not $branch) { return $true } # Detached HEAD or empty
        
        # Check for remote updates quietly
        git fetch origin -q 2>$null
        
        # Check if behind
        $upstream = "origin/$branch"
        $behind = git rev-list HEAD..$upstream --count 2>$null
        
        if ($behind -and [int]$behind -gt 0) {
            Write-Log "Remote changes detected ($behind commits). Syncing..." "WARNING"
            
            # Attempt safe sync
            # We use --rebase --autostash to handle dirty working directories gracefully
            # This preserves local uncommitted work while applying remote updates
            $syncResult = git pull --rebase --autostash origin $branch 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Sync completed successfully." "SUCCESS"
                return $true
            }
            else {
                # Check if rebase failed (conflict)
                if (Test-Path .git/rebase-merge -Or (Test-Path .git/rebase-apply)) {
                    git rebase --abort 2>&1 | Out-Null
                }
                Write-Log "Sync failed due to conflict. Preserving local work." "ERROR"
                Write-Log "Manual 'git pull' required to resolve conflicts." "WARNING"
                return $false
            }
        }
    }
    catch {
        Write-Log "Sync check failed: $_" "WARNING"
    }
    finally {
        Pop-Location
    }
    return $true
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
    
    # Check if .git directory exists
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
    
    # Robust script path detection for Hot-Reload
    # We prefer PSScriptRoot as it's cleaner for file-based scripts
    $ScriptPath = Join-Path $PSScriptRoot "auto-push-monitor.ps1"
    
    # Verify the path exists and is a file
    if (-not (Test-Path $ScriptPath -PathType Leaf)) {
        # Fallback to Definition only if it is an ExternalScript (path)
        if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
            $ScriptPath = $MyInvocation.MyCommand.Definition
        }
        else {
            $ScriptPath = $null
        }
    }
    
    # Store initial modification time safely
    $lastModTime = $null
    if ($ScriptPath -and (Test-Path $ScriptPath -PathType Leaf)) {
        $lastModTime = (Get-Item $ScriptPath).LastWriteTime
    }
    else {
        Write-Log "Hot-reload disabled: Cannot determine effective script path." "WARNING"
    }

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
            # 0. Hot-Reload Check
            try {
                $currentModTime = (Get-Item $ScriptPath).LastWriteTime
                if ($currentModTime -ne $lastModTime) {
                    Write-Log "Source code updated. Reloading monitor..." "WARNING"
                    
                    # Release PID file so new instance can take over
                    if (Test-Path $PidFile) { Remove-Item $PidFile -Force -ErrorAction SilentlyContinue }
                    
                    # Spawn new instance in same window
                    # passing current config to preserve state
                    Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$ScriptPath`"", "-Start", "-TargetFolder", "`"$($config.TargetFolder)`"", "-LineThreshold", "$($config.LineThreshold)", "-CheckIntervalSeconds", "$($config.CheckIntervalSeconds)" -NoNewWindow
                    
                    exit
                }
            }
            catch {
                Write-Log "Failed to check self-update status: $_" "WARNING"
            }

            # 1. Sync Phase (if enabled)
            if ($config.AutoSync) {
                Invoke-AutoSync -RepoPath $config.TargetFolder | Out-Null
            }
            
            # 2. Check Local Changes
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
