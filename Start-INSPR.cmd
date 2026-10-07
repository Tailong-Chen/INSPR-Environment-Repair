@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0deployment\Start-INSPR.ps1" %*
if errorlevel 1 (
    echo.
    echo INSPR could not start. See the message above and deployment\logs.
    pause
    exit /b 1
)
endlocal
