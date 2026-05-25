# ============================================================
# Setup-Monitor.ps1
# Purpose: One-command deployment script for the SRE Health Monitor
# Run on: Windows Server 2022 (as Administrator)
# Usage:  .\Setup-Monitor.ps1
# ============================================================

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "   SRE Health Monitor - Setup" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

# ----- STEP 1: VERIFY ALL REQUIRED FILES EXIST -----
# Stops immediately with a clear error if anything is missing
$RequiredFiles = @(
    "C:\SRE-Monitor\Monitor.ps1",
    "C:\SRE-Monitor\Config.ps1",
    "C:\SRE-Monitor\Alert.ps1"
)

foreach ($File in $RequiredFiles) {
    if (-not (Test-Path $File)) {
        Write-Host "ERROR - Required file missing: $File" -ForegroundColor Red
        Write-Host "Ensure all files are in C:\SRE-Monitor before running setup." -ForegroundColor Red
        exit
    }
}
Write-Host "All required files found." -ForegroundColor Green

# ----- STEP 2: CREATE LOGS DIRECTORY -----
if (-not (Test-Path "C:\SRE-Monitor\Logs")) {
    New-Item -Path "C:\SRE-Monitor\Logs" -ItemType Directory | Out-Null
    Write-Host "Logs folder created." -ForegroundColor Green
} else {
    Write-Host "Logs folder already exists." -ForegroundColor Green
}

# ----- STEP 3: REMOVE EXISTING TASK IF PRESENT -----
# Prevents duplicate tasks if setup is run more than once
$ExistingTask = Get-ScheduledTask -TaskName "SRE-HealthMonitor" -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Unregister-ScheduledTask -TaskName "SRE-HealthMonitor" -Confirm:$false
    Write-Host "Removed existing scheduled task." -ForegroundColor Yellow
}

# ----- STEP 4: REGISTER THE SCHEDULED TASK -----
# Runs Monitor.ps1 every 5 minutes under the SYSTEM account
# SYSTEM account ensures the monitor runs even when no user is logged in
Write-Host "Creating scheduled task..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File C:\SRE-Monitor\Monitor.ps1"

$Trigger = New-ScheduledTaskTrigger `
    -RepetitionInterval (New-TimeSpan -Minutes 5) `
    -Once `
    -At (Get-Date)

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName "SRE-HealthMonitor" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Monitors system health every 5 minutes. Checks CPU, memory, disk, and critical AD services." `
    -Force | Out-Null

Write-Host "Scheduled task created successfully." -ForegroundColor Green

# ----- STEP 5: START MONITOR IMMEDIATELY -----
Start-ScheduledTask -TaskName "SRE-HealthMonitor"
Write-Host "Monitor started immediately." -ForegroundColor Green

# ----- STEP 6: CONFIRM DEPLOYMENT -----
$Task = Get-ScheduledTask -TaskName "SRE-HealthMonitor"
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "   Setup Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Task Name:   $($Task.TaskName)" -ForegroundColor Green
Write-Host "State:       $($Task.State)" -ForegroundColor Green
Write-Host "Run every:   5 minutes" -ForegroundColor Green
Write-Host "Log file:    C:\SRE-Monitor\Logs\health_log.txt" -ForegroundColor Green
Write-Host "`nTo check logs run:" -ForegroundColor Cyan
Write-Host "Get-Content C:\SRE-Monitor\Logs\health_log.txt" -ForegroundColor Yellow
Write-Host ""
