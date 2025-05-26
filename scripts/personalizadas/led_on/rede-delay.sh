#!/bin/bash

pinctrl set 2,3,4,17,27,22,10,9,11,5,6,13 op dl

pinctrl set 4,17,10,6 op dh

sleep 30

pinctrl set 4,17,10,6 op dl

ip addr flush dev wlan0

ip addr add 10.3.141.1/24 dev wlan0

ip link set wlan0 up

sleep 10

systemctl restart dnsmasq

systemctl restart hostapd

CSV_BINAUTH_LOG="home/victo/codigo-c/csv/c_macs_efetivamente_ativos_anterior.txt"

CSV_ACTIVITY_LOG="home/victo/codigo-c/csv/eventos_sessoes_C.csv"

CSV_ACTIVITY_LOG1="home/victo/codigo-c/htdocs/eventos_sessoes_C.csv"

MAIN_BINAUTH_DETAILS_LOG="/home/victo/codigo-c/htdocs/relatorio_usuarios_C.csv"

MONITOR_ACTIVITY_ERROR_LOG="/tmp/nodogsplash_debug/monitor_atividade.error.log"

rm -f "$CSV_BINAUTH_LOG"

rm -f "$CSV_ACTIVITY_LOG"

rm -f "$CSV_ACTIVITY_LOG1"

rm -f "$MAIN_BINAUTH_DETAILS_LOG"

rm -f "$MONITOR_ACTIVITY_ERROR_LOG"

systemctl restart nodogsplash

pinctrl set 2 op dh
sleep 0.5
pinctrl set 2 op dl
pinctrl set 27 op dh
sleep 0.5
pinctrl set 27 op dl
pinctrl set 9 op dh
sleep 0.5
pinctrl set 9 op dl
pinctrl set 5 op dh
sleep 0.5
pinctrl set 2,3,4,17,27,22,10,9,11,5,6,26 op dl