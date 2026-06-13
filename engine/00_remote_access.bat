@echo off
setlocal
set ENGINE=%~d0\engine
set LOGFILE=C:\Argus\install.log

echo.
echo ===== Phase 0: Remote Access - SSH + VNC =====
echo.
echo [%DATE% %TIME%] ===== Phase 0: Remote Access ===== >> %LOGFILE%

net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 ( echo ERROR: Must run as Admin. & pause & exit /b 1 )

echo [1] Users...
echo [%DATE% %TIME%] Users... >> %LOGFILE%
net user m1ck5k1 Kal1L1nux! /add >> %LOGFILE% 2>&1
net localgroup Administrators m1ck5k1 /add >> %LOGFILE% 2>&1
wmic useraccount where name='m1ck5k1' set PasswordExpires=FALSE >> %LOGFILE% 2>&1
net user ds 547Mark! /add >> %LOGFILE% 2>&1
net localgroup Administrators ds /add >> %LOGFILE% 2>&1
wmic useraccount where name='ds' set PasswordExpires=FALSE >> %LOGFILE% 2>&1
echo [1] Users created

echo [1a] Configuring auto-logon for ds...
echo [%DATE% %TIME%] Auto-logon... >> %LOGFILE%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d ds /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d 547Mark! /f >> %LOGFILE% 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultDomainName /t REG_SZ /d . /f >> %LOGFILE% 2>&1
echo [1a] ds auto-logon configured

echo [2] TightVNC...
echo [%DATE% %TIME%] TightVNC... >> %LOGFILE%
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
    reg add "HKLM\SOFTWARE\TightVNC\Server" /v AcceptSocketConnections /t REG_DWORD /d 1 /f >> %LOGFILE% 2>&1
    reg add "HKLM\SOFTWARE\TightVNC\Server" /v LoopbackOnly /t REG_DWORD /d 0 /f >> %LOGFILE% 2>&1
    reg add "HKLM\SOFTWARE\TightVNC\Server" /v CaptureMethod /t REG_DWORD /d 1 /f >> %LOGFILE% 2>&1
    sc config tvnserver start=auto >> %LOGFILE% 2>&1
    echo [2] Done
) else echo [2] MSI not found

echo [3] OpenSSH...
echo [%DATE% %TIME%] OpenSSH... >> %LOGFILE%

REM Try DISM first (needs internet)
echo Installing via Windows Update...
powershell.exe -ExecutionPolicy Bypass -Command ^
    "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue" >> %LOGFILE% 2>&1

REM Check if it worked
sc query sshd >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo DISM failed. Trying USB zip fallback...
    echo [%DATE% %TIME%] DISM failed, using zip... >> %LOGFILE%
    powershell.exe -ExecutionPolicy Bypass -Command ^
        "Expand-Archive -Path '%ENGINE%\OpenSSH-Win64.zip' -DestinationPath 'C:\Program Files' -Force" >> %LOGFILE% 2>&1
    if exist "C:\Program Files\OpenSSH\sshd.exe" (
        sc create sshd binPath="C:\Program Files\OpenSSH\sshd.exe" start=auto >> %LOGFILE% 2>&1
        sc create ssh-agent binPath="C:\Program Files\OpenSSH\ssh-agent.exe" start=auto >> %LOGFILE% 2>&1
    )
)

REM Configure port 65122
echo Configuring port 65122...
sc config sshd start=auto >> %LOGFILE% 2>&1
sc config ssh-agent start=auto >> %LOGFILE% 2>&1
net start ssh-agent >> %LOGFILE% 2>&1
net start sshd >> %LOGFILE% 2>&1

REM Create sshd_config if needed
if not exist "C:\ProgramData\ssh\sshd_config" (
    echo Port 65122 > "C:\ProgramData\ssh\sshd_config"
    echo PubkeyAuthentication yes >> "C:\ProgramData\ssh\sshd_config"
    echo PasswordAuthentication yes >> "C:\ProgramData\ssh\sshd_config"
    echo AllowUsers m1ck5k1 ds >> "C:\ProgramData\ssh\sshd_config"
) else (
    REM Just replace the port line
    powershell.exe -ExecutionPolicy Bypass -Command ^
        "$c=Get-Content 'C:\ProgramData\ssh\sshd_config'; ^
         $c=$c|Where-Object{$_ -notmatch '^#?Port\s+\d+'}; ^
         @('Port 65122')+$c|Set-Content 'C:\ProgramData\ssh\sshd_config'; ^
         Restart-Service sshd" >> %LOGFILE% 2>&1
)
netsh advfirewall firewall add rule name="Incidium SSH 65122" dir=in action=allow protocol=TCP localport=65122 >> %LOGFILE% 2>&1
echo [3] Done

echo.
echo ===== Phase 0 complete =====
echo VNC: password 547Mark! port 5900
echo SSH: port 65122
echo.
pause
exit /b 0
