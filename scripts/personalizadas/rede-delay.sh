#!/bin/bash

sleep 30

ip addr flush dev wlan0

ip addr add 10.3.141.1/24 dev wlan0

ip link set wlan0 up

sleep 10

systemctl restart dnsmasq

systemctl restart hostapd

CSV_BINAUTH_LOG="/etc/sistema_presenca/codigo-c/csv/c_macs_efetivamente_ativos_anterior.txt"

CSV_ACTIVITY_LOG="/etc/sistema_presenca/codigo-c/csv/eventos_sessoes_C.csv"

CSV_ACTIVITY_LOG1="/etc/sistema_presenca/codigo-c/htdocs/eventos_sessoes_C.csv"

MAIN_BINAUTH_DETAILS_LOG="/etc/sistema_presenca/codigo-c/htdocs/relatorio_usuarios_C.csv"

MONITOR_ACTIVITY_ERROR_LOG="/tmp/nodogsplash_debug/monitor_atividade.error.log"

rm -f "$CSV_BINAUTH_LOG"

rm -f "$CSV_ACTIVITY_LOG"

rm -f "$CSV_ACTIVITY_LOG1"

rm -f "$MAIN_BINAUTH_DETAILS_LOG"

rm -f "$MONITOR_ACTIVITY_ERROR_LOG"

systemctl restart nodogsplash

exit 0