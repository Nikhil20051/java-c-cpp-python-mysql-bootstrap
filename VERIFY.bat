@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
echo Running verification script...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\verify-installation.ps1"
echo.
pause

