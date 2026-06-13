@echo off
REM ============================================================
REM Incidium Digital Signage — Phase 2: Software Installation
REM Chrome, VLC, TightVNC, Remote Access, BGInfo
REM All installers ship on the USB — no internet required.
REM ============================================================
setlocal
set USB_DRIVE=%~d0
set INSTALL_DIR=C:\Argus
set LOGFILE=%INSTALL_DIR%\install.log
set ENGINE=%USB_DRIVE%\engine

echo.
echo ===================================================================
echo  Incidium Signage Installer — Phase 2: Software Installation
echo ===================================================================
echo.
echo [%DATE% %TIME%] ===== Phase 2: Software Installation ===== >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required.
    pause
    exit /b 1
)

REM --- Step 1: Google Chrome ---
echo [1] Installing Google Chrome...
echo [%DATE% %TIME%] Installing Chrome... >> %LOGFILE%
if exist "%ENGINE%\ChromeStandaloneSetup64.exe" (
    "%ENGINE%\ChromeStandaloneSetup64.exe" /silent /install >> %LOGFILE% 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [1] Chrome installed.
    ) else (
        echo [1] WARNING: Chrome installer returned error %ERRORLEVEL%.
    )
) else (
    echo [1] WARNING: ChromeStandaloneSetup64.exe not found, attempting choco...
    REM Fallback: try chocolatey if drive has internet
    choco install googlechrome -y --ignore-checksums >> %LOGFILE% 2>&1
)
echo.

REM --- Step 2: VLC ---
echo [2] Installing VLC...
echo [%DATE% %TIME%] Installing VLC... >> %LOGFILE%
if exist "%ENGINE%\vlc-3.0.20-win64.exe" (
    "%ENGINE%\vlc-3.0.20-win64.exe" /S >> %LOGFILE% 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [2] VLC installed.
    ) else (
        echo [2] WARNING: VLC installer returned error %ERRORLEVEL%.
    )
) else (
    echo [2] WARNING: VLC offline installer not found, attempting choco...
    choco install vlc -y >> %LOGFILE% 2>&1
)

REM Copy VLC config if present
if exist "%ENGINE%\vlcrc" (
    for /d %%d in ("%USERPROFILE%\AppData\Roaming\vlc") do (
        if exist "%%d" copy /Y "%ENGINE%\vlcrc" "%%d\vlcrc" >> %LOGFILE% 2>&1
    )
    echo [2] VLC config deployed.
)
echo.

REM --- Step 3: TightVNC ---
echo [3] Installing TightVNC...
echo [%DATE% %TIME%] Installing TightVNC... >> %LOGFILE%
REM Uninstall any pre-existing TightVNC first (OEM pre-installed)
echo [3a] Removing any pre-existing TightVNC...
msiexec /x "%ENGINE%\tightvnc-2.8.63-gpl-setup-64bit.msi" /quiet /norestart >> %LOGFILE% 2>&1
net stop tvnserver >nul 2>&1
sc delete tvnserver >nul 2>&1
reg delete "HKLM\SOFTWARE\TightVNC" /f >nul 2>&1
echo [3a] Previous TightVNC removed.

echo [3b] Installing TightVNC fresh...
if exist "%ENGINE%\tightvnc-2.8.63-gpl-setup-64bit.msi" (
    msiexec /i "%ENGINE%\tightvnc-2.8.63-gpl-setup-64bit.msi" /quiet /norestart ^
        ADDLOCAL="Server,Viewer" ^
        VIEWER_ASSOCIATE_VNC_EXTENSION=1 ^
        SERVER_REGISTER_AS_SERVICE=1 ^
        SERVER_ADD_FIREWALL_EXCEPTION=1 ^
        VIEWER_ADD_FIREWALL_EXCEPTION=1 ^
        SERVER_ALLOW_SAS=1 ^
        SET_USEVNCAUTHENTICATION=1 ^
        VALUE_OF_USEVNCAUTHENTICATION=1 ^
        SET_PASSWORD=1 ^
        VALUE_OF_PASSWORD=547Mark! ^
        SET_USECONTROLAUTHENTICATION=1 ^
        VALUE_OF_USECONTROLAUTHENTICATION=1 ^
        SET_CONTROLPASSWORD=1 ^
        VALUE_OF_CONTROLPASSWORD=547Mark! >> %LOGFILE% 2>&1
    echo [3b] TightVNC installed.
) else (
    echo [3] WARNING: TightVNC MSI not found, skipping.
)
echo.

REM --- Step 4: Incidium Remote Access ---
echo [4] Installing Incidium Remote Access...
echo [%DATE% %TIME%] Installing Incidium Remote Access... >> %LOGFILE%
if exist "%ENGINE%\incidium-remote-access.msi" (
    msiexec /i "%ENGINE%\incidium-remote-access.msi" /quiet /norestart >> %LOGFILE% 2>&1
    echo [4] Incidium Remote Access installed.
) else (
    echo [4] WARNING: incidium-remote-access.msi not found, skipping.
)
echo.

REM --- Step 5: BGInfo ---
echo [5] Installing BGInfo desktop overlay...
echo [%DATE% %TIME%] Installing BGInfo... >> %LOGFILE%
if exist "%ENGINE%\BGInfo\Bginfo.exe" (
    if not exist "C:\BGInfo" mkdir "C:\BGInfo"
    xcopy /Y /E "%ENGINE%\BGInfo" "C:\BGInfo\" >> %LOGFILE% 2>&1

    REM Create scheduled task to refresh BGInfo every 10min
    schtasks /create /tn "BGInfoDesktopUpdater" ^
        /tr "'C:\BGInfo\BGInfo.exe' C:\BGInfo\incidium.bgi /timer:0 /nolicprompt" ^
        /sc DAILY /st 00:00 /f /RI 10 /du 24:00 >> %LOGFILE% 2>&1
    
    REM Run once to show immediately
    start "" "C:\BGInfo\BGInfo.exe" "C:\BGInfo\incidium.bgi" /timer:0 /nolicprompt
    
    echo [5] BGInfo desktop overlay installed.
) else (
    echo [5] BGInfo not bundled, skipping.
)
echo.

REM --- Step 6: Firewall rules ---
echo [6] Configuring firewall exceptions...
echo [%DATE% %TIME%] Configuring firewall... >> %LOGFILE%
netsh advfirewall firewall add rule name="Incidium VLC" dir=in action=allow program="C:\Program Files\VideoLAN\VLC\vlc.exe" enable=yes profile=any >> %LOGFILE% 2>&1
netsh advfirewall firewall add rule name="Incidium SnakeCharmer" dir=in action=allow program="C:\SnakeSpeareV6\SnakeCharmer.exe" enable=yes profile=any >> %LOGFILE% 2>&1

REM Open SSH port for fleet management
netsh advfirewall firewall add rule name="Incidium SSH 65122" dir=in action=allow protocol=TCP localport=65122 >> %LOGFILE% 2>&1

echo [6] Firewall configured.

REM --- Summary ---
echo.
echo ===================================================================
echo  Phase 2 complete. Log: %LOGFILE%
echo ===================================================================
echo.

exit /b 0