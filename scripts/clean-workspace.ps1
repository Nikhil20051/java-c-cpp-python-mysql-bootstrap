<#
    Copyright (c) 2026 dmj.one
    
    Workspace Cleanup Script
    Created by dmj.one AI Assistant
    
    Licensed under the MIT License.
#>
<#
.SYNOPSIS
    Cleans up generated test artifacts and compiled binaries from the workspace.

.DESCRIPTION
    Removes dynamic test files, compiled classes, executables, logs, and temporary
    files generated during test runs to declutter the workspace.

.EXAMPLE
    .\clean-workspace.ps1
#>

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $PSScriptRoot

function Remove-Files {
    param($Path, $Filter, $Recurse = $false)
    
    if (Test-Path $Path) {
        $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse:$Recurse -File
        if ($files) {
            Write-Host "Cleaning $Path ($Filter)..." -ForegroundColor Yellow
            foreach ($file in $files) {
                try {
                    Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                    Write-Host "  Removed: $($file.Name)" -ForegroundColor Gray
                }
                catch {
                    Write-Host "  Failed to remove: $($file.Name)" -ForegroundColor Red
                }
            }
        }
    }
}

function Remove-FolderContents {
    param($Path)
    
    if (Test-Path $Path) {
        Write-Host "Cleaning directory: $Path..." -ForegroundColor Yellow
        $items = Get-ChildItem -Path $Path -Recurse
        if ($items) {
            $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "  Directory emptied." -ForegroundColor Gray
        }
        else {
            Write-Host "  Directory is already empty." -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  Cleaning Workspace Artifacts" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# 1. Clean Dynamic and Report Files
$generatedTests = Join-Path $ScriptRoot "tests\generated"
Remove-FolderContents -Path $generatedTests

$reportDir = Join-Path $ScriptRoot "tests\reports"
Remove-FolderContents -Path $reportDir

# 2. Recursive Clean in Samples Directory
$samplesDir = Join-Path $ScriptRoot "samples"
Write-Host "Recursively cleaning 'samples' directory..." -ForegroundColor Yellow

# Define patterns to nuke
$filePatterns_to_nuke = @(
    "*.class", 
    "*.exe", 
    "*.o", 
    "*.obj", 
    "*.dll", 
    "*.log", 
    "*.pyc",
    "*.pyd",
    ".DS_Store"
)

# Define directories to nuke (names only)
$dirNames_to_nuke = @(
    "__pycache__", 
    "venv", 
    ".venv", 
    "env", 
    ".env", 
    "target", 
    "build", 
    "bin", 
    ".gradle", 
    ".pytest_cache", 
    ".mypy_cache",
    "node_modules"
)

# 2a. Delete Files
foreach ($pattern in $filePatterns_to_nuke) {
    # Exclude libmysql.dll if it is inside the 'lib' folder, but here we are in 'samples' so it is fine to nuke dlls if they are generated/copied.
    # However, user might have put something important there? 
    # Usually in this repo, samples contain source code. 
    # We'll just be careful to not delete source files.
    
    $files = Get-ChildItem -Path $samplesDir -Include $pattern -Recurse -File -Force -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Host "  Removed File: $($file.FullName)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  [WARN] Failed to remove: $($file.FullName)" -ForegroundColor Red
        }
    }
}

# 2b. Delete Directories
# We do this carefully to avoid traversing into deleted directories
$dirs = Get-ChildItem -Path $samplesDir -Recurse -Directory -Force -ErrorAction SilentlyContinue | 
Where-Object { $dirNames_to_nuke -contains $_.Name } | 
Sort-Object -Property FullName -Descending # Sort descending depth-first to handle nested deletables safely

foreach ($dir in $dirs) {
    if (Test-Path $dir.FullName) {
        try {
            Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "  Removed Directory: $($dir.FullName)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  [WARN] Failed to remove directory: $($dir.FullName)" -ForegroundColor Red
        }
    }
}

# 3. Clean specific top-level generated logs if any exist in root (be careful not to delete essential ones)
# Just cleaning monitor.log as identified
$monitorLog = Join-Path $ScriptRoot "scripts\auto-push-monitor\monitor.log"
if (Test-Path $monitorLog) {
    Remove-Item -Path $monitorLog -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed monitor.log" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host ""

