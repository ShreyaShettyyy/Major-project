@echo off
echo =====================================================================
echo               Starting SignBridge FastAPI Backend Server             
echo =====================================================================
cd /d "%~dp0backend"

:: Check Python availability
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python was not found in your system PATH!
    echo Please ensure Python 3.11+ is installed and added to PATH.
    pause
    exit /b 1
)

echo Port: 5000
echo Documentation: http://127.0.0.1:5000/docs
echo Health Check:  http://127.0.0.1:5000/health
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload
pause
