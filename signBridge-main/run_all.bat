@echo off
setlocal enabledelayedexpansion
title SignBridge - Master Launcher

echo =====================================================================
echo                     SignBridge Master Launcher                      
echo =====================================================================
echo.
echo Please select an option:
echo   [1] Start Full Stack (Backend + Chrome Web App)
echo   [2] Start Backend Only (FastAPI on port 5000)
echo   [3] Start Frontend Only (Chrome Web App)
echo   [4] Start Frontend Only (Android Mobile Device via ADB)
echo   [5] Run Backend Diagnostic Tests
echo   [6] Exit
echo.
set /p opt="Enter your choice [1-6] (Default is 1): "
if "%opt%"=="" set opt=1

if "%opt%"=="1" goto run_both
if "%opt%"=="2" goto run_backend
if "%opt%"=="3" goto run_web
if "%opt%"=="4" goto run_mobile
if "%opt%"=="5" goto run_tests
if "%opt%"=="6" goto end
echo Invalid option selected.
pause
goto end

:run_both
echo.
echo Starting FastAPI Backend in a new window...
start "SignBridge Backend (Port 5000)" cmd /k "cd /d ""%~dp0"" && run_backend.bat"
timeout /t 3 /nobreak >nul
echo Starting Flutter Web Frontend in a new window...
start "SignBridge Web Frontend" cmd /k "cd /d ""%~dp0"" && run_web.bat"
echo.
echo =====================================================================
echo Backend and Frontend have been launched in separate windows!
echo Backend API Docs: http://127.0.0.1:5000/docs
echo Web Client:       Opening automatically in Chrome...
echo =====================================================================
goto end

:run_backend
cd /d "%~dp0"
call run_backend.bat
goto end

:run_web
cd /d "%~dp0"
call run_web.bat
goto end

:run_mobile
cd /d "%~dp0"
call run_mobile.bat
goto end

:run_tests
echo.
echo =====================================================================
echo               Running SignBridge Backend Unit Tests                  
echo =====================================================================
cd /d "%~dp0backend"
python -m unittest discover -s tests -v
pause
goto end

:end
