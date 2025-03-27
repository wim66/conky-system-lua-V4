#!/bin/bash

#########################
# vnstat.sh             #
# by @wim66             #
# v2 27-march-2024      #
#########################

cd "$(dirname "$0")"

# Get network interface
netw=$(grep var_WIFI ../settings.lua | awk -F\" '{print $2}' | head -1)
[ -z "$netw" ] && netw="enp0s25"  # Use your interface as fallback

output="vnstat.txt"

# Check if vnstat has data for this interface
if ! vnstat -i "$netw" >/dev/null 2>&1; then
    echo "Interface $netw not found in vnstat. Initialize with 'vnstat -u -i $netw'" >&2
    echo "N/A" > "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    exit 1
fi

# Daily statistics (use default output, not -d)
today=$(vnstat -i "$netw" | grep "today")
echo "${today:-N/A}" | awk '{print $2 $3}' > "$output"      # Down today
echo "${today:-N/A}" | awk '{print $5 $6}' >> "$output"     # Up today

# Weekly statistics
week=$(vnstat -i "$netw" -w | grep "current week")
echo "${week:-N/A}" | awk '{print $3 $4}' >> "$output"      # Down week
echo "${week:-N/A}" | awk '{print $6 $7}' >> "$output"      # Up week

# Monthly statistics
current_month=$(date +"%b '%y")
month=$(vnstat -i "$netw" -m | grep "$current_month")
echo "${month:-N/A}" | awk '{print $3 $4}' >> "$output"     # Down month
echo "${month:-N/A}" | awk '{print $6 $7}' >> "$output"     # Up month

# Check the number of lines
lines=$(wc -l < "$output")
if [ "$lines" -lt 6 ]; then
    echo "Incomplete data, filling with N/A" >&2
    echo "N/A" > "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
fi