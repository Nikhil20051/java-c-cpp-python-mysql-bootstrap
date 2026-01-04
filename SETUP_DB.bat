@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
echo ============================================
echo   Database Setup Utility
echo ============================================
echo.
echo Attempting to connect to MySQL to run setup-database.sql...
echo.

REM Try to connect without password first (default for fresh install)
mysql -u root -e "source setup-database.sql" 2>nul
if %errorlevel% EQU 0 (
    echo.
    echo [SUCCESS] Database set up successfully with no password!
    goto :End
)

echo [INFO] Could not connect without password.
echo Please enter your MySQL root password below:
mysql -u root -p -e "source setup-database.sql"

if %errorlevel% EQU 0 (
    echo.
    echo [SUCCESS] Database set up successfully!
) else (
    echo.
    echo [ERROR] Failed to set up database. Please check your password.
    echo If you haven't installed MySQL yet, run INSTALL.bat first.
)

:End
echo.
pause

