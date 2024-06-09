#!/bin/bash

CONKY_DIR=$(dirname "$(readlink -f "$0")")

if pidof conky > /dev/null; then
    killall conky
fi

cd $CONKY_DIR

# start system conky
 sh conky-system-lua-V3/autostart.sh
sleep 1
# start clock conky
 sh conky-clock-lua-V1/autostart.sh
sleep 1
# start  vnstat conky
 sh conky-vnstat-lua/autostart.sh
 
 sh /home/willem/git-repo/conky-weather-lua-kopie/start2.sh
exit
