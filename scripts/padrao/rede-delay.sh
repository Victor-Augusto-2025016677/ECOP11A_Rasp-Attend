#!/bin/bash

# Script para definir um ip estático na interface wlan0 (AP), e reiniciar serviços de rede e AP

sleep 30

ip addr flush dev wlan0

ip addr add 10.3.141.1/24 dev wlan0

ip link set wlan0 up

sleep 10

systemctl restart dnsmasq

systemctl restart hostapd

systemctl restart nodogsplash