@echo off

powershell -Command "Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \".\sendMail.ps1\"' -WindowStyle Hidden"

REM del "%~f0"