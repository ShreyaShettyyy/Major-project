@echo off
echo =====================================================================
echo                 Launching SignBridge Frontend (Chrome Web)           
echo =====================================================================
cd /d "%~dp0frontend"

:: Check Flutter command
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set FLUTTER_CMD=flutter
) else if exist "D:\flutter\bin\flutter.bat" (
    set FLUTTER_CMD="D:\flutter\bin\flutter.bat"
) else (
    echo [ERROR] Flutter SDK not found in PATH or at D:\flutter\bin\flutter.bat!
    echo Please install Flutter or add it to your system PATH.
    pause
    exit /b 1
)

echo Using Flutter at: %FLUTTER_CMD%
echo Launching Chrome Web app...
%FLUTTER_CMD% run -d chrome
pause
