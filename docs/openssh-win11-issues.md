# OpenSSH Install — Issues & Fixes (Win11 VM)

## Issue 1: Add-WindowsCapability didn't deploy the service binary
- Symptom: DISM reported "installed" but no sshd service
- Fix: Reboot — deployment finalized on restart
- Lesson: Some Win11 capability installs need a reboot to materialize the service

## Issue 2: Port 65122 wasn't configured
- Symptom: Service ran on default port 22
- Fix: Added `Port 65122` to sshd_config

## Issue 3: PasswordAuthentication was commented out
- Symptom: sshd_config had `#PasswordAuthentication yes` (defaults to no)
- Fix: Added `PasswordAuthentication yes`

## Issue 4: echo without quotes broke the config
- Symptom: `echo Port 65122 > file` in PowerShell wrote TWO lines (Port + 65122)
- Fix: Use `Set-Content "file" "Port 65122"` or `Add-Content`

## Issue 5: Service crashed on bad config
- Symptom: sshd terminated unexpectedly
- Fix: Check Event Viewer → System log → Event ID 7034
- Fix: Write clean config, Restart-Service

## Issue 6: Exclamation mark in password
- Symptom: `net user ds 547Mark!` set wrong password (\! stripped)
- Fix: `net user ds "547Mark!"` — always quote passwords

## Issue 7: Firewall rules not persisting through reboot
- Symptom: Rules created without profile=any were missing after reboot
- Fix: `profile=any` flag

## Working Config
```
Port 65122
PasswordAuthentication yes
Subsystem sftp sftp-server.exe
```

## Working Credentials
ds / 547Mark! (password must be quoted in net user command)