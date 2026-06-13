@echo off
REM ============================================================
REM Incidium Digital Signage — Phase 1: System Preparation
REM Debloat, power plan, time sync, hosts file, purging
REM ============================================================
setlocal
set USB_DRIVE=%~d0
set INSTALL_DIR=C:\Incidium-Install
set LOGFILE=%INSTALL_DIR%\install.log
set ENGINE=%USB_DRIVE%\engine

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo. >> %LOGFILE%
echo [%DATE% %TIME%] ===== Phase 1: System Preparation ===== >> %LOGFILE%

echo.
echo ===================================================================
echo  Incidium Signage Installer — Phase 1: System Preparation
echo ===================================================================
echo.

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required. Right-click and "Run as Administrator".
    pause
    exit /b 1
)

REM --- Step 0: Pre-install snapshot ---
echo [0] Capturing pre-install inventory snapshot...
echo [%DATE% %TIME%] ===== PRE-INSTALL SNAPSHOT ===== > C:\Argus\pre-install-snapshot.txt
echo Hostname: %COMPUTERNAME% >> C:\Argus\pre-install-snapshot.txt
echo Date: %DATE% %TIME% >> C:\Argus\pre-install-snapshot.txt
echo. >> C:\Argus\pre-install-snapshot.txt
echo --- Installed Software --- >> C:\Argus\pre-install-snapshot.txt
powershell -ExecutionPolicy Bypass -Command "Get-Package -ProviderName Programs -IncludeWindowsInstaller -ErrorAction SilentlyContinue | Select-Object Name,Version | Format-Table -AutoSize -Wrap" >> C:\Argus\pre-install-snapshot.txt 2>&1
echo. >> C:\Argus\pre-install-snapshot.txt
echo --- Running Services --- >> C:\Argus\pre-install-snapshot.txt
sc query state= all | findstr /B "SERVICE_NAME DISPLAY_NAME STATE" >> C:\Argus\pre-install-snapshot.txt 2>&1
echo. >> C:\Argus\pre-install-snapshot.txt
echo --- Open Ports --- >> C:\Argus\pre-install-snapshot.txt
netstat -ano | findstr LISTEN >> C:\Argus\pre-install-snapshot.txt 2>&1
echo. >> C:\Argus\pre-install-snapshot.txt
echo --- Disk Info --- >> C:\Argus\pre-install-snapshot.txt
wmic logicaldisk get size,freespace,caption,volumename >> C:\Argus\pre-install-snapshot.txt 2>&1
echo [0] Snapshot saved: C:\Argus\pre-install-snapshot.txt
echo [%DATE% %TIME%] Pre-install snapshot saved >> %LOGFILE%

REM --- Step 1: Remove vendor bloat ---
echo [1] Removing vendor applications (Office, Adobe, Apple, Teams, Zoom, etc.)...
echo [%DATE% %TIME%] Removing vendor bloat... >> %LOGFILE%
powershell.exe -ExecutionPolicy Bypass -File "%ENGINE%\uninstall-bloat.ps1" >> %LOGFILE% 2>&1
echo [0] Vendor bloat removal complete.

REM --- Step 1a: Strip Windows bloatware ---
echo [1a] Removing Windows bloatware...
echo [%DATE% %TIME%] Removing bloatware... >> %LOGFILE%
powershell.exe -ExecutionPolicy Bypass -File "%ENGINE%\debloat-windows.ps1" >> %LOGFILE% 2>&1
echo [1a] Bloatware removal complete.

REM --- Step 1b: Purge temp files ---
echo [1b] Purging temporary files...
echo [%DATE% %TIME%] Purging temp files... >> %LOGFILE%
powershell.exe -Command "Get-ChildItem $env:USERPROFILE\AppData\Local\Temp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue" >> %LOGFILE% 2>&1
echo [1b] Temp files purged.

REM --- Step 2: Apply registry tweaks ---
echo [2] Applying registry tweaks (kiosk mode, UAC, auto-logon)...
call "%ENGINE%\reg-tweaks.cmd"
echo [2] Registry tweaks applied.

REM --- Step 3: Import Incidium power plan ---
echo [3] Importing Incidium power plan...
echo [%DATE% %TIME%] Importing power plan... >> %LOGFILE%
if exist "%ENGINE%\Incidium.pow" (
    powercfg /import "%ENGINE%\Incidium.pow" >nul 2>&1
    for /f "tokens=4 delims= " %%a in ('powercfg /l ^| find /i "Incidium"') do set INC_PLAN=%%a
    if defined INC_PLAN (
        powercfg /setactive "%INC_PLAN%" >nul 2>&1
        echo [3] Incidium power plan activated.
    ) else (
        echo [3] WARNING: Could not find Incidium power plan in system.
    )
) else (
    echo [3] WARNING: Incidium.pow not found, skipping.
)

REM --- Step 4: Time sync ---
echo [4] Configuring time sync...
echo [%DATE% %TIME%] Configuring NTP... >> %LOGFILE%
net start w32time >nul 2>&1
w32tm /config /update /manualpeerlist:"pool.ntp.org" /syncfromflags:MANUAL >nul 2>&1
w32tm /resync >nul 2>&1
echo [4] NTP configured.

REM --- Step 5: Copy hosts file ---
echo [5] Updating hosts file...
echo [%DATE% %TIME%] Copying hosts file... >> %LOGFILE%
if exist "%ENGINE%\hosts" (
    copy /Y "%ENGINE%\hosts" "%WINDIR%\System32\drivers\etc\hosts" >> %LOGFILE% 2>&1
    echo [5] Hosts file updated.
) else (
    echo [5] No custom hosts file found, skipping.
)

REM --- Summary ---
echo.
echo ===================================================================
echo  Phase 1 complete. Log: %LOGFILE%
echo ===================================================================
echo.

exit /b 0