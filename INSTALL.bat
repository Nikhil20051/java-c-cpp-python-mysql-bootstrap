@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM One-Click Development Environment Installer
REM For Windows 11
REM ============================================

echo.
echo ============================================
echo   Development Environment Bootstrap
echo   Windows 11 - One Click Installer
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

echo Starting installation...
echo This will install: Java, C, C++, Python, MySQL
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause >nul

REM Run the PowerShell installation script
powershell -ExecutionPolicy Bypass -File "%~dp0install-dev-environment.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Installation encountered errors.
    echo Check the log file for details.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Installation Complete!
echo ============================================
echo.
echo Next steps:
echo   1. Restart your computer
echo   2. Run verify-installation.ps1 to check installation
echo   3. Run setup-database.sql in MySQL
echo   4. Run run-tests.ps1 to test all languages
echo.
pause

