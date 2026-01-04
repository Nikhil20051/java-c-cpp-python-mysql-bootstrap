@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM d1run - Universal Code Runner
REM Usage: runall <filename> [args...]
REM ============================================

REM Redirect to the new d1run script
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\d1run-impl.ps1" %*
exit /b %ERRORLEVEL%
