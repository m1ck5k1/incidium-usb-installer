@echo off
REM ============================================================
REM Incidium Digital Signage — USB Installer Entry Point
REM
REM Insert USB -> auto-run launches this.
REM Phase 0 runs FIRST to establish SSH + VNC remote access,
REM then proceeds with system prep, software, and CMS.
REM Logs saved to USB after every phase.
REM ============================================================
setlocal enabledelayedexpansion

set USB_DRIVE=%~d0
set INSTALL_DIR=C:\Argus
set LOGFILE=%INSTALL_DIR%\install.log
set ENGINE=%USB_DRIVE%\engine
set DEVICE_DIR=%USB_DRIVE%\device-%COMPUTERNAME%

REM --- Display header ---
color 0a
title Incidium Signage Installer v1.1
mode 100,25

echo.
echo                           Incidium Digital Signage Installer
echo                           ==================================
echo.
echo  Target: %COMPUTERNAME%
echo  USB Drive: %USB_DRIVE%
echo  Log: %LOGFILE%
echo.

REM --- Create directories ---
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%DEVICE_DIR%" mkdir "%DEVICE_DIR%"

echo [%DATE% %TIME%] ============================================ > %LOGFILE%
echo [%DATE% %TIME%] Incidium Signage Installer v1.1 started >> %LOGFILE%
echo [%DATE% %TIME%] Target: %COMPUTERNAME% >> %LOGFILE%
echo [%DATE% %TIME%] USB: %USB_DRIVE% >> %LOGFILE%
echo [%DATE% %TIME%] ============================================ >> %LOGFILE%

REM --- Admin check ---
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ERROR: This installer must be run as Administrator.
    echo  Right-click this file and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

echo  All 6 phases will run in sequence. Estimated time: 5-10 minutes.
echo  Phase 0 establishes remote access first — operator can then
echo  complete the install remotely via SSH or VNC.
echo  Logs saved to USB after every phase.
echo.
echo  Press any key to begin installation, or Ctrl+C to cancel.
pause >nul
echo.

REM ===== Track phase results =====
set PHASE0_STATUS=PASS
set PHASE1_STATUS=PASS
set PHASE2_STATUS=PASS
set PHASE3_STATUS=PASS
set PHASE4_STATUS=PASS

REM ===== PHASE 0: Remote Access (SSH + VNC) =====
echo.
echo ================ PHASE 0/6: Remote Access ================
call "%ENGINE%\00_remote_access.bat"
if %ERRORLEVEL% NEQ 0 (
    set PHASE0_STATUS=FAIL
    echo [WARN] Phase 0 had errors. Continuing...
)
call :capture_logs

REM ===== PHASE 1: System Preparation =====
echo.
echo ================ PHASE 1/6: System Preparation ================
call "%ENGINE%\01_system_prep.bat"
if %ERRORLEVEL% NEQ 0 (
    set PHASE1_STATUS=FAIL
    echo [WARN] Phase 1 had errors. Continuing...
)
call :capture_logs

REM ===== PHASE 2: Software Installation =====
echo.
echo ================ PHASE 2/6: Software Installation ================
call "%ENGINE%\02_software.bat"
if %ERRORLEVEL% NEQ 0 (
    set PHASE2_STATUS=FAIL
    echo [WARN] Phase 2 had errors. Continuing...
)
call :capture_logs

REM ===== PHASE 3: Fleet Agent (Argus) =====
echo.
echo ================ PHASE 3/6: Fleet Agent ================
call "%ENGINE%\04_agent.bat"
if %ERRORLEVEL% NEQ 0 (
    set PHASE3_STATUS=FAIL
    echo [WARN] Phase 3 had errors. Continuing...
)
call :capture_logs

REM ===== PHASE 4: CMS Player =====
echo.
echo ================ PHASE 4/6: CMS Player ================
call "%ENGINE%\03_cms_player.bat"
if %ERRORLEVEL% NEQ 0 (
    set PHASE4_STATUS=FAIL
    echo [WARN] Phase 4 had errors. Continuing...
)
call :capture_logs

REM ===== Final log capture =====
call :capture_logs

REM ===== Summary =====
echo.
echo ===================================================================
echo  Phase Summary:
echo    Phase 0 (Remote Access) : !PHASE0_STATUS!
echo    Phase 1 (System Prep)   : !PHASE1_STATUS!
echo    Phase 2 (Software)      : !PHASE2_STATUS!
echo    Phase 3 (Fleet Agent)   : !PHASE3_STATUS!
echo    Phase 4 (CMS Player)    : !PHASE4_STATUS!
echo -------------------------------------------------------------------
echo  Logs saved to %DEVICE_DIR%
echo ===================================================================
echo [%DATE% %TIME%] Installation complete. >> %LOGFILE%

REM ===== PHASE 5: Hostname + Reboot =====
echo.
echo ================ PHASE 5/6: Hostname and Reboot ================
call "%ENGINE%\05_hostname.bat"
REM Phase 5 handles its own reboot prompt — don't check ERRORLEVEL

echo.
echo ===================================================================
echo  Installation complete.
echo ===================================================================
goto :eof

REM ===== Subroutine: Capture logs to USB =====
:capture_logs
echo [LOG] Capturing logs to USB...
if exist "%LOGFILE%" (
    copy /Y "%LOGFILE%" "%DEVICE_DIR%\install.log" >nul
)
if exist "C:\Argus\pre-install-snapshot.txt" (
    copy /Y "C:\Argus\pre-install-snapshot.txt" "%DEVICE_DIR%\pre-install-snapshot.txt" >nul
)
echo [LOG] Logs saved to %DEVICE_DIR%
goto :eof