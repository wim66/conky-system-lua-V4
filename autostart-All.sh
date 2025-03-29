#!/bin/bash
# This script creates an autostart by changing to the theme folder before executing conky
# Conkies can be started individually through terminal from their directory (conky -c conky.conf or cd /path/to/theme/ && conky -c conky.conf)

# Kill any running conky instances
killall conky

# Ensure script is run from the directory it is located in
cd "$(dirname "$0")"
# Start system conky
sh conky-system-lua-V4/autostart.sh
sleep 1

# Start clock conky
sh conky-clock-lua-V1/autostart.sh
sleep 1

# Start vnstat conky
sh conky-vnstat-lua/autostart.sh
# Exit script
exit 0