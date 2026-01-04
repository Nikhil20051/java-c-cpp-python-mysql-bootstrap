@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM Development Environment Uninstaller
REM For Windows 11
REM ============================================

echo.
echo ============================================
echo   Development Environment UNINSTALLER
echo   WARNING: This will REMOVE installed tools
echo ============================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges!
    echo.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Running with Administrator privileges
echo.

REM Change to script directory
cd /d "%~dp0"

echo This will uninstall: Java, C, C++, Python, MySQL, Git, VS Code
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

REM Run the PowerShell uninstallation script
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\uninstall-dev-environment.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Uninstallation encountered errors.
    pause
    exit /b 1
)

echo.
pause

