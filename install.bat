@echo off
REM ai-common-rules one-click installer for Windows. Double-click to run.
REM Wraps install.ps1 so no execution-policy change or PowerShell window is needed.
REM Extra arguments pass through, e.g.  install.bat -SkipSuperpowers
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set EXITCODE=%ERRORLEVEL%
echo.
pause
exit /b %EXITCODE%
