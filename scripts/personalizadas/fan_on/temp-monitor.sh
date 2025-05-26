#!/bin/bash

while true; do
temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
temp_c=$((temp_raw / 1000))

if [ "$temp_c" -gt 45 ]; then

sudo pinctrl set 16 op dh
else
sudo pinctrl set 16 op dl

fi

sleep 120

done