#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALAÇÃO BASE (RaspAP + NoDogSplash)
# ==============================================================================
# Execute com: sudo ./install_base.sh

set -e

if [ "$EUID" -ne 0 ]; then
  echo "ERRO: Este script precisa ser executado como root. Use: sudo ./install_base.sh"
  exit 1
fi

REPO_ROOT=$(pwd)

echo "============================================="
echo "INICIANDO INSTALAÇÃO de RaspAP + NoDogSplash"
echo "============================================="

echo -e "\n>>> [1/5] Atualizando pacotes e instalando dependência (libmicrohttpd-dev)"
sudo apt-get update

sudo apt-get install -y libmicrohttpd-dev
echo ">>> Dependências instaladas."

echo -e "\n>>> [2/5] Instalando RaspAP (Modo Mínimo)"
curl -sL https://install.raspap.com | bash -s -- --yes --openvpn 0 --wireguard 0 --adblock 0 --restapi 0 --tcp-bbr 1
echo ">>> RaspAP instalado."

echo -e "\n>>> [3/5] Clonando repositório NoDogSplash"

if [ -d "nodogsplash" ]; then
    echo "    Pasta 'nodogsplash' existente encontrada. Removendo para clonagem limpa."
    sudo rm -rf nodogsplash
fi

git clone https://github.com/nodogsplash/nodogsplash.git
echo ">>> Repositório NoDogSplash clonado"

echo -e "\n>>> [4/5] Compilando e instalando NoDogSplash..."
cd nodogsplash

echo "    Executando make"

make

echo "    Executando sudo make install"

sudo make install

echo ">>> NoDogSplash compilado e instalado."

echo -e "\n>>> [5/5] Copiando arquivo de serviço NoDogSplash..."

if [ -f "debian/nodogsplash.service" ]; then
    sudo cp debian/nodogsplash.service /lib/systemd/system/
    echo "    Arquivo 'nodogsplash.service' copiado para /lib/systemd/system/."
    echo "    Recarregando systemd daemon..."
    sudo systemctl daemon-reload
else
    echo "    ERRO: Arquivo 'debian/nodogsplash.service' não encontrado no repositório clonado!"
    cd "$REPO_ROOT"
    exit 2
fi

cd "$REPO_ROOT"

echo -e "\n============================================="
echo "INSTALAÇÃO RaspAP + NoDogSplash CONCLUÍDA!"
echo "============================================="

echo "============================================="
echo "Configurando NODOGSPLASH - PADRÃO (FASE 2)"
echo "============================================="

CONFIG_FONTE="configuracoes\padrao\nodogsplash.conf"
CONFIG_DESTINO="/etc/nodogsplash/nodogsplash.conf"

echo -e "\n>>> [1/3] Aplicando configuração do NoDogSplash..."

if [ ! -f "$CONFIG_FONTE" ]; then
    echo "    ERRO: Arquivo '$CONFIG_FONTE' não encontrado! Certifique-se de executar da pasta do repositório."
    exit 3
fi

if [ ! -d "/etc/nodogsplash" ]; then
    echo "    ERRO: Diretório '/etc/nodogsplash' não encontrado. O NoDogSplash foi instalado corretamente na FASE 1?"
    exit 4
fi

sudo cp "$CONFIG_FONTE" "$CONFIG_DESTINO"
echo ">>> Configuração do NoDogSplash aplicada."

sudo systemctl enable nodogsplash.service
sudo systemctl start nodogsplash.service 
echo ">>> [2/3] Serviço NoDogSplash habilitado e iniciado."

echo -e "\n>>> [3/3] Configurações Padrão Aplicadas e serviço iniciado!"

echo "============================================="
echo "Configurando Delay de Rede (correção automática) - NECESSÁRIO (FASE 3)"
echo "============================================="

CONFIG_FONTE1="scripts\padrao\rede-delay.sh"
CONFIG_DESTINO1="/usr/local/bin/rede-delay.sh"

echo -e "\n>>> [1/3] Copiando script de delay de rede..."

if [ ! -f "$CONFIG_FONTE1" ]; then
    echo "    ERRO: Arquivo '$CONFIG_FONTE1' não encontrado! Certifique-se de executar da pasta do repositório."
    exit 3
fi

sudo cp "$CONFIG_FONTE1" "$CONFIG_DESTINO1"
echo ">>> Script delay de rede copiado."

CONFIG_FONTE2="scripts\padrao\rede-delay.service"
CONFIG_DESTINO2="/etc/systemd/system/rede-delay.service"

echo -e "\n>>> [2/3] Copiando serviço de delay de rede..."

if [ ! -f "$CONFIG_FONTE2" ]; then
    echo "    ERRO: Arquivo '$CONFIG_FONTE2' não encontrado! Certifique-se de executar da pasta do repositório."
    exit 3
fi

sudo cp "$CONFIG_FONTE2" "$CONFIG_DESTINO2"
echo ">>> .service do delay de rede copiado."

sudo chmod +x /usr/local/bin/rede-delay.sh
echo ">>> script definido como executável."
sudo systemctl daemon-reload
echo ">>> Recarregando systemd daemon..."
sudo systemctl enable rede-delay
sudo systemctl start rede-delay
echo ">>> Serviço de delay de rede habilitado e iniciado."
echo -e "\n>>> [3/3] Configurações Padrão Aplicadas e serviço iniciado!"

echo ">>> ATENÇÃO: O sistema será REINICIADO"

sudo reboot