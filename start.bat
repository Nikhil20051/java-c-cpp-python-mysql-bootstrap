@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
setlocal
title Universal Boostrap - dmj.one

:MENU
cls
echo ========================================================
echo   UNIVERSAL CODE RUNNER & DEV ENVIRONMENT - SETUP
echo ========================================================
echo.
echo   1. Install Complete Environment (Java, C, C++, Python, MySQL)
echo   2. Install 'd1run' Globally (Run code from anywhere)
echo   3. Setup Database (Initialize MySQL Schema)
echo   4. Verify Installation (Check all components)
echo   5. Run Tests (Validate languages with samples)
echo   6. Uninstall Everything
echo   7. Uninstall 'd1run' Only
echo   8. Exit
echo.
echo ========================================================
set "choice="
set /p choice="Select an option (1-8): "

if "%choice%"=="1" goto INSTALL_ENV
if "%choice%"=="2" goto INSTALL_GLOBAL
if "%choice%"=="3" goto SETUP_DB
if "%choice%"=="4" goto VERIFY
if "%choice%"=="5" goto TEST
if "%choice%"=="6" goto UNINSTALL_ALL
if "%choice%"=="7" goto UNINSTALL_GLOBAL
if "%choice%"=="8" goto EXIT
goto MENU

:INSTALL_ENV
cls
echo [INFO] launching Environment Installer...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\install-dev-environment.ps1"
pause
goto MENU

:INSTALL_GLOBAL
cls
echo [INFO] Installing d1run Globally...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\install-d1run-global.ps1"
pause
goto MENU

:SETUP_DB
cls
echo [INFO] Setting up Database...
echo Attempting to connect to MySQL to run database\setup-database.sql...
echo.

REM Try to connect without password first (default for fresh install)
mysql -u root -e "source database\setup-database.sql" 2>nul
if %errorlevel% EQU 0 (
    echo [SUCCESS] Database set up successfully!
    pause
    goto MENU
)

echo [INFO] Password required.
mysql -u root -p -e "source database\setup-database.sql"
pause
goto MENU

:VERIFY
cls
echo [INFO] Verifying Installation...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\verify-installation.ps1"
pause
goto MENU

:TEST
cls
echo [INFO] Running Tests...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\run-tests.ps1"
pause
goto MENU

:UNINSTALL_ALL
cls
echo [INFO] Uninstalling Environment...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\uninstall-dev-environment.ps1"
pause
goto MENU

:UNINSTALL_GLOBAL
cls
echo [INFO] Uninstalling d1run...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\install-d1run-global.ps1" -Uninstall
pause
goto MENU

:EXIT
exit /b 0
