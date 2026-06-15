@echo off
REM ============================================================
REM Incidium Digital Signage — Phase 5: Identity & Reboot
REM Rename PC using CMS device ID, then reboot
REM ============================================================
setlocal
set LOGFILE=C:\Argus\install.log

echo.
echo ===================================================================
echo  Incidium Signage Installer — Phase 5: Hostname & Reboot
echo ===================================================================
echo.
echo [%DATE% %TIME%] ===== Phase 5: Hostname & Reboot ===== >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required.
    pause
    exit /b 1
)

REM --- Step 1: Detect device name from CMS registry ---
echo [1] Detecting device identity...
set DEVICE_NAME=
for /f "skip=2 tokens=2,*" %%a in ('reg query "HKCU\SOFTWARE\Incidium\SnakeCharmer" /v deviceName 2^>nul') do set DEVICE_NAME=%%b

if defined DEVICE_NAME (
    echo [1] CMS device name found: %DEVICE_NAME%
) else (
    echo [1] CMS device name not found. Using model-based naming.
    goto prompt_hostname
)

REM Extract suffix from deviceName (format: PREFIX_XXXX)
set HOSTNAME_PREFIX=B4ELITE
for /f "tokens=1 delims=_" %%a in ("%DEVICE_NAME%") do set HOSTNAME_PREFIX=%%a
for /f "tokens=2 delims=_" %%a in ("%DEVICE_NAME%") do set HOSTNAME_SUFFIX=%%a
set NEW_HOSTNAME=%HOSTNAME_PREFIX%-%HOSTNAME_SUFFIX%
echo [1] Generated hostname: %NEW_HOSTNAME%
goto do_rename

:prompt_hostname
echo [1] Could not auto-detect device name.
set /p HOSTNAME_INPUT="Enter desired hostname (e.g., B4ELITE-HPE26-01): "
if "%HOSTNAME_INPUT%"=="" (
    echo Hostname cannot be empty. Using HPE26-SIGNAGE.
    set NEW_HOSTNAME=HPE26-SIGNAGE
) else (
    set NEW_HOSTNAME=%HOSTNAME_INPUT%
)

:do_rename
echo.
echo [2] Renaming PC to: %NEW_HOSTNAME%
echo [%DATE% %TIME%] Renaming PC to %NEW_HOSTNAME%... >> %LOGFILE%

wmic computersystem where name="%COMPUTERNAME%" call rename "%NEW_HOSTNAME%" >> %LOGFILE% 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2] PC rename queued. Will apply on reboot.
) else (
    echo [2] WARNING: PC rename failed. Try manually.
)

REM --- Step 3: Create install-complete marker ---
echo [%DATE% %TIME%] Installation complete. Hostname: %NEW_HOSTNAME% > C:\Argus\COMPLETE.txt

REM --- Step 4: Prompt for reboot ---
echo.
echo ===================================================================
echo  Installation complete!
echo.
echo  Hostname will change to: %NEW_HOSTNAME%
echo  SnakeCharmer will auto-start on next boot.
echo.
echo  REBOOT REQUIRED to apply all changes.
echo ===================================================================
echo.
echo.
echo  Press ENTER to reboot the machine now (recommended)
echo  Close this window to skip reboot (manual reboot later)
echo.
pause >nul

echo [%DATE% %TIME%] Rebooting to complete installation... >> %LOGFILE%
shutdown /r /t 30 /c "Incidium signage install complete. Rebooting to apply changes."

exit /b 0