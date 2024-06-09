#!/bin/sh

# Making sure theme-dir is working-dir
        cd "$(dirname "$0")"
netw=`grep var_WIFI ../settings.lua | awk -F\" '{print $2}' | head -1`
downtoday=`vnstat -i $netw | grep "today" | awk '{print $2 $3}'`
uptoday=`vnstat -i $netw | grep "today" | awk '{print $5 $6}'`

down_week=`vnstat -i $netw -w | grep "current week" | awk '{print $3 $4}'`
up_week=`vnstat -i $netw -w | grep "current week" | awk '{print $6 $7}'`

stats_month=`vnstat -i $netw -m`


echo "$downtoday" > vnstat.txt
echo "$uptoday" >> vnstat.txt
echo "$down_week" >> vnstat.txt
echo "$up_week" >> vnstat.txt
echo "$stats_month" | grep "`date +"%b '%y"`" | awk '{print $3 $4}' >> vnstat.txt
echo "$stats_month" | grep "`date +"%b '%y"`" | awk '{print $6 $7}' >> vnstat.txt
