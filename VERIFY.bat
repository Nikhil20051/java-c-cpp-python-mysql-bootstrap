@echo off
echo Running verification script...
powershell -ExecutionPolicy Bypass -File "%~dp0verify-installation.ps1"
echo.
pause
