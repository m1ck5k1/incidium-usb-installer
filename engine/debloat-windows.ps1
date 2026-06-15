# Incidium Digital Signage — Windows Bloatware Removal
# Strips unnecessary AppX packages while keeping essentials.
# Run with: powershell -ExecutionPolicy Bypass -File debloat-windows.ps1

Write-Host "[Incidium] Removing Windows bloatware packages..." -ForegroundColor Cyan

# Whitelist — apps to KEEP
$WhitelistedApps = 'Microsoft.Paint3D|Microsoft.MSPaint|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.MicrosoftStickyNotes|Microsoft.WindowsSoundRecorder|Microsoft.Windows.Photos|Microsoft.WindowsNotepad|Microsoft.PowerAutomateDesktop'

# Remove per-user AppX packages
Get-AppxPackage -AllUsers | Where-Object { $_.Name -notmatch $WhitelistedApps } | Remove-AppxPackage -ErrorAction SilentlyContinue

# Remove provisioned packages (won't install for new users)
Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -notmatch $WhitelistedApps } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

Write-Host "[Incidium] Bloatware removal complete." -ForegroundColor Green