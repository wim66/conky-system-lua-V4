#!/bin/bash

#########################
# vnstat.sh             #
# Updated for vnstat 2+ #
# by@wim66              #
# v5 4-april-2025       #
#########################

cd "$(dirname "$0")"

# Fetch interface from settings.lua
netw=$(grep var_WIFI ../settings.lua | awk -F\" '{print $2}' | head -1)
[ -z "$netw" ] && netw="enp0s25"  # Fallback interface if not found

output="vnstat.txt"

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
    for i in {1..6}; do echo "N/A" >> "$output"; done
    exit 1
fi

# Fetch JSON data from vnstat
json=$(vnstat -i "$netw" --json)

# Get current date components
year=$(date +"%Y")
month=$(date +"%-m")  # Month without leading zero
day=$(date +"%-d")    # Day without leading zero

# Fetch data for today
down_today=$(echo "$json" | jq -r ".interfaces[0].traffic.day[] | select(.date.year==$year and .date.month==$month and .date.day==$day) | .rx")
up_today=$(echo "$json" | jq -r ".interfaces[0].traffic.day[] | select(.date.year==$year and .date.month==$month and .date.day==$day) | .tx")

# Calculate week data since Monday (vnstat 2+ doesn't provide week directly)
TODAY=$(date +%Y-%m-%d)  # e.g., 2025-04-04
DAYS_SINCE_MONDAY=$(date -d "$TODAY" +%u)
DAYS_SINCE_MONDAY=$((DAYS_SINCE_MONDAY - 1))
MONDAY=$(date -d "$TODAY - $DAYS_SINCE_MONDAY days" +%Y-%m-%d)  # e.g., 2025-03-31

# Extract year, month, and day for Monday and today
MONDAY_YEAR=$(date -d "$MONDAY" +%Y)
MONDAY_MONTH=$(date -d "$MONDAY" +%m | sed 's/^0//')
TODAY_MONTH=$(date -d "$TODAY" +%m | sed 's/^0//')
MONDAY_DAY=$(date -d "$MONDAY" +%d | sed 's/^0//')
TODAY_DAY=$(date -d "$TODAY" +%d | sed 's/^0//')

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

# Set "null" or empty values explicitly to "0"
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
        # Calculate GiB value first
        gib=$(echo "scale=3; $bytes / 1024 / 1024 / 1024" | bc)
        if [ "$(echo "$gib < 1" | bc -l)" -eq 1 ]; then
            # If less than 1 GiB, convert to MiB
            mib=$(echo "scale=2; $bytes / 1024 / 1024" | bc | awk '{printf "%.2f", $0}')
            echo "$mib MiB"
        else
            # If 1 GiB or more, use GiB
            gib_formatted=$(echo "$gib" | awk '{printf "%.2f", $0}')
            echo "$gib_formatted GiB"
        fi
    else
        # Fallback to KiB if bc is not available
        kib=$(echo "$bytes / 1024" | bc)
        echo "${kib}KiB"
    fi
}

# Write formatted data to output file
{
    format_bytes "$down_today"
    format_bytes "$up_today"
    format_bytes "$down_week"
    format_bytes "$up_week"
    format_bytes "$down_month"
    format_bytes "$up_month"
} > "$output"