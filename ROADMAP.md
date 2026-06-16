# Phase 6: Network Installer — ai.incidium.net

## Objective
Eliminate the USB stick. One PowerShell command on any baseline Windows machine downloads and executes the full Incidium installer from ai.incidium.net.

## The Bootstrap Command

```powershell
powershell -Command "iwr https://ai.incidium.net/i -OutFile $env:TEMP\i.ps1; powershell -ExecutionPolicy Bypass -File $env:TEMP\i.ps1"
```

This is the only manual step. Everything after is automated.

## Architecture

```
Operator types one command
        │
        ▼
Target machine downloads:
  https://ai.incidium.net/i                    → bootstrap script (<1KB)
  https://ai.incidium.net/installer/run.ps1     → main orchestrator (~10KB)
  https://ai.incidium.net/installer/00-05*.ps1  → phase scripts
  https://ai.incidium.net/installer/bin/        → Chrome, VLC, TightVNC, Argus, SnakeCharmer
        │
        ▼
run.ps1 orchestrates Phase 0-5 in sequence
  │
  ├── Phase 0: Remote Access (users, SSH, VNC, auto-logon)
  ├── Phase 1: System Prep (debloat, reg tweaks, power plan, Edge/OneDrive, taskbar)
  ├── Phase 2: Software (Chrome, VLC, TightVNC)
  ├── Phase 3: Fleet Agent (Argus)
  ├── Phase 4: CMS Player (SnakeCharmer + scheduled task)
  └── Phase 5: Hostname + cleanup
        │
        ▼
Logs → Google Sheet via GAS
Status → Google Chat (operator notification)
```

## What Changes

| Component | USB Installer (current) | Network Installer (Phase 6) |
|---|---|---|
| Entry point | autorun.bat on USB | run.ps1 on VPS |
| Binary source | `D:\engine\` | `https://ai.incidium.net/installer/bin/` |
| Script format | .bat (batch) | .ps1 (PowerShell) |
| Media required | 4GB USB stick | Internet connection only |
| Physical access | Yes (insert USB, run autorun) | Once (paste one command) |
| Operator notification | Pause on screen | Google Chat message with status |
| Log destination | USB drive + C:\Argus\ | Google Sheet + C:\Argus\ |

## What Stays the Same

- Same 6-phase structure (Phase 0-5)
- Same configuration (users, passwords, ports, registry tweaks)
- Same binaries (Chrome, VLC, TightVNC, Argus, SnakeCharmer)
- Same install logs on the target machine (C:\Argus\install.log)
- Same AAB-approved architecture — this is a delivery mechanism change, not a configuration change

## VPS File Structure

```
/var/www/incidium-installer/
├── i                           # Bootstrap script (1KB, minimal)
├── installer/
│   ├── run.ps1                 # Main orchestrator
│   ├── 00_remote_access.ps1    # Phase 0
│   ├── 01_system_prep.ps1      # Phase 1
│   ├── 02_software.ps1         # Phase 2
│   ├── 03_agent.ps1            # Phase 3
│   ├── 04_cms_player.ps1       # Phase 4
│   ├── 05_hostname.ps1         # Phase 5
│   ├── reg-tweaks.cmd
│   ├── debloat-windows.ps1
│   ├── uninstall-bloat.ps1
│   ├── register-snakecharmer-task.ps1
│   ├── set-autologin.ps1
│   └── docs/
│       └── openssh-win11-issues.md
└── bin/
    ├── argus.exe
    ├── ChromeStandaloneSetup64.exe
    ├── tightvnc-2.8.63-gpl-setup-64bit.msi
    ├── vlc-3.0.20-win64.exe
    └── snake-speare-v6/         # 1.2GB runtime
```

## Conversion Effort

| Task | Effort | Notes |
|---|---|---|
| Convert .bat → .ps1 | Medium | Phase scripts need rewriting for PowerShell (better error handling) |
| Set up VPS file host | Low | Static HTTP serving on ai.incidium.net |
| Create run.ps1 orchestrator | Low | Sequence + error handling + logging |
| Create bootstrap script (i) | Low | Single URL fetch + execute |
| Test on baseline Win11 | Medium | Validate against clean VM |
| Update AAB proposal | Low | Already approved architecture, delivery change only |

## Status
**Proposed** — not implemented. Saved as ROADMAP.md for Phase 6 tracking.