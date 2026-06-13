# Incidium Digital Signage — Vendor Bloat Removal
# Removes specified applications from client-provisioned hardware.
# Targeted by product name fragment — skips anything with "driver" in the name.
# Runs as Phase 1a, before system prep.
#
# Usage: powershell -ExecutionPolicy Bypass -File uninstall-bloat.ps1
# Log: C:\Incidium-Install\install.log

param(
    [string]$LogFile = "C:\Incidium-Install\install.log"
)

$Targets = @(
    "Microsoft Office",
    "Office 16 Click-to-Run",
    "Microsoft 365",
    "Adobe Acrobat",
    "Adobe Reader",
    "Adobe Acrobat Reader",
    "Adobe Acrobat DC",
    "Apple",
    "iTunes",
    "iCloud",
    "Bonjour",
    "Apple Software Update",
    "Apple Mobile Device",
    "Google Chrome",
    "Firefox",
    "Mozilla Firefox",
    "VLC media player",
    "VideoLAN VLC",
    "Zoom",
    "Microsoft Teams",
    "OneDrive",
    "Microsoft OneDrive",
    "Webex",
    "Cisco Webex",
    "Cisco Webex Meetings",
    "Cisco Webex Teams"
)

$SkippedDrivers = @()

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath $LogFile -Append
    Write-Host "[Incidium] $Message"
}

Write-Log "===== Uninstall Phase: Vendor Bloat Removal ====="
Write-Log "Targets: $($Targets -join ', ')"

# Method 1: Get-Package (modern, works for MSI, AppX, and more)
$packages = Get-Package -ProviderName Programs -IncludeWindowsInstaller -ErrorAction SilentlyContinue

$removed = 0
$notFound = 0

foreach ($target in $Targets) {
    $match = $packages | Where-Object { $_.Name -like "*$target*" }
    
    if (-not $match) {
        Write-Log "  SKIP (not installed): $target"
        $notFound++
        continue
    }
    
    foreach ($pkg in $match) {
        $name = $pkg.Name
        
        # Safety: skip anything that looks like a driver
        if ($name -match "(?i)driver|chipset|amd|nvidia|intel|realtek|rakitan") {
            Write-Log "  SKIP (driver detected): $name"
            $SkippedDrivers += $name
            continue
        }
        
        try {
            Write-Log "  REMOVING: $name"
            if ($pkg.ProviderName -eq "Programs" -or $pkg.FastPackageReference) {
                # Use msiexec for MSI-based installs
                if ($pkg.FastPackageReference -match '{([A-F0-9-]+)}') {
                    $guid = $matches[1]
                    Write-Log "    MSI GUID: $guid"
                    $proc = Start-Process msiexec -ArgumentList "/x {$guid} /quiet /norestart /log C:\Incidium-Install\uninstall-msi.log" -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0) {
                        Write-Log "    Removal success (exit $($proc.ExitCode))"
                    } else {
                        Write-Log "    Removal returned exit code $($proc.ExitCode) — see C:\Incidium-Install\uninstall-msi.log"
                    }
                } else {
                    # Fallback: uninstall via package manager
                    Uninstall-Package -InputObject $pkg -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    Write-Log "    Uninstall-Package completed"
                }
            }
            $removed++
        }
        catch {
            Write-Log "    ERROR removing $name : $_"
        }
    }
}

# Method 2: WMI fallback for stubborn installs
Write-Log "--- WMI fallback pass ---"
$wmiProducts = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object {
    $name = $_.Name
    $Targets | Where-Object { $name -like "*$_*" } -and $name -notmatch "(?i)driver|chipset|amd|nvidia|intel|realtek|rakitan"
}

foreach ($product in $wmiProducts) {
    try {
        Write-Log "  WMI REMOVING: $($product.Name)"
        $result = $product.Uninstall()
        if ($result.ReturnValue -eq 0) {
            Write-Log "    WMI removal success"
        } else {
            Write-Log "    WMI removal returned $($result.ReturnValue)"
        }
        $removed++
    }
    catch {
        Write-Log "    WMI ERROR: $_"
    }
}

Write-Log "===== Uninstall Complete ====="
Write-Log "Removed: $removed | Not found: $notFound | Drivers skipped: $($SkippedDrivers.Count)"
if ($SkippedDrivers.Count -gt 0) {
    Write-Log "Skipped drivers: $($SkippedDrivers -join '; ')"
}