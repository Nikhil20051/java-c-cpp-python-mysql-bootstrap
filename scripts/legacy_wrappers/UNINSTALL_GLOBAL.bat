@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM Uninstall d1run Globally
REM Removes 'd1run' from the system
REM ============================================

echo.
echo ========================================
echo   Uninstall d1run Globally
echo ========================================
echo.

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges!
    echo.
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

REM Run the PowerShell uninstaller
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\install-d1run-global.ps1" -Uninstall

pause
