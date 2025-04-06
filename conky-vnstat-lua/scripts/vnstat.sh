#!/bin/bash

# conky-vnstat-lua V4
# by @wim66
# v4 6-April-2024

# Required tools: vnstat, jq, bc, awk, grep, date

# Set script directory
cd "$(dirname "$0")" || exit

output="vnstat.txt"

# Improved interface detection
# Step 1: Try interface from settings.lua
netw=$(grep var_WIFI ../settings.lua 2>/dev/null | awk -F\" '{print $2}' | head -1)

# Step 2: Get vnstat-monitored interfaces
vnstat_ifaces=$(vnstat --json | jq -r '.interfaces[].name')

# Step 3: Validate interface or choose a good alternative
if ! echo "$vnstat_ifaces" | grep -qx "$netw"; then
    echo "Config interface '$netw' is not monitored by vnstat or not set."

    # Get all active (UP) interfaces
    up_ifaces=$(ip -o link show up | awk -F': ' '{print $2}')

    # Choose first suitable match: monitored by vnstat AND UP AND not virtual
    netw=$(echo "$vnstat_ifaces" | grep -Fx -f <(echo "$up_ifaces") | grep -Ev 'lo|proton0|ipv6leakintrf0' | head -n1)

    # Fallback: first monitored interface
    [ -z "$netw" ] && netw=$(echo "$vnstat_ifaces" | grep -Ev 'lo|ipv6leakintrf0' | head -n1)
fi

# Final fallback if still empty
[ -z "$netw" ] && netw="wlp3s0"

echo "Using interface: $netw"

# Check if 'bc' is installed
if ! command -v bc &>/dev/null; then
    echo "Warning: 'bc' is not installed. Data will be displayed in KiB." >&2
    use_bc=false
else
    use_bc=true
fi

# Verify if the interface is available in vnstat
if ! vnstat -i "$netw" --json 1>/dev/null 2>&1; then
    echo "Interface $netw not found in vnstat." >&2
    for _ in {1..6}; do echo "N/A" >> "$output"; done
    exit 1
fi

# Fetch JSON data from vnstat and validate
json=$(vnstat -i "$netw" --json)
if [ -z "$json" ]; then
    echo "Error: Failed to fetch JSON data from vnstat." >&2
    for _ in {1..6}; do echo "N/A" >> "$output"; done
    exit 1
fi

# Get current date components with error handling
year=$(date +"%Y" 2>/dev/null) || { echo "Error: Failed to get year." >&2; exit 1; }
month=$(date +"%-m" 2>/dev/null) || { echo "Error: Failed to get month." >&2; exit 1; }
day=$(date +"%-d" 2>/dev/null) || { echo "Error: Failed to get day." >&2; exit 1; }

# Fetch data for today
down_today=$(echo "$json" | jq -r ".interfaces[0].traffic.day[] | select(.date.year==$year and .date.month==$month and .date.day==$day) | .rx")
up_today=$(echo "$json" | jq -r ".interfaces[0].traffic.day[] | select(.date.year==$year and .date.month==$month and .date.day==$day) | .tx")

# Calculate week data since Monday
TODAY=$(date +%Y-%m-%d 2>/dev/null) || { echo "Error: Failed to get today’s date." >&2; exit 1; }
DAYS_SINCE_MONDAY=$(($(date -d "$TODAY" +%u 2>/dev/null) - 1)) || { echo "Error: Failed to calculate days since Monday." >&2; exit 1; }
MONDAY=$(date -d "$TODAY - $DAYS_SINCE_MONDAY days" +%Y-%m-%d 2>/dev/null) || { echo "Error: Failed to calculate Monday’s date." >&2; exit 1; }

MONDAY_YEAR=$(date -d "$MONDAY" +%Y 2>/dev/null) || { echo "Error: Failed to get Monday’s year." >&2; exit 1; }
MONDAY_MONTH=$(date -d "$MONDAY" +%-m 2>/dev/null) || { echo "Error: Failed to get Monday’s month." >&2; exit 1; }
TODAY_MONTH=$(date -d "$TODAY" +%-m 2>/dev/null) || { echo "Error: Failed to get today’s month." >&2; exit 1; }
MONDAY_DAY=$(date -d "$MONDAY" +%-d 2>/dev/null) || { echo "Error: Failed to get Monday’s day." >&2; exit 1; }
TODAY_DAY=$(date -d "$TODAY" +%-d 2>/dev/null) || { echo "Error: Failed to get today’s day." >&2; exit 1; }

# Filter day data for the current week (Monday to today)
FILTERED_DATA=$(echo "$json" | jq -r "
  .interfaces[0].traffic.day |
  map(select(
    (.date.year == $MONDAY_YEAR and
     .date.month == $MONDAY_MONTH and
     .date.day >= $MONDAY_DAY) or
    (.date.year == $MONDAY_YEAR and
     .date.month == $TODAY_MONTH and
     .date.day <= $TODAY_DAY)
  ))
")

# Calculate total rx and tx for the week
down_week=$(echo "$FILTERED_DATA" | jq -r 'map(.rx) | add // 0')
up_week=$(echo "$FILTERED_DATA" | jq -r 'map(.tx) | add // 0')

# Fetch data for the current month
down_month=$(echo "$json" | jq -r ".interfaces[0].traffic.month[] | select(.date.year==$year and .date.month==$month) | .rx")
up_month=$(echo "$json" | jq -r ".interfaces[0].traffic.month[] | select(.date.year==$year and .date.month==$month) | .tx")

# Sanitize possible null or empty values
down_today=$(echo "${down_today:-0}" | grep -E '^[0-9]+$' || echo 0)
up_today=$(echo "${up_today:-0}" | grep -E '^[0-9]+$' || echo 0)
down_week=$(echo "${down_week:-0}" | grep -E '^[0-9]+$' || echo 0)
up_week=$(echo "${up_week:-0}" | grep -E '^[0-9]+$' || echo 0)
down_month=$(echo "${down_month:-0}" | grep -E '^[0-9]+$' || echo 0)
up_month=$(echo "${up_month:-0}" | grep -E '^[0-9]+$' || echo 0)

# Function to format bytes dynamically (MiB if < 1 GiB, else GiB)
format_bytes() {
    local bytes=$1
    if [ "$use_bc" = true ]; then
        gib=$(echo "scale=3; $bytes / 1024 / 1024 / 1024" | bc)
        if (( $(echo "$gib < 1" | bc -l) )); then
            mib=$(echo "scale=2; $bytes / 1024 / 1024" | bc | awk '{printf "%.2f", $0}')
            echo "$mib MiB"
        else
            gib_formatted=$(echo "$gib" | awk '{printf "%.2f", $0}')
            echo "$gib_formatted GiB"
        fi
    else
        kib=$(echo "$bytes / 1024" | bc)
        echo "${kib} KiB"
    fi
}

# Output formatted results
{
    format_bytes "$down_today"
    format_bytes "$up_today"
    format_bytes "$down_week"
    format_bytes "$up_week"
    format_bytes "$down_month"
    format_bytes "$up_month"
} > "$output"
