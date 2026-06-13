# Incidium SnakeCharmer Scheduled Task — Auto-Start
# Creates a scheduled task to launch SnakeCharmer.exe at user logon
# with auto-restart on crash, interactive desktop, and unlimited runtime.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\register-snakecharmer-task.ps1
#
# Or run inline from batch:
#   powershell.exe -ExecutionPolicy Bypass -Command "& '.\register-snakecharmer-task.ps1'"

$currentUser = $env:USERDOMAIN + '\' + $env:USERNAME

$action = New-ScheduledTaskAction `
    -Execute 'C:\SnakeSpeareV6\SnakeCharmer.exe' `
    -WorkingDirectory 'C:\SnakeSpeareV6'

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser

$principal = New-ScheduledTaskPrincipal `
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName 'Incidium SnakeCharmer' `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Force

Write-Output "Task 'Incidium SnakeCharmer' registered for user: $currentUser"
Write-Output "  Auto-restart: 3 attempts, 1 minute interval"
Write-Output "  Runtime limit: unlimited"
Write-Output "  Logon type:    interactive desktop"