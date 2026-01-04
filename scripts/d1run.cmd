@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM d1run v3.1 - Universal Code Runner
REM Usage: d1run [filename] [arguments...]
REM 
REM Features:
REM   - Python: Auto-create venv + install requirements.txt
REM   - C/C++: Auto-install missing dependencies via vcpkg
REM   - Automatic execution policy bypass (no prompts!)
REM ============================================

REM Get the directory where this script is located
set "D1RUN_SCRIPT_DIR=%~dp0"

REM Execute directly with bypass - d1run is a trusted tool
powershell -ExecutionPolicy Bypass -NoProfile -File "%D1RUN_SCRIPT_DIR%d1run-impl.ps1" %*

exit /b %ERRORLEVEL%
