@echo off
REM ============================================================
REM Incidium Digital Signage — Phase 4: Fleet Agent
REM Deploy Argus telemetry daemon + OpenSSH
REM ============================================================
setlocal
set USB_DRIVE=%~d0
set LOGFILE=C:\Argus\install.log
set ENGINE=%USB_DRIVE%\engine

echo.
echo ===================================================================
echo  Incidium Signage Installer — Phase 4: Fleet Agent
echo ===================================================================
echo.
echo [%DATE% %TIME%] ===== Phase 4: Fleet Agent ===== >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Administrator privileges required.
    pause
    exit /b 1
)

REM --- Step 1: Create Argus directory structure ---
echo [1] Creating Argus agent directories...
echo [%DATE% %TIME%] Creating Argus directories... >> %LOGFILE%
if not exist "C:\Argus\bin" mkdir "C:\Argus\bin"
if not exist "C:\Argus\scripts" mkdir "C:\Argus\scripts"
if not exist "C:\Argus\config" mkdir "C:\Argus\config"
if not exist "C:\Argus\logs" mkdir "C:\Argus\logs"
echo [1] Argus directories created.

REM --- Step 2: Copy Argus binary ---
echo [2] Deploying Argus agent...
echo [%DATE% %TIME%] Copying argus.exe... >> %LOGFILE%
if exist "%ENGINE%\argus.exe" (
    copy /Y "%ENGINE%\argus.exe" "C:\Argus\bin\argus.exe" >> %LOGFILE% 2>&1
    echo [2] Argus agent binary deployed.
) else (
    echo [2] WARNING: argus.exe not found on USB. Skipping Argus install.
    goto ssh_setup
)

REM --- Step 3: Install as Windows service (NSSM style) ---
echo [3] Registering Argus as Windows service...
echo [%DATE% %TIME%] Registering Argus service... >> %LOGFILE%

REM Check if NSSM exists on system, otherwise use sc
sc query Argus >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [3] Argus service already exists, skipping registration.
) else (
    sc create Argus binPath="C:\Argus\bin\argus.exe" start=auto >> %LOGFILE% 2>&1
    sc description Argus "Incidium fleet telemetry and remote command agent" >> %LOGFILE% 2>&1
    sc failure ArgUS reset=86400 actions=restart/5000/restart/10000/restart/30000 >> %LOGFILE% 2>&1
    echo [3] Argus service registered with auto-restart.
)

REM --- Step 4: Configure Argus ---
echo [4] Configuring Argus endpoint...
echo [%DATE% %TIME%] Writing argus.env... >> %LOGFILE%
if exist "%ENGINE%\argus.env" (
    copy /Y "%ENGINE%\argus.env" "C:\Argus\config\argus.env" >> %LOGFILE% 2>&1
) else (
    REM Write default config — dual broker for redundancy
    (
        echo ARGUS_BROKER_ENDPOINT=wss://argus.incidium.net/ws/telemetry
        echo ARGUS_BROKER_FALLBACK=wss://hhr.incidium.net/ws/telemetry
        echo ARGUS_INTERVAL=30
        echo ARGUS_LOG_LEVEL=info
    ) > "C:\Argus\config\argus.env"
)
echo [4] Argus config written.

REM --- Step 5: Start service ---
echo [5] Starting Argus service...
echo [%DATE% %TIME%] Starting Argus service... >> %LOGFILE%
sc start Argus >> %LOGFILE% 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [5] Argus service started.
) else (
    echo [5] WARNING: Argus service failed to start. Check logs.
)

:ssh_setup

REM --- Step 6: OpenSSH Server on port 65122 ---
echo [6] Configuring OpenSSH on port 65122 (offline-safe)...
echo [%DATE% %TIME%] OpenSSH setup... >> %LOGFILE%

REM Check if OpenSSH is already installed
sc query sshd >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [6] OpenSSH Server already installed.
    goto config_ssh
)

REM Check if capability is available offline first
dism /online /Get-Capabilities 2>nul | find "OpenSSH.Server~~~~0.0.1.0" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [6] Installing OpenSSH Server...
    dism /online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 /quiet /LimitAccess >> %LOGFILE% 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo [6] WARNING: DISM OpenSSH install failed (offline?).
        echo [6] Trying online install...
        dism /online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 /quiet >> %LOGFILE% 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo [6] WARNING: OpenSSH Server install failed — skipping SSH setup.
            echo [6] Install manually later: dism /online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 /quiet
            goto ssh_done
        )
    )
) else (
    echo [6] WARNING: OpenSSH Server capability not found — skipping SSH setup.
    goto ssh_done
)

:config_ssh
REM Configure SSH for port 65122
if exist "%WINDIR%\System32\OpenSSH\sshd_config" (
    REM Replace or add Port directive
    powershell -Command "(Get-Content '%WINDIR%\System32\OpenSSH\sshd_config') -replace '^#?Port .*', 'Port 65122' | Set-Content '%WINDIR%\System32\OpenSSH\sshd_config'" >> %LOGFILE% 2>&1
) else (
    echo Port 65122 > "%ProgramData%\ssh\sshd_config"
    echo PubkeyAuthentication yes >> "%ProgramData%\ssh\sshd_config"
    echo PasswordAuthentication no >> "%ProgramData%\ssh\sshd_config"
    echo PermitEmptyPasswords no >> "%ProgramData%\ssh\sshd_config"
)

REM Ensure SSH service auto-starts
sc config sshd start=auto >> %LOGFILE% 2>&1
sc start sshd >> %LOGFILE% 2>&1

REM Open firewall for SSH
netsh advfirewall firewall add rule name="Incidium SSH" dir=in action=allow protocol=TCP localport=65122 >> %LOGFILE% 2>&1

echo [6] OpenSSH configured on port 65122.

:ssh_done

REM --- Summary ---
echo.
echo ===================================================================
echo  Phase 4 complete. Argus agent + SSH deployed.
echo ===================================================================
echo.

exit /b 0