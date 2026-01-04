@REM Copyright (c) 2026 dmj.one
@REM
@REM This software is part of the dmj.one initiative.
@REM Created by Nikhil Bhardwaj.
@REM
@REM Licensed under the MIT License.
@echo off
REM ============================================
REM Universal Code Runner Wrapper
REM Usage: runall <filename> [args...]
REM ============================================

if "%~1"=="" (
    echo.
    echo Usage: runall ^<filename^> [args...]
    echo.
    echo Examples:
    echo   runall hello.py
    echo   runall MyProgram.java
    echo   runall test.c
    echo   runall program.cpp
    echo   runall query.sql
    echo.
    echo Supported: .py .java .c .cpp .js .ps1 .bat .sql
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy Bypass -File "%~dp0runall.ps1" %*

