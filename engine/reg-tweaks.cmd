@echo off
REM ============================================================
REM Incidium Digital Signage — Registry Tweaks
REM Consolidated from legacy installer (v6.0.4), winOS_regTweaks,
REM auto-hide-taskbar scripts, and debloater.
REM Phase 1: System Preparation
REM ============================================================
setlocal
set LOGFILE=C:\Incidium-Install\install.log
echo [%DATE% %TIME%] Applying registry tweaks... >> %LOGFILE%

echo.
echo [Incidium] Applying registry tweaks...

REM --- KIOSK MODE: Taskbar ---
echo  Taskbar: auto-hide
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" /v Settings /t REG_BINARY /d 03000000080000000000000000000000 /f >nul 2>&1

echo  Taskbar: small icons
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 1 /f >nul 2>&1

echo  Taskbar: disable notifications area
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 0 /f >nul 2>&1

REM --- KIOSK MODE: Desktop ---
echo  Desktop: dark grey background (48,48,48)
reg add "HKCU\Control Panel\Colors" /v Background /t REG_SZ /d "48 48 48" /f >nul 2>&1

echo  Desktop: remove wallpaper
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "" /f >nul 2>&1

echo  Desktop: disable screensaver
reg delete "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE /f >nul 2>&1

echo  Desktop: small icon size (16px)
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "Shell Icon Size" /t REG_SZ /d "16" /f >nul 2>&1

REM --- KIOSK MODE: Notifications ---
echo  Notifications: disable Action Center
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v HideSCAHealth /t REG_DWORD /d 1 /f >nul 2>&1

echo  Notifications: disable balloon tips
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBalloonTips /t REG_DWORD /d 0 /f >nul 2>&1

echo  Notifications: disable Notification Center
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f >nul 2>&1

echo  Notifications: disable toast notifications
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f >nul 2>&1

echo  Notifications: disable app notifications
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_TOASTS_ENABLED /t REG_DWORD /d 0 /f >nul 2>&1

echo  Error Reporting: disable
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1

echo  Error Reporting: disable UI
reg add "HKCU\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1

REM --- KIOSK MODE: Services ---
echo  Services: disable Bluetooth
reg add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1

echo  Services: disable Shell Hardware Detection
reg add "HKLM\SYSTEM\CurrentControlSet\services\ShellHWDetection" /v Start /t REG_DWORD /d 4 /f >nul 2>&1

REM --- KIOSK MODE: Windows Update ---
echo  Windows Update: disable automatic updates
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f >nul 2>&1

echo  Windows Update: disable service
sc config wuauserv start=disabled >nul 2>&1

REM --- KIOSK MODE: Input ---
echo  Input: disable touch keyboard
reg add "HKLM\Software\Policies\Microsoft\TabletTip\1.7" /v "DisableEdgeTarget" /t REG_DWORD /d 1 /f >nul 2>&1

echo  Input: disable pen flicks
reg add "HKCU\Software\Microsoft\Wisp\Pen\SysEventParameters" /v "Flickmode" /t REG_DWORD /d 0 /f >nul 2>&1

REM --- USER ACCOUNT CONTROL ---
echo  UAC: disable
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 0 /f >nul 2>&1

REM --- AUTO-LOGON ---
echo  Auto-logon: enable for ds user
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUsername /t REG_SZ /d ds /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d ds /f >nul 2>&1

REM --- POWER ---
echo  Power button: default to restart
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_PowerButtonAction /t REG_DWORD /d 4 /f >nul 2>&1

REM --- UPDATE BLOCKERS ---
echo  Adobe AIR: disable updates
reg add "HKLM\Software\Policies\Adobe\AIR" /v UpdateDisabled /t REG_DWORD /d 1 /f >nul 2>&1

REM --- NETWORK ---
echo  Network: disable gratuitous ARP retries
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpRetryCount /t REG_DWORD /d 0 /f >nul 2>&1

REM --- VNC ---
echo  TightVNC: set capture method to mirror driver
reg add "HKLM\SOFTWARE\TightVNC\Server" /v "CaptureMethod" /t REG_DWORD /d 1 /f >nul 2>&1
echo  TightVNC: allow remote connections
reg add "HKLM\SOFTWARE\TightVNC\Server" /v "AcceptSocketConnections" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\TightVNC\Server" /v "LoopbackOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\TightVNC\Server" /v "ConnectPriority" /t REG_DWORD /d 0 /f >nul 2>&1

REM --- Cleanup Google update tasks ---
echo  Scheduled tasks: remove Google update
schtasks /delete /tn "GoogleUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "GoogleUpdateTaskMachineUA" /f >nul 2>&1

echo [%DATE% %TIME%] Registry tweaks applied. >> %LOGFILE%
echo [Incidium] Registry tweaks complete.
exit /b 0