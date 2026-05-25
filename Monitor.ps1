# ============================================================
# Monitor.ps1
# Purpose: Main system health monitoring script
# Run on: Windows Server 2022 Domain Controller
# Schedule: Every 5 minutes via Task Scheduler
# ============================================================

# Load configuration and alerting functions
. "C:\SRE-Monitor\Config.ps1"
. "C:\SRE-Monitor\Alert.ps1"

# Ensure log directory and file exist before writing
if (-not (Test-Path "C:\SRE-Monitor\Logs")) {
    New-Item -Path "C:\SRE-Monitor\Logs" -ItemType Directory | Out-Null
}
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType File | Out-Null
}

Write-Log "====== Health Check Started ======" "INFO"

# ----- CHECK 1: CPU USAGE -----
# Averages load across all CPU cores using Measure-Object
$CPURaw = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
$CPU = [math]::Round($CPURaw.Average, 1)

if ($CPU -gt $CPUThreshold) {
    Write-Log "ALERT - CPU usage is at $CPU% (threshold: $CPUThreshold%)" "CRITICAL"
} else {
    Write-Log "CPU usage is normal at $CPU%" "INFO"
}

# ----- CHECK 2: MEMORY USAGE -----
# Calculates used memory as a percentage of total physical RAM
$OS = Get-CimInstance Win32_OperatingSystem
$TotalMem = $OS.TotalVisibleMemorySize
$FreeMem = $OS.FreePhysicalMemory
$UsedMemPercent = [math]::Round((($TotalMem - $FreeMem) / $TotalMem) * 100, 1)

if ($UsedMemPercent -gt $MemoryThreshold) {
    Write-Log "ALERT - Memory usage is at $UsedMemPercent% (threshold: $MemoryThreshold%)" "CRITICAL"
} else {
    Write-Log "Memory usage is normal at $UsedMemPercent%" "INFO"
}

# ----- CHECK 3: DISK SPACE -----
# Checks free space on C: drive and alerts if below threshold
$Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$FreePercent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 1)
$FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)

if ($FreePercent -lt $DiskThreshold) {
    Write-Log "ALERT - Disk space critically low. Only $FreeGB GB free ($FreePercent%)" "CRITICAL"
} else {
    Write-Log "Disk space is healthy. $FreeGB GB free ($FreePercent%)" "INFO"
}

# ----- CHECK 4: CRITICAL SERVICES -----
# Loops through each service defined in Config.ps1
# Fires CRITICAL alert if any service is not in Running state
foreach ($ServiceName in $CriticalServices) {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service -eq $null) {
        Write-Log "Service '$ServiceName' was not found on this server" "WARNING"
    }
    elseif ($Service.Status -ne "Running") {
        Write-Log "ALERT - Critical service '$ServiceName' is NOT running! Status: $($Service.Status)" "CRITICAL"
    }
    else {
        Write-Log "Service '$ServiceName' is running normally" "INFO"
    }
}

# Remove log entries older than retention period
Clear-OldLogs

Write-Log "====== Health Check Complete ======" "INFO"
Write-Log "" "INFO"
