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
echo   UNIVERSAL CODE RUNNER ^& DEV ENVIRONMENT - SETUP
echo ========================================================
echo.
echo   1. FULL INSTALL (Recommended - Installs Everything + d1run)
echo      [Java, C, C++, Python, MySQL, Git, VS Code + d1run global + APM]
echo      [Auto-checks for updates before installation]
echo.
echo   2. Update Software (Check for updates)
echo   3. Install 'd1run' (Global Runner Only)
echo   4. Setup Database (Re-Initialize MySQL Schema)
echo   5. Verify System (Check all components)
echo   6. Run Tests (Validate languages with samples)
echo   7. Uninstall Everything
echo   8. Uninstall 'd1run' Only
echo   9. Exit
echo.
echo   NOTE: After Option 1, restart your PC. Then 'd1run file.cpp'
echo         will work from ANY new terminal!
echo.
echo ========================================================
:MENU_LOOP
set "choice="
set /p "choice=Select an option (1-9): "

if not defined choice goto MENU
if "%choice%"=="1" goto CHECK_UPDATE_THEN_INSTALL
if "%choice%"=="2" goto CHECK_UPDATE
if "%choice%"=="3" goto INSTALL_GLOBAL
if "%choice%"=="4" goto SETUP_DB
if "%choice%"=="5" goto VERIFY
if "%choice%"=="6" goto TEST
if "%choice%"=="7" goto UNINSTALL_ALL
if "%choice%"=="8" goto UNINSTALL_GLOBAL
if "%choice%"=="9" goto EXIT

echo.
echo   [ERROR] Invalid selection: %choice%
echo   Please enter a number between 1 and 9.
echo.
pause
goto MENU

:CHECK_UPDATE_THEN_INSTALL
cls
echo ========================================================
echo   CHECKING FOR UPDATES
echo ========================================================
echo.
echo   [INFO] Checking if a newer version is available...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\check-update.ps1"
echo.
echo   [INFO] Proceeding with installation...
echo.
goto INSTALL_ENV

:CHECK_UPDATE
cls
echo ========================================================
echo   SOFTWARE UPDATE
echo ========================================================
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\check-update.ps1"
echo.
pause
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
echo ========================================================
echo   DATABASE SETUP ^& CREDENTIALS
echo ========================================================
echo.
echo   [INFO] Default Credentials:
echo   - Root User: root (No Password)
echo   - App User:  appuser (Password: 72Je!^NY06OPx$uW)
echo   - Database:  testdb
echo.
echo   [INFO] Checking MySQL availability...

REM Check if MySQL is in PATH
where mysql >nul 2>&1
if %errorlevel% EQU 0 goto CHECK_SERVICE

REM Try to add MySQL to PATH from known locations
if exist "C:\tools\mysql\current\bin\mysql.exe" (
    set "PATH=%PATH%;C:\tools\mysql\current\bin"
    goto CHECK_SERVICE
)
if exist "C:\Program Files\MySQL\MySQL Server 9.2\bin\mysql.exe" (
    set "PATH=%PATH%;C:\Program Files\MySQL\MySQL Server 9.2\bin"
    goto CHECK_SERVICE
)

echo.
echo   [ERROR] MySQL client (mysql.exe) not found in PATH or default locations.
echo   Please ensure MySQL is installed (Option 1).
echo.
pause
goto MENU

:CHECK_SERVICE
echo   [INFO] MySQL client found. Checking if MySQL service is running...

REM Try a simple MySQL connection to see if server is running
mysql -u root --execute="SELECT 1" >nul 2>&1
if %errorlevel% EQU 0 goto START_SETUP

echo.
echo   [WARN] MySQL server is not responding.
echo   [INFO] Attempting to start MySQL service...
echo.

REM Try to start MySQL service
net start MySQL >nul 2>&1
if %errorlevel% EQU 0 (
    echo   [SUCCESS] MySQL service started!
    timeout /t 3 /nobreak >nul
    goto START_SETUP
)

REM If service doesn't exist, try to initialize and start MySQL
if exist "C:\tools\mysql\current\bin\mysqld.exe" (
    echo   [INFO] MySQL service not found. Initializing MySQL...
    
    REM Check if data directory exists
    if not exist "C:\tools\mysql\current\data" (
        echo   [INFO] Creating data directory and initializing MySQL...
        mkdir "C:\tools\mysql\current\data" 2>nul
        "C:\tools\mysql\current\bin\mysqld.exe" --initialize-insecure --basedir="C:\tools\mysql\current" --datadir="C:\tools\mysql\current\data"
        
        echo   [INFO] Installing MySQL as service...
        "C:\tools\mysql\current\bin\mysqld.exe" --install MySQL
        
        echo   [INFO] Starting MySQL service...
        net start MySQL
        timeout /t 5 /nobreak >nul
        
        REM Verify it works
        mysql -u root --execute="SELECT 1" >nul 2>&1
        if %errorlevel% EQU 0 (
            echo   [SUCCESS] MySQL initialized and started successfully!
            goto START_SETUP
        )
    )
) else (
    REM mysqld.exe not found - MySQL Server is not installed (only client)
    echo.
    echo   [ERROR] MySQL Server ^(mysqld.exe^) not found.
    echo.
    echo   [INFO] Only the MySQL client is installed, not the full server.
    echo   [INFO] Please run Option 1 to install the complete environment,
    echo          which will install MySQL Server with the full components.
    echo.
    pause
    goto MENU
)

REM If we got here, something went wrong with initialization
echo.
echo   [ERROR] Could not initialize or start MySQL server.
echo   [INFO] Please run Option 1 to fully reinstall the environment.
echo.
pause
goto MENU

:START_SETUP
echo   [INFO] Attempting automated setup...
echo.

REM Try to connect without password first
call mysql -u root --execute="source database\setup-database.sql" 2>nul
if %errorlevel% EQU 0 (
    echo.
    echo   [SUCCESS] Database setup completed successfully!
    echo   [INFO] user 'appuser' with password '72Je!^NY06OPx$uW' is ready.
    echo.
    pause
    goto MENU
)

echo   [WARN] Automated setup failed without password. 
echo   [INFO] If you have set a root password, please enter it below.
echo.
call mysql -u root -p --execute="source database\setup-database.sql"
if %errorlevel% EQU 0 (
    echo.
    echo   [SUCCESS] Database setup completed successfully!
    echo.
) else (
    echo.
    echo   [ERROR] Database setup failed (Error Level: %errorlevel%). 
    echo   Please ensure MySQL is running (Option 4 to check).
    echo.
)
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
