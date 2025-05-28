#!/bin/bash

# ==============================================================================
# SCRIPT DE INSTALAÇÃO BASE (RaspAP + NoDogSplash)
# ==============================================================================
# Execute com: sudo ./install_base.sh

# Termina o script imediatamente se um comando sair com um status diferente de zero.
set -e

# --- Funções Auxiliares ---

# Função para fazer perguntas Sim/Não (não utilizada neste script, mas mantida para consistência se necessário no futuro)
# ask_yes_no() {
#     while true; do
#         read -p "$1 (s/n): " sn
#         case $sn in
#             [Ss]* ) return 0;; # Sim
#             [Nn]* ) return 1;; # Não
#             * ) echo "   ATENÇÃO: Por favor, responda com 's' para sim ou 'n' para não.";;
#         esac
#     done
# }

# Função para exibir cabeçalho de seção
print_section_header() {
    echo
    echo "================================================="
    echo " $1"
    echo "================================================="
    echo
}

# Função para exibir mensagem de sucesso
print_success() {
    echo "   SUCESSO: $1"
}

# Função para exibir mensagem de erro
print_error() {
    echo "   ERRO: $1"
}

# Função para exibir mensagem de informação
print_info() {
    echo "   INFO: $1"
}

# Função para exibir mensagem de aviso
print_warning() {
    echo "   AVISO: $1"
}

# Função para exibir etapa de progresso
print_step() {
    echo "   PASSO: $1..."
}

# --- Verificação Inicial ---
if [ "$EUID" -ne 0 ]; then
  print_error "Este script precisa ser executado como root. Use: sudo ./install_base.sh"
  exit 1
fi

# Define o diretório raiz do repositório
REPO_ROOT=$(pwd)
clear # Limpa a tela

# --- FASE 1: INSTALAÇÃO RaspAP + NoDogSplash ---
print_section_header "FASE 1: INICIANDO INSTALAÇÃO de RaspAP + NoDogSplash"

print_step "[1/5] Atualizando pacotes e instalando dependências (libmicrohttpd-dev, cmake)"
sudo apt-get update -qq # -qq para menos output
sudo apt-get install -y libmicrohttpd-dev cmake
print_success "Dependências instaladas."

print_step "[2/5] Instalando RaspAP (Modo Mínimo)"
# A saída do script do RaspAP é verbosa, então apenas informamos o início e o fim.
curl -sL https://install.raspap.com | bash -s -- --yes --openvpn 0 --wireguard 0 --adblock 0 --restapi 0 --tcp-bbr 1
print_success "RaspAP instalado."

print_step "[3/5] Clonando repositório NoDogSplash"
if [ -d "nodogsplash" ]; then
    print_info "Pasta 'nodogsplash' existente encontrada. Removendo para clonagem limpa."
    sudo rm -rf nodogsplash
fi
git clone https://github.com/nodogsplash/nodogsplash.git
print_success "Repositório NoDogSplash clonado para o diretório 'nodogsplash'."

print_step "[4/5] Compilando e instalando NoDogSplash"
cd nodogsplash
print_info "Executando 'make' (isso pode levar alguns minutos)..."
make > /dev/null 2>&1 # Redireciona output para suprimir verbosidade excessiva do make
print_info "Executando 'sudo make install'..."
sudo make install > /dev/null 2>&1 # Redireciona output
print_success "NoDogSplash compilado e instalado."

print_step "[5/5] Copiando arquivo de serviço NoDogSplash e recarregando systemd"
if [ -f "debian/nodogsplash.service" ]; then
    sudo cp debian/nodogsplash.service /lib/systemd/system/
    print_info "Arquivo 'nodogsplash.service' copiado para /lib/systemd/system/."
    print_info "Recarregando systemd daemon..."
    sudo systemctl daemon-reload
    print_success "Arquivo de serviço NoDogSplash configurado."
else
    print_error "Arquivo 'debian/nodogsplash.service' não encontrado no repositório clonado!"
    cd "$REPO_ROOT" # Garante que estamos no diretório correto antes de sair
    exit 2
fi
cd "$REPO_ROOT" # Retorna ao diretório raiz do script
print_section_header "FASE 1: INSTALAÇÃO RaspAP + NoDogSplash CONCLUÍDA!"

# --- FASE 2: CONFIGURANDO NODOGSPLASH - PADRÃO ---
print_section_header "FASE 2: Configurando NODOGSPLASH - PADRÃO"

CONFIG_FONTE_NDS="$REPO_ROOT/configuracoes/padrao/nodogsplash.conf"
CONFIG_DESTINO_NDS="/etc/nodogsplash/nodogsplash.conf"

print_step "[1/3] Aplicando configuração padrão do NoDogSplash"
if [ ! -f "$CONFIG_FONTE_NDS" ]; then
    print_error "Arquivo de configuração '$CONFIG_FONTE_NDS' não encontrado! Certifique-se de executar o script da pasta raiz do repositório."
    exit 3
fi
if [ ! -d "/etc/nodogsplash" ]; then
    print_error "Diretório '/etc/nodogsplash' não encontrado. O NoDogSplash foi instalado corretamente na FASE 1?"
    exit 4
fi
sudo cp "$CONFIG_FONTE_NDS" "$CONFIG_DESTINO_NDS"
print_success "Configuração padrão do NoDogSplash aplicada."

print_step "[2/3] Habilitando e iniciando serviço NoDogSplash"
sudo systemctl enable nodogsplash.service
sudo systemctl start nodogsplash.service
if systemctl is-active --quiet nodogsplash.service; then
    print_success "Serviço NoDogSplash habilitado e iniciado."
else
    print_error "Falha ao iniciar o serviço NoDogSplash. Verifique com 'systemctl status nodogsplash.service'."
fi

print_step "[3/3] Configurações Padrão do NoDogSplash Aplicadas e serviço iniciado!"
print_section_header "FASE 2: CONFIGURAÇÃO NODOGSPLASH CONCLUÍDA!"

# --- FASE 3: CONFIGURANDO DELAY DE REDE ---
print_section_header "FASE 3: Configurando Delay de Rede (correção automática)"

CONFIG_FONTE_DELAY_SCRIPT="$REPO_ROOT/scripts/padrao/rede-delay.sh"
CONFIG_DESTINO_DELAY_SCRIPT="/usr/local/bin/rede-delay.sh"
CONFIG_FONTE_DELAY_SERVICE="$REPO_ROOT/scripts/padrao/rede-delay.service"
CONFIG_DESTINO_DELAY_SERVICE="/etc/systemd/system/rede-delay.service"

print_step "[1/4] Copiando script de delay de rede"
if [ ! -f "$CONFIG_FONTE_DELAY_SCRIPT" ]; then
    print_error "Arquivo de script '$CONFIG_FONTE_DELAY_SCRIPT' não encontrado! Certifique-se de executar da pasta do repositório."
    exit 3
fi
sudo cp "$CONFIG_FONTE_DELAY_SCRIPT" "$CONFIG_DESTINO_DELAY_SCRIPT"
print_success "Script de delay de rede copiado para '$CONFIG_DESTINO_DELAY_SCRIPT'."

print_step "[2/4] Copiando arquivo de serviço de delay de rede"
if [ ! -f "$CONFIG_FONTE_DELAY_SERVICE" ]; then
    print_error "Arquivo de serviço '$CONFIG_FONTE_DELAY_SERVICE' não encontrado! Certifique-se de executar da pasta do repositório."
    exit 3
fi
sudo cp "$CONFIG_FONTE_DELAY_SERVICE" "$CONFIG_DESTINO_DELAY_SERVICE"
print_success "Arquivo .service do delay de rede copiado para '$CONFIG_DESTINO_DELAY_SERVICE'."

print_step "[3/4] Configurando permissões para o script de delay de rede"
sudo chmod +x "$CONFIG_DESTINO_DELAY_SCRIPT"
print_info "Permissão de execução concedida para '$CONFIG_DESTINO_DELAY_SCRIPT'."

print_step "[4/4] Habilitando e iniciando serviço de delay de rede"
sudo systemctl daemon-reload # Garante que o novo serviço seja reconhecido
sudo systemctl enable rede-delay.service
sudo systemctl start rede-delay.service
if systemctl is-active --quiet rede-delay.service; then
    print_success "Serviço de delay de rede habilitado e iniciado."
else
    print_error "Falha ao iniciar o serviço de delay de rede. Verifique com 'systemctl status rede-delay.service'."
fi
print_section_header "FASE 3: CONFIGURAÇÃO DO DELAY DE REDE CONCLUÍDA!"

# --- FINALIZAÇÃO ---
print_warning "ATENÇÃO: O sistema será REINICIADO para aplicar todas as configurações."
sudo reboot