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

# 1. Clean Dynamic Tests
# This is the primary target: the folder filled with generated tests
$generatedTests = Join-Path $ScriptRoot "tests\generated"
Remove-FolderContents -Path $generatedTests

# 2. Clean Java Artifacts
Remove-Files -Path (Join-Path $ScriptRoot "samples\java") -Filter "*.class"

# 3. Clean C/C++ Artifacts
$cDir = Join-Path $ScriptRoot "samples\c"
Remove-Files -Path $cDir -Filter "*.exe"
Remove-Files -Path $cDir -Filter "*.o"
Remove-Files -Path $cDir -Filter "*.obj"
Remove-Files -Path $cDir -Filter "libmysql.dll"

$cppDir = Join-Path $ScriptRoot "samples\cpp"
Remove-Files -Path $cppDir -Filter "*.exe"
Remove-Files -Path $cppDir -Filter "*.o"
Remove-Files -Path $cppDir -Filter "*.obj"
Remove-Files -Path $cppDir -Filter "libmysql.dll"

# 4. Clean Python Artifacts
$pyCache = Join-Path $ScriptRoot "samples\python\__pycache__"
if (Test-Path $pyCache) {
    Write-Host "Cleaning Python cache..." -ForegroundColor Yellow
    Remove-Item -Path $pyCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed __pycache__" -ForegroundColor Gray
}

# 5. Clean maven/gradle target/build directories if they exist
$mavenTarget = Join-Path $ScriptRoot "samples\java\maven-demo\target"
if (Test-Path $mavenTarget) {
    Write-Host "Cleaning Maven target..." -ForegroundColor Yellow
    Remove-Item -Path $mavenTarget -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed maven-demo\target" -ForegroundColor Gray
}

$gradleBuild = Join-Path $ScriptRoot "samples\java\gradle-demo\build"
if (Test-Path $gradleBuild) {
    Write-Host "Cleaning Gradle build..." -ForegroundColor Yellow
    Remove-Item -Path $gradleBuild -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed gradle-demo\build" -ForegroundColor Gray
}

$gradleBin = Join-Path $ScriptRoot "samples\java\gradle-demo\bin"
if (Test-Path $gradleBin) {
    Write-Host "Cleaning Gradle bin..." -ForegroundColor Yellow
    Remove-Item -Path $gradleBin -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Removed gradle-demo\bin" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host ""
