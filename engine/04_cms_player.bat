@echo off
REM ============================================================
REM Incidium Digital Signage — Phase 3: CMS Player
REM Deploy SnakeCharmer.exe + runtime, create startup shortcut
REM ============================================================
setlocal
set USB_DRIVE=%~d0
set LOGFILE=C:\Argus\install.log
set ENGINE=%USB_DRIVE%\engine

echo.
echo ===================================================================
echo  Incidium Signage Installer — Phase 3: CMS Player
echo ===================================================================
echo.
echo [%DATE% %TIME%] ===== Phase 3: CMS Player ===== >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required.
    pause
    exit /b 1
)

REM --- Step 1: Copy SnakeSpeareV6 folder to C:\ ---
echo [1] Deploying SnakeSpeareV6 CMS player...
echo [%DATE% %TIME%] Copying SnakeSpeareV6 to C:\... >> %LOGFILE%
if exist "%ENGINE%\snake-speare-v6" (
    if not exist "C:\SnakeSpeareV6" mkdir "C:\SnakeSpeareV6"
    xcopy /Y /E /I "%ENGINE%\snake-speare-v6\*" "C:\SnakeSpeareV6\" >> %LOGFILE% 2>&1
    if %ERRORLEVEL% LSS 4 (
        echo [1] SnakeSpeareV6 deployed to C:\SnakeSpeareV6\
    ) else (
        echo [1] ERROR: Failed to copy SnakeSpeareV6 files.
        pause
        exit /b 1
    )
) else (
    echo [1] ERROR: snake-speare-v6 folder not found on USB!
    pause
    exit /b 1
)

REM --- Step 2: Create SnakeCharmer scheduled task (auto-start, auto-restart) ---
echo [2] Creating SnakeCharmer scheduled task...
echo [%DATE% %TIME%] Creating scheduled task... >> %LOGFILE%
powershell.exe -ExecutionPolicy Bypass -Command ^
    "$u=$env:USERNAME; ^
     $a=New-ScheduledTaskAction -Execute 'C:\SnakeSpeareV6\SnakeCharmer.exe' -WorkingDirectory 'C:\SnakeSpeareV6'; ^
     $t=New-ScheduledTaskTrigger -AtLogOn -User $u; ^
     $p=New-ScheduledTaskPrincipal -UserId $u -LogonType Interactive -RunLevel Limited; ^
     $s=New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew -StartWhenAvailable; ^
     Register-ScheduledTask -TaskName 'Incidium SnakeCharmer' -Action $a -Trigger $t -Principal $p -Settings $s -Force" >> %LOGFILE% 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [2] Scheduled task created (auto-restart on crash)
    echo [%DATE% %TIME%] Scheduled task created >> %LOGFILE%
) else (
    echo [2] WARNING: Could not create scheduled task.
    echo [%DATE% %TIME%] Scheduled task failed >> %LOGFILE%
)

REM --- Step 3: Import WiFi profile (if present) ---
echo [3] Importing WiFi profiles...
echo [%DATE% %TIME%] Importing WiFi profiles... >> %LOGFILE%
if exist "%ENGINE%\*.xml" (
    for %%f in ("%ENGINE%\WiFi*.xml") do (
        netsh wlan add profile filename="%%f" user=all >> %LOGFILE% 2>&1
        echo [3] Imported %%~nxf
    )
)

REM --- Summary ---
echo.
echo ===================================================================
echo  Phase 3 complete. CMS player deployed to C:\SnakeSpeareV6\
echo ===================================================================
echo.

exit /b 0