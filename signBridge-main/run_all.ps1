# SignBridge Master PowerShell Launcher
param(
    [ValidateSet('both', 'backend', 'web', 'mobile', 'test')]
    [string]$Mode = 'menu'
)

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Menu {
    Clear-Host
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host "                    SignBridge Master Launcher                       " -ForegroundColor Yellow
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Start Full Stack (FastAPI Backend + Chrome Web App)" -ForegroundColor Green
    Write-Host "  [2] Start Backend Only (FastAPI on http://127.0.0.1:5000)" -ForegroundColor White
    Write-Host "  [3] Start Frontend Only (Chrome Web App)" -ForegroundColor White
    Write-Host "  [4] Start Frontend Only (Android Mobile with ADB Reverse)" -ForegroundColor White
    Write-Host "  [5] Run Backend Diagnostic Tests" -ForegroundColor White
    Write-Host "  [6] Exit" -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Enter your choice [1-6] (Default 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    return $choice
}

function Start-BackendWindow {
    Write-Host "Launching FastAPI Backend..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$RootDir/backend'; python -m uvicorn app.main:app --host 0.0.0.0 --port 5000 --reload"
}

function Start-WebWindow {
    Write-Host "Launching Flutter Web App..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$RootDir/frontend'; flutter run -d chrome"
}

function Start-Mobile {
    Write-Host "Forwarding port 5000 to ADB..." -ForegroundColor Yellow
    adb reverse tcp:5000 tcp:5000
    Set-Location "$RootDir/frontend"
    flutter run
}

function Run-Tests {
    Set-Location "$RootDir/backend"
    python -m unittest discover -s tests -v
}

if ($Mode -eq 'menu') {
    $sel = Show-Menu
    switch ($sel) {
        "1" { Start-BackendWindow; Start-Sleep -Seconds 3; Start-WebWindow }
        "2" { Start-BackendWindow }
        "3" { Start-WebWindow }
        "4" { Start-Mobile }
        "5" { Run-Tests }
        "6" { exit }
        default { Start-BackendWindow; Start-Sleep -Seconds 3; Start-WebWindow }
    }
} elseif ($Mode -eq 'both') {
    Start-BackendWindow
    Start-Sleep -Seconds 3
    Start-WebWindow
} elseif ($Mode -eq 'backend') {
    Start-BackendWindow
} elseif ($Mode -eq 'web') {
    Start-WebWindow
} elseif ($Mode -eq 'mobile') {
    Start-Mobile
} elseif ($Mode -eq 'test') {
    Run-Tests
}
