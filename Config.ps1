# ============================================================
# Config.ps1
# Purpose: Central configuration for the SRE Health Monitor
# Edit these values to adjust monitoring behavior
# ============================================================

# ----- ALERT THRESHOLDS -----
# CPU usage percentage that triggers an alert
$CPUThreshold = 80

# Memory usage percentage that triggers an alert
$MemoryThreshold = 85

# Minimum free disk space percentage before alert triggers
$DiskThreshold = 10

# ----- SERVICES TO MONITOR -----
# Critical Windows services that must stay running
# If any of these stop, a CRITICAL alert fires immediately
$CriticalServices = @(
    "DNS",        # Domain Name System - critical for Active Directory
    "ADWS",       # Active Directory Web Services
    "Netlogon",   # Domain authentication service
    "W32Time"     # Windows Time service - keeps domain clocks synced
)

# ----- LOG SETTINGS -----
# Full path to the log file
$LogPath = "C:\SRE-Monitor\Logs\health_log.txt"

# Number of days to retain log entries before auto-deletion
$LogRetentionDays = 7
