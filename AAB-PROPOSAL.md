# AAB Proposal: HPe-26 Digital Signage USB Installer

## 1. Business Case

### Current State
Digital signage machines for HPE Discover 2026 arrive on-site with clean Windows OS. Each machine must be made production-ready by:
- Installing Chrome, VLC, TightVNC, TeamViewer, and Incidium Remote Access
- Applying ~20 registry tweaks for kiosk operation
- Deploying SnakeCharmer.exe (CMS player) with its full runtime
- Configuring Argus fleet telemetry, OpenSSH on port 65122
- Naming the PC and registering it in the CMS

Currently, this process relies on a legacy batch installer (`_SnakespeareV6_Installer.bat` v6.0.4) dating from 2023. It requires internet access (Chocolatey for Chrome/VLC), pulls installers from Google Drive file IDs that may have rotated, and has no modular phase structure or error handling.

### Problem
- **No offline capability** — Exhibitor hall WiFi is unreliable; choco calls fail
- **Brittle sourcing** — GDrive file IDs in `winOS_filesDownload.bat` may have expired
- **Monolithic script** — 320-line batch file with no phase isolation; a failure mid-way means restarting from scratch
- **No logging** — Existing installer has ad-hoc logging but no structured output
- **Venue-specific gaps** — No HPe-26 WiFi profile, no event-specific config

### Opportunity
Build a self-contained USB installer that ships all binaries on the stick. Zero internet required. Phased execution so failures are contained. Consolidates 10+ years of organically grown scripts into a maintainable 5-phase pipeline.

---

## 2. Proposed Solution: Self-Contained USB Installer

### Architecture

```
USB Drive (FAT32/NTFS, 4GB+)
│
├── autorun.bat                    # Entry point — admin check, phase orchestration
│
└── engine/
    ├── 01_system_prep.bat         # Debloat, reg tweaks, power plan, NTP, hosts
    ├── 02_software.bat            # Chrome, VLC, TightVNC, Remote Access, firewall
    ├── 03_cms_player.bat          # SnakeCharmer.exe deploy, startup shortcut, WiFi
    ├── 04_agent.bat               # Argus daemon, service, OpenSSH port 65122
    ├── 05_hostname.bat            # Device name, rename PC, reboot
    ├── reg-tweaks.cmd             # Consolidated kiosk registry tweaks (113 lines)
    ├── debloat-windows.ps1        # AppX bloatware removal
    ├── snake-speare-v6/           # SnakeCharmer.exe + DotNetBrowser + libvlc (1.2GB)
    ├── argus.exe                  # Fleet telemetry daemon (5.2MB)
    ├── ChromeStandaloneSetup64.exe # Offline Chrome (146MB)
    ├── vlc-3.0.20-win64.exe       # Offline VLC (43MB)
    ├── tightvnc-2.8.63 MSI        # VNC remote desktop (2.4MB)
    ├── TeamViewer_Host_Setup.exe  # Remote support (29MB)
    ├── incidium-remote-access.msi # Custom remote agent (23MB)
    ├── BGInfo/                    # Desktop overlay (2.3MB)
    ├── Incidium.pow               # Custom power scheme
    ├── vlcrc                      # Locked-down VLC config
    ├── hosts                      # Custom hosts entries
    ├── wallpaper_*.png            # Incidium wallpapers
    └── WiFi_*.xml                 # Pre-configured WiFi profiles
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Offline vs online | **Offline-first** | Venue WiFi is unreliable. All binaries ship on USB. Choco is fallback only. |
| Batch vs PowerShell | **Batch orchestration, PS scripts** | Batch is the simplest entry point (double-click → runs). Complex logic (debloat, registry) delegated to targeted PS1 scripts. |
| Phase isolation | **5 independent phases** | Failure in Phase 2 doesn't lose Phase 1 work. Each phase can be re-run individually. |
| Error handling | **Per-phase ERRORLEVEL check** | If any phase fails, installation halts and points to log. |
| Versioning | **Google Drive + manual revisions** | Avoid GitHub (binary files). Drive revisions provide manual rollback. `keepForever=true` for release builds. |

### What's New vs Legacy Installer

| Area | Legacy (v6.0.4) | New (v1.0) |
|------|-----------------|------------|
| Internet required | Yes (Choco) | No |
| Offline Chrome/VLC | No | Yes — shipped on USB |
| Phase structure | Monolithic | 5 independent phases |
| Error handling | None (continues on failure) | Stops on phase failure, points to log |
| Registry tweaks | 3 separate files, ~200 lines total | 1 consolidated file, 113 lines |
| Argus agent | Not included | Included (service install + config) |
| OpenSSH | Not configured | Port 65122, key-only auth |
| Logging | Ad-hoc to engine/ dir | Structured to C:\Incidium-Install\ |
| WiFi profiles | 3 legacy profiles | Same + venue-specific (HPe-26 TBD) |

---

## 3. Implementation Plan

### Phase 1: Consolidation (DONE)
- Build USB skeleton at `~/dev/incidium-usb-installer/`
- Consolidate registry tweaks into single file
- Write 5 phase scripts (645 lines total)
- Collect all binaries from existing repos
- Download Chrome/VLC offline installers
- Create Drive folder + tracking sheet

### Phase 2: PowerShell Rewrite (NEXT)
- Rewrite all phase scripts as a single `install-incidium-signage.ps1`
- Add `-Silent` flag for hands-off deployment
- Add proper try/catch error handling
- Add `-SkipPhase` flags for selective re-runs

### Phase 3: Toolchain Automation
- Script to build USB from source: `build-usb.ps1 --output E:\`
- Version stamping in `autorun.bat`
- Pull latest SnakeCharmer.exe from CMS build server
- Pull latest argus.exe from CI

---

## 4. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| USB stick lost/damaged | Low | High | Keep master copy in Drive folder + build script to regenerate |
| SnakeCharmer.exe version mismatch | Medium | Medium | Tag release in Drive with `keepForever=true` |
| HPe-26 WiFi credentials change | Medium | Low | Venue SSID config is a single XML file, easily updated |
| Windows update changes registry behaviour | Low | Medium | Test on Win11 24H2 before event |
| 1.4GB exceeds FAT32 limit for single files | Low | Medium | Largest file is 146MB — well under 4GB FAT32 limit |

---

## 5. Storage & Versioning Strategy

### Why not GitHub
- Largest files (SnakeCharmer runtime: 1.2GB, Chrome: 146MB) exceed GitHub's LFS-free limits
- Git LFS adds complexity and cost for binaries that rarely change
- The installer is a deployment artifact, not source code

### Google Drive as Version Store
- Per-file revision history (tested: 3 revisions tracked on a test upload)
- Default: 100 revisions or 30 days retention
- Production releases: set `keepForever=true` on release revisions to prevent auto-expiry
- Rollback: restore any previous revision via the Drive API
- Collaboration: folder shared with ops team (James, Alex)
- Storage: 51TB available; 2.4TB used — 1.4GB project is negligible

### Workflow
```
Build USB locally     → Upload autorun.bat + engine/ to Drive folder
Tag release (v1.0)    → Pin revisions with keepForever=true
Copy to physical USB  → Insert and run on target machine
Update for next venue  → Replace config files, re-upload → new revision
```

---

## 6. Files & Locations

| Item | Location |
|------|----------|
| Source tree | `~/dev/incidium-usb-installer/` |
| Drive folder | https://drive.google.com/drive/folders/1sHuM5ZxP-X6yCgSk83SZoSLsZTFBqzam |
| Build tracker sheet | https://docs.google.com/spreadsheets/d/1HkH78ZIMaJrnHUJuotcerel7YdXWujeL8aoUSasRKws/edit |
| Task pipeline | T-021 |

---

## 7. Recommendation

**Proceed with Phase 2** (PowerShell rewrite) to harden the installer for production deployment at HPE Discover 2026. The current batch phase scripts are functional and tested but benefit from proper error handling, silent mode, and selective phase re-runs before we burn production USBs.

---

*Draft — not submitted to AAB. Ready for review.*