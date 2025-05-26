#!/bin/bash

sleep 30
pinctrl set 2,3,4,17,27,22,10,9,11,5,6,26 op dl

pinctrl set 3,22,11,26 dh
sleep 0.5
pinctrl set 3,22,11,26 dl && pinctrl set 2,27,9,5 dh
sleep 0.5
pinctrl set 2,27,9,5 dl && pinctrl set 4,17,10,6 dh
sleep 0.5
pinctrl set 2,3,4,17,27,22,10,9,11,5,6,26 dl

sleep 5

while true; do

if systemctl show -p ActiveState,SubState hostapd | grep -q 'ActiveState=active' && \
systemctl show -p ActiveState,SubState hostapd | grep -q 'SubState=running'; then

pinctrl set 2 dh
pinctrl set 3 dl
pinctrl set 4 dl

else

pinctrl set 2 dl
pinctrl set 3 dh
pinctrl set 4 dl

fi

if systemctl show -p ActiveState,SubState dnsmasq | grep -q 'ActiveState=active' && \
systemctl show -p ActiveState,SubState dnsmasq | grep -q 'SubState=running'; then

pinctrl set 27 dh
pinctrl set 17 dl
pinctrl set 22 dl

else

pinctrl set 27 dl
pinctrl set 22 dh
pinctrl set 17 dl

fi

if systemctl show -p ActiveState,SubState nodogsplash | grep -q 'ActiveState=active' && \
systemctl show -p ActiveState,SubState nodogsplash | grep -q 'SubState=running'; then

pinctrl set 9 dh
pinctrl set 10 dl
pinctrl set 11 dl

else

pinctrl set 9 dl
pinctrl set 11 dh
pinctrl set 10 dl

fi



if systemctl show -p ActiveState,SubState backendc1 | grep -q 'ActiveState=active' && \
systemctl show -p ActiveState,SubState backendc1 | grep -q 'SubState=running'; then

pinctrl set 5 dh
pinctrl set 6 dl
pinctrl set 26 dl

else

pinctrl set 6 dh
pinctrl set 5 dl
pinctrl set 26 dh

fi



if systemctl show -p ActiveState,SubState painel_http | grep -q 'ActiveState=active' && \
systemctl show -p ActiveState,SubState painel_http | grep -q 'SubState=running'; then

pinctrl set 5 dh
pinctrl set 6 dl
pinctrl set 26 dl

else

pinctrl set 6 dl
pinctrl set 5 dl
pinctrl set 26 dh

fi

sleep 5

done