===================================================================
 Incidium Digital Signage — USB Installer v1.0
===================================================================

PURPOSE
  One-time setup USB for Incidium digital signage kiosks.
  Machines arrive with clean WinOS — this USB makes them
  production-ready SnakeSpeareV6 CMS players.

REQUIREMENTS
  - Windows 10 or 11 (64-bit)
  - Administrator privileges
  - 4GB+ USB drive (this bundle is ~1.4GB)
  - No internet required — all installers ship on the USB

ONE-TIME SETUP
  This USB must be built once from the source tree at:
    ~/dev/incidium-usb-installer/

  To prepare the USB:
    1. Insert blank USB drive (8GB+ recommended, FAT32 or NTFS)
    2. Copy the entire incidium-usb-installer folder to the USB
    3. Rename autorun.bat to autorun.bat (keep as-is for auto-play)
    4. Optionally add HPe-26 WiFi profile to engine/ if venue SSID known

INSTALLATION (on target machine)
  Option A — Auto-run:
    1. Insert USB into target machine
    2. If auto-play is enabled, the installer starts automatically
    3. Confirm "Run as Administrator" when prompted

  Option B — Manual:
    1. Open USB drive in Explorer
    2. Right-click autorun.bat → "Run as Administrator"

  WHAT IT DOES (5 phases, ~5-10 minutes total):

    Phase 1: System Preparation
      - Strips Windows bloatware (AppX packages)
      - Applies kiosk registry tweaks (auto-hide taskbar, black desktop,
        disable notifications, disable UAC, enable auto-logon)
      - Imports Incidium power plan
      - Configures NTP time sync
      - Updates hosts file

    Phase 2: Software Installation
      - Google Chrome (offline installer)
      - VLC media player (offline installer + config)
      - TightVNC server (password: fleet standard)
      - Incidium Remote Access (MSI)
      - Configures firewall rules

    Phase 3: CMS Player
      - Copies SnakeSpeareV6 runtime to C:\SnakeSpeareV6\
      - Creates SnakeCharmer.exe startup shortcut
      - Imports WiFi profiles

    Phase 4: Fleet Agent
      - Deploys Argus telemetry daemon
      - Registers as Windows service with auto-restart
      - Configures OpenSSH server on port 65122

    Phase 5: Hostname & Reboot
      - Reads device name from CMS registry
      - Renames PC (model prefix + device suffix)
      - Reboots to apply changes

  LOG FILE: C:\Incidium-Install\install.log

FILES ON THIS USB
  autorun.bat                  Entry point — run this
  engine/
    01_system_prep.bat         Phase 1
    02_software.bat            Phase 2
    03_cms_player.bat          Phase 3
    04_agent.bat               Phase 4
    05_hostname.bat            Phase 5
    reg-tweaks.cmd             Consolidated registry tweaks
    debloat-windows.ps1        AppX bloatware removal
    snake-speare-v6/           SnakeCharmer.exe + runtime DLLs + libvlc
    argus.exe                  Fleet telemetry daemon
    ChromeStandaloneSetup64.exe Google Chrome (offline install)
    vlc-3.0.20-win64.exe       VLC media player (offline install)
    tightvnc-2.8.63-gpl-setup-64bit.msi
    TeamViewer_Host_Setup.exe  Remote support
    incidium-remote-access.msi Custom remote agent
    BGInfo/                    Desktop overlay utility
    Incidium.pow               Custom power scheme
    vlcrc                      Locked-down VLC config
    hosts                      Custom hosts entries
    wallpaper_*.png            Incidium desktop wallpapers
    WiFi_*.xml                 Pre-configured WiFi profiles

===================================================================
 Incidium Ltd — HPE Discover 2026
===================================================================