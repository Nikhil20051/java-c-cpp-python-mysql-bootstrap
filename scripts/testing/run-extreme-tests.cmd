@REM Copyright (c) 2026 dmj.one
@REM Dynamic Test Suite Launcher
@echo off
setlocal

echo.
echo ======================================================================
echo   Dynamic Test Suite - Extreme Testing Framework
echo   Automatically Generates and Runs New Test Cases Each Time
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"

REM Parse arguments
set "LANGUAGE=all"
set "TEST_COUNT=10"
set "STRESS="
set "FUZZ="

:parse_args
if "%~1"=="" goto run_tests
if /I "%~1"=="python" set "LANGUAGE=python" & shift & goto parse_args
if /I "%~1"=="c" set "LANGUAGE=c" & shift & goto parse_args
if /I "%~1"=="cpp" set "LANGUAGE=cpp" & shift & goto parse_args
if /I "%~1"=="java" set "LANGUAGE=java" & shift & goto parse_args
if /I "%~1"=="all" set "LANGUAGE=all" & shift & goto parse_args
if /I "%~1"=="-count" set "TEST_COUNT=%~2" & shift & shift & goto parse_args
if /I "%~1"=="-stress" set "STRESS=-Stress" & shift & goto parse_args
if /I "%~1"=="-fuzz" set "FUZZ=-Fuzz" & shift & goto parse_args
shift
goto parse_args

:run_tests
echo   Language: %LANGUAGE%
echo   Test Count: %TEST_COUNT%
echo   Stress Mode: %STRESS%
echo   Fuzz Mode: %FUZZ%
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%dynamic-test-generator.ps1" -Language %LANGUAGE% -TestCount %TEST_COUNT% %STRESS% %FUZZ%

echo.
pause
