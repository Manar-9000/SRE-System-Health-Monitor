# ============================================================
# Alert.ps1
# Purpose: Handles all logging and alerting for the monitor
# In production this would also integrate with Slack,
# PagerDuty, or email notifications
# ============================================================

# Writes a timestamped entry to both the screen and the log file
# Parameters:
#   Message - the text to log
#   Level   - INFO, WARNING, or CRITICAL
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    # Every log entry gets a precise timestamp
    # Format: 2026-05-25 13:40:36
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Build the structured log line
    # Example: [2026-05-25 13:40:36] [CRITICAL] ALERT - DNS is NOT running
    $LogLine = "[$Timestamp] [$Level] $Message"

    # Append to log file — never overwrites existing entries
    Add-Content -Path $LogPath -Value $LogLine

    # Print to screen with color based on severity level
    switch ($Level) {
        "INFO"     { Write-Host $LogLine -ForegroundColor Green }
        "WARNING"  { Write-Host $LogLine -ForegroundColor Yellow }
        "CRITICAL" { Write-Host $LogLine -ForegroundColor Red }
    }
}

# Removes log entries older than the retention period
# Prevents the log file from growing indefinitely
function Clear-OldLogs {
    $Cutoff = (Get-Date).AddDays(-$LogRetentionDays)
    $AllLines = Get-Content -Path $LogPath -ErrorAction SilentlyContinue
    $RecentLines = $AllLines | Where-Object {
        if ($_ -match "\[(\d{4}-\d{2}-\d{2})") {
            [datetime]$matches[1] -gt $Cutoff
        }
    }
    $RecentLines | Set-Content -Path $LogPath
}
