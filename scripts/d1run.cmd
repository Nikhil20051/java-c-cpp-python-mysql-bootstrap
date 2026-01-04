@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM d1run - Universal Code Runner
REM Usage: d1run [filename] [options]
REM All parameters are optional!
REM ============================================

REM Get the directory where this script is located
set "D1RUN_SCRIPT_DIR=%~dp0"

REM Check if we already confirmed bypass for this session
if "%D1RUN_CONFIRMED%"=="1" goto RUN

:ASK
echo script execution policy check:
set /P "AREYOUSURE=Allow d1run to bypass execution policy for this session? (Y/N) "
if /I "%AREYOUSURE%"=="Y" (
    set "D1RUN_CONFIRMED=1"
    goto RUN
)
echo Action cancelled.
exit /b 1

:RUN
REM Execute the PowerShell script with all arguments
powershell -ExecutionPolicy Bypass -NoProfile -File "%D1RUN_SCRIPT_DIR%d1run-impl.ps1" %*

exit /b %ERRORLEVEL%
