#!/bin/sh

# Change directory to the script's location
cd "$(dirname "$0")" || exit

# Wait for a short period to ensure conky processes are terminated
sleep 1

# Start conky with the specified configuration file
( set -x; setsid conky -c conky-system.conf )

# Wait for a short period to ensure conky starts properly
sleep 1

exit