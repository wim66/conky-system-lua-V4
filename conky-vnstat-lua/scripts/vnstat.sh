#!/bin/bash

cd "$(dirname "$0")"

# Haal netwerkinterface op
netw=$(grep var_WIFI ../settings.lua | awk -F\" '{print $2}' | head -1)
[ -z "$netw" ] && netw="enp0s25"  # Gebruik jouw interface als fallback

output="vnstat.txt"

# Controleer of vnstat data heeft voor deze interface
if ! vnstat -i "$netw" >/dev/null 2>&1; then
    echo "Interface $netw niet gevonden in vnstat. Initialiseer met 'vnstat -u -i $netw'" >&2
    echo "N/A" > "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    exit 1
fi

# Dagstatistieken (gebruik de standaard uitvoer, niet -d)
today=$(vnstat -i "$netw" | grep "today")
echo "${today:-N/A}" | awk '{print $2 $3}' > "$output"      # Down today
echo "${today:-N/A}" | awk '{print $5 $6}' >> "$output"     # Up today

# Weekstatistieken
week=$(vnstat -i "$netw" -w | grep "current week")
echo "${week:-N/A}" | awk '{print $3 $4}' >> "$output"      # Down week
echo "${week:-N/A}" | awk '{print $6 $7}' >> "$output"      # Up week

# Maandstatistieken
current_month=$(date +"%b '%y")
month=$(vnstat -i "$netw" -m | grep "$current_month")
echo "${month:-N/A}" | awk '{print $3 $4}' >> "$output"     # Down month
echo "${month:-N/A}" | awk '{print $6 $7}' >> "$output"     # Up month

# Controleer het aantal lijnen
lines=$(wc -l < "$output")
if [ "$lines" -lt 6 ]; then
    echo "Onvolledige data, vult met N/A" >&2
    echo "N/A" > "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
    echo "N/A" >> "$output"
fi