@echo off
:: Auto-Push Monitor Launcher
:: Easy access to the monitor from the project root

cd /d "%~dp0scripts\auto-push-monitor"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "auto-push-monitor.ps1" %*
cd /d "%~dp0"
