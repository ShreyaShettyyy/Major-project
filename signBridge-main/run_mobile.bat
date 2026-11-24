@echo off
echo =====================================================================
echo              Connecting Mobile Device to Backend (Port 5000)          
echo =====================================================================

:: Check ADB command
where adb >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set ADB_CMD=adb
) else if exist "D:\Android\sdk\platform-tools\adb.exe" (
    set ADB_CMD="D:\Android\sdk\platform-tools\adb.exe"
) else (
    set ADB_CMD=adb
)

:: Check Flutter command
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set FLUTTER_CMD=flutter
) else if exist "D:\flutter\bin\flutter.bat" (
    set FLUTTER_CMD="D:\flutter\bin\flutter.bat"
) else (
    set FLUTTER_CMD=flutter
)

echo Setting up ADB reverse port forwarding (5000 -^> 5000)...
%ADB_CMD% reverse tcp:5000 tcp:5000
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] ADB reverse failed or no Android device connected.
    echo If testing on an emulator or real device, ensure USB debugging is enabled.
) else (
    echo [SUCCESS] Port 5000 forwarded to connected Android device.
)

echo.
echo =====================================================================
echo                Launching SignBridge on Mobile Device                 
echo =====================================================================
cd /d "%~dp0frontend"
%FLUTTER_CMD% run
pause
