@echo off
REM ============================================================
REM Incidium TightVNC Fix v2.0
REM
REM Uninstalls pre-installed TightVNC, then reinstalls with
REM correct password + remote access settings.
REM Run as Administrator on machines where VNC rejects connections.
REM ============================================================
setlocal
set USB_DRIVE=%~d0
set LOGFILE=%USB_DRIVE%\fix-tightvnc-%COMPUTERNAME%.log
set ENGINE=%USB_DRIVE%\engine

echo.
echo  Incidium TightVNC Fix v2.0
echo  ============================
echo.
echo  Log: %LOGFILE%
echo.

echo [%DATE% %TIME%] ===== TightVNC Fix v2.0 ===== > %LOGFILE%
echo [%DATE% %TIME%] Target: %COMPUTERNAME% >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  ERROR: Must run as Administrator.
    pause
    exit /b 1
)
echo [%DATE% %TIME%] Admin check OK >> %LOGFILE%

REM --- Step 1: Stop + remove existing TightVNC ---
echo [1] Removing previous TightVNC...
echo [%DATE% %TIME%] Removing previous TightVNC... >> %LOGFILE%
net stop tvnserver >> %LOGFILE% 2>&1
sc delete tvnserver >> %LOGFILE% 2>&1
if exist "%ENGINE%\tightvnc-2.8.63-gpl-setup-64bit.msi" (
    msiexec /x "%ENGINE%\tightvnc-2.8.63-gpl-setup-64bit.msi" /quiet /norestart >> %LOGFILE% 2>&1
    echo [1] MSI uninstall done.
)
reg delete "HKLM\SOFTWARE\TightVNC" /f >> %LOGFILE% 2>&1
echo [%DATE% %TIME%] Previous TightVNC removed >> %LOGFILE%

REM --- Step 2: Install fresh with correct password ---
echo [2] Installing TightVNC with Incidium password...
echo [%DATE% %TIME%] Installing TightVNC... >> %LOGFILE%
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
    echo [2] TightVNC installed with password.
    echo [%DATE% %TIME%] TightVNC installed >> %LOGFILE%
) else (
    echo [2] ERROR: tightvnc-2.8.63-gpl-setup-64bit.msi not found on USB!
    echo [%DATE% %TIME%] ERROR: MSI not found >> %LOGFILE%
    pause
    exit /b 1
)

REM --- Step 3: Registry fixes ---
echo [3] Applying remote access settings...
echo [%DATE% %TIME%] Registry settings... >> %LOGFILE%
reg add "HKLM\SOFTWARE\TightVNC\Server" /v AcceptSocketConnections /t REG_DWORD /d 1 /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\TightVNC\Server" /v LoopbackOnly /t REG_DWORD /d 0 /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\TightVNC\Server" /v ConnectPriority /t REG_DWORD /d 0 /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\TightVNC\Server" /v CaptureMethod /t REG_DWORD /d 1 /f >> %LOGFILE% 2>&1
echo [3] Settings applied.

REM --- Step 4: Auto-start + start service ---
echo [4] Starting TightVNC Server...
echo [%DATE% %TIME%] Starting service... >> %LOGFILE%
sc config tvnserver start=auto >> %LOGFILE% 2>&1
net start tvnserver >> %LOGFILE% 2>&1
sc query tvnserver | findstr STATE >> %LOGFILE% 2>&1
echo [%DATE% %TIME%] Service started >> %LOGFILE%

REM --- Step 5: Firewall ---
echo [5] Verifying firewall...
netsh advfirewall firewall add rule name="Incidium VNC 5900" dir=in action=allow protocol=TCP localport=5900 >> %LOGFILE% 2>&1
echo [5] Firewall OK.

REM --- Summary ---
echo [%DATE% %TIME%] ===== TightVNC Fix Complete ===== >> %LOGFILE%

REM --- Cloud logging ---
echo [6] Logging result to cloud...
powershell.exe -ExecutionPolicy Bypass -Command ^
    "$body = @{token='incidium-diag-2026'; hostname=$env:COMPUTERNAME; app='fix-tightvnc'; action='reinstall'; status='OK'; detail='Reinstall with password via MSI'} | ConvertTo-Json; try { $r = Invoke-RestMethod -Uri 'https://script.google.com/macros/s/AKfycbzMf_VBN-NyH604VDE1ZMnJWnB6bzNhU6N7CdY0Vy3SOjc-gDPgIuiH1zJLy2rRsGNY9A/exec' -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10; if ($r.status -eq 'ok') { echo '  [6] Cloud log: OK' } else { echo '  [6] Cloud log: ' + $r.error } } catch { echo '  [6] Cloud log: offline - ' + $_.Exception.Message }" >> %LOGFILE% 2>&1

echo.
echo ============================================================
echo  Fix applied. Log: %LOGFILE%
echo  VNC password: 547Mark!
echo ============================================================
pause