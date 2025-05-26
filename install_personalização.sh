#!/bin/bash

# Define o diretório raiz do repositório
REPO_ROOT=$(pwd)

# Função para fazer perguntas Sim/Não
ask_yes_no() {
    while true; do
        read -p "$1 (s/n): " sn
        case $sn in
            [Ss]* ) return 0;; # Sim
            [Nn]* ) return 1;; # Não
            * ) echo "Por favor, responda com 's' para sim ou 'n' para não.";;
        esac
    done
}

# --- Início da Instalação ---
echo "================================================="
echo " Início da Instalação e Configuração da Solução"
echo "================================================="
echo

# --- Escolhas do Usuário ---

echo "Serão oferecidas algumas opções de personalização."
echo "Mais informações sobre cada serviço podem ser encontradas na pasta /docs."
echo

# Pergunta sobre Leds Automáticos
if ask_yes_no "Deseja instalar o serviço de LEDs automáticos para status?"; then
    INSTALL_LEDS=true
    echo "  >> Serviço de LEDs será instalado."
else
    INSTALL_LEDS=false
    echo "  >> Serviço de LEDs NÃO será instalado."
fi
echo

# Pergunta sobre Ventoinha
if ask_yes_no "Deseja instalar o serviço de ventoinha para refrigeração?"; then
    INSTALL_FAN=true
    echo "  >> Serviço de ventoinha será instalado."
else
    INSTALL_FAN=false
    echo "  >> Serviço de ventoinha NÃO será instalado."
fi
echo

# --- Instalação da Biblioteca pinctrl (se necessário) ---

if [ "$INSTALL_LEDS" = true ] || [ "$INSTALL_FAN" = true ]; then
    echo ">>> Iniciando a instalação da biblioteca 'pinctrl' (necessária para LEDs e/ou Ventoinha)..."
    PINCTRL_SCRIPT="$REPO_ROOT/pinctrl_lib/pinctrl_install.sh"

    if [ ! -f "$PINCTRL_SCRIPT" ]; then
        echo "    ERRO: Arquivo '$PINCTRL_SCRIPT' não encontrado!"
        exit 1
    fi

    sudo chmod +x "$PINCTRL_SCRIPT"
    if sudo "$PINCTRL_SCRIPT"; then
        echo ">>> Biblioteca 'pinctrl' instalada com sucesso."
    else
        echo "    ERRO: Falha ao instalar a biblioteca 'pinctrl'."
        exit 2
    fi
    echo
fi

# --- Instalação do Serviço de LEDs (se escolhido) ---

if [ "$INSTALL_LEDS" = true ]; then
    echo "========================================="
    echo " Iniciando a Instalação do Serviço de LEDs"
    echo "========================================="

    CONFIG_FONTE1="$REPO_ROOT/scripts/personalizadas/led_on/pinctrl-monitor.sh"
    CONFIG_DESTINO1="/usr/local/bin/pinctrl-monitor.sh"
    CONFIG_FONTE2="$REPO_ROOT/scripts/personalizadas/led_on/pinctrl-monitor.service"
    CONFIG_DESTINO2="/etc/systemd/system/pinctrl-monitor.service"
    CONFIG_FONTE5="$REPO_ROOT/scripts/personalizadas/led_on/shutdown_pins.sh"
    CONFIG_DESTINO5="/usr/local/bin/shutdown_pins.sh"
    CONFIG_FONTE6="$REPO_ROOT/scripts/personalizadas/led_on/rede-delay.sh"
    CONFIG_DESTINO6="/usr/local/bin/rede-delay.sh"

    echo ">>> [1/6] Verificando arquivos necessários..."
    if [ ! -f "$CONFIG_FONTE1" ] || [ ! -f "$CONFIG_FONTE2" ] || [ ! -f "$CONFIG_FONTE5" ] || [ ! -f "$CONFIG_FONTE6" ]; then
        echo "    ERRO: Um ou mais arquivos do serviço de LEDs não foram encontrados! Certifique-se de executar da pasta do repositório."
        exit 3
    fi
    echo ">>> [1/6] Arquivos verificados."

    echo ">>> [2/6] Copiando script de LEDs ($CONFIG_FONTE1)..."
    sudo cp "$CONFIG_FONTE1" "$CONFIG_DESTINO1"
    echo ">>> [2/6] Script de LEDs copiado."

    echo ">>> [3/6] Copiando .service do serviço de LEDs ($CONFIG_FONTE2)..."
    sudo cp "$CONFIG_FONTE2" "$CONFIG_DESTINO2"
    echo ">>> [3/6] .service de LEDs copiado."

    echo ">>> [4/6] Copiando script de desligamento ($CONFIG_FONTE5)..."
    sudo cp "$CONFIG_FONTE5" "$CONFIG_DESTINO5"
    echo "    INFO: O script 'shutdown_pins.sh' garante que os LEDs sejam desligados corretamente durante o reboot ou shutdown."
    echo "    AVISO: Devido à configuração padrão do Raspberry Pi, algum LED pode acender brevemente antes do boot completo. Isso é normal e corrigido após o início do sistema."
    echo ">>> [4/6] Script de desligamento copiado."

    echo ">>> [5/6] Copiando script de delay/animação da rede ($CONFIG_FONTE6)..."
    sudo cp "$CONFIG_FONTE6" "$CONFIG_DESTINO6"
    echo "    INFO: O script 'rede-delay.sh' (versão com LEDs) inclui animações indicando o status do boot e da rede."
    echo ">>> [5/6] Script de delay da rede copiado."

    echo ">>> [6/6] Configurando permissões e serviços..."
    sudo chmod +x "$CONFIG_DESTINO1"
    sudo chmod +x "$CONFIG_DESTINO5"
    sudo chmod +x "$CONFIG_DESTINO6" # Garante que o rede-delay seja executável
    echo "    Scripts definidos como executáveis."
    sudo systemctl daemon-reload
    echo "    Systemd daemon recarregado."
    sudo systemctl enable pinctrl-monitor
    sudo systemctl start pinctrl-monitor
    echo ">>> [6/6] Serviço de LEDs habilitado e iniciado."
    echo ">>> Instalação do Serviço de LEDs concluída."
    echo
fi

# --- Instalação do Serviço de Ventoinha (se escolhido) ---

if [ "$INSTALL_FAN" = true ]; then
    echo "============================================="
    echo " Iniciando a Instalação do Serviço de Ventoinha"
    echo "============================================="

    CONFIG_FONTE3="$REPO_ROOT/scripts/personalizadas/fan_on/temp-monitor.sh"
    CONFIG_DESTINO3="/usr/local/bin/temp-monitor.sh"
    CONFIG_FONTE4="$REPO_ROOT/scripts/personalizadas/fan_on/temp-monitor.service"
    CONFIG_DESTINO4="/etc/systemd/system/temp-monitor.service"

    echo ">>> [1/4] Verificando arquivos necessários..."
    if [ ! -f "$CONFIG_FONTE3" ] || [ ! -f "$CONFIG_FONTE4" ]; then
        echo "    ERRO: Um ou mais arquivos do serviço de ventoinha não foram encontrados! Certifique-se de executar da pasta do repositório."
        exit 3
    fi
    echo ">>> [1/4] Arquivos verificados."

    echo ">>> [2/4] Copiando script da Ventoinha ($CONFIG_FONTE3)..."
    sudo cp "$CONFIG_FONTE3" "$CONFIG_DESTINO3"
    echo ">>> [2/4] Script de Ventoinha copiado."

    echo ">>> [3/4] Copiando .service do serviço de ventoinha ($CONFIG_FONTE4)..."
    sudo cp "$CONFIG_FONTE4" "$CONFIG_DESTINO4"
    echo ">>> [3/4] .service de ventoinha copiado."

    echo ">>> [4/4] Configurando permissões e serviços..."
    sudo chmod +x "$CONFIG_DESTINO3"
    echo "    Script definido como executável."
    sudo systemctl daemon-reload
    echo "    Systemd daemon recarregado."
    sudo systemctl enable temp-monitor
    sudo systemctl start temp-monitor
    echo ">>> [4/4] Serviço de Ventoinha habilitado e iniciado."
    echo ">>> Instalação do Serviço de Ventoinha concluída."
    echo
fi

# --- Instalação do Restante da Solução ---

if ask_yes_no "Deseja prosseguir com a instalação do restante da solução (serviços web, backend, configurações de rede)?"; then
    echo
    echo "================================================="
    echo " Iniciando a Instalação do Restante da Solução"
    echo "================================================="

    # Copia o rede-delay padrão SE os LEDs não foram instalados
    if [ "$INSTALL_LEDS" = false ]; then
        echo ">>> Copiando script 'rede-delay.sh' padrão (sem LEDs)..."
        CONFIG_FONTE7="$REPO_ROOT/scripts/padrao/rede-delay.sh"
        CONFIG_DESTINO7="/usr/local/bin/rede-delay.sh"
        if [ ! -f "$CONFIG_FONTE7" ]; then
            echo "    ERRO: Arquivo '$CONFIG_FONTE7' não encontrado!"
            exit 3
        fi
        sudo cp "$CONFIG_FONTE7" "$CONFIG_DESTINO7"
        sudo chmod +x "$CONFIG_DESTINO7"
        echo ">>> Script 'rede-delay.sh' padrão copiado e definido como executável."
    fi

    # Lista de arquivos e destinos para cópia
    declare -A FILES_TO_COPY
    FILES_TO_COPY=(
        ["$REPO_ROOT/scripts/personalizadas/painel_http.service"]="/etc/systemd/system/painel_http.service"
        ["$REPO_ROOT/scripts/personalizadas/backendc1.service"]="/etc/systemd/system/backendc1.service"
        ["$REPO_ROOT/configuracoes/personalizadas/nodogsplash.conf"]="/etc/nodogsplash/nodogsplash.conf"
        ["$REPO_ROOT/configuracoes/personalizadas/hostapd.conf"]="/etc/hostapd/hostapd.conf" # CORRIGIDO: Assumindo destino correto
        ["$REPO_ROOT/configuracoes/personalizadas/090_wlan0.conf"]="/etc/dnsmasq.d/090_wlan0.conf"
        ["$REPO_ROOT/web/nodogsplash/splash.html"]="/etc/nodogsplash/htdocs/splash.html"
        ["$REPO_ROOT/web/nodogsplash/status.html"]="/etc/nodogsplash/htdocs/status.html"
    )

    # Copiando arquivos de configuração e web
    for FONTE in "${!FILES_TO_COPY[@]}"; do
        DESTINO=${FILES_TO_COPY[$FONTE]}
        echo ">>> Copiando $FONTE para $DESTINO..."
        if [ ! -f "$FONTE" ]; then
            echo "    ERRO: Arquivo '$FONTE' não encontrado!"
            # Poderia adicionar 'continue' ou 'exit 4' dependendo da criticidade
        else
            # Cria o diretório de destino se não existir (para /etc/nodogsplash/htdocs/ e /etc/hostapd/ por exemplo)
            sudo mkdir -p "$(dirname "$DESTINO")"
            sudo cp "$FONTE" "$DESTINO"
            echo "    Copiado com sucesso."
        fi
    done

    # Habilitando e iniciando serviços
    echo ">>> Habilitando e iniciando painel_http..."
    sudo systemctl enable painel_http
    sudo systemctl start painel_http

    echo ">>> Habilitando e iniciando backendc1..."
    sudo systemctl enable backendc1
    sudo systemctl start backendc1

    # Movendo sistema_presenca e compilando
    CONFIG_FONTE10="$REPO_ROOT/sistema_presenca"
    CONFIG_DESTINO10="/etc"
    echo ">>> Movendo $CONFIG_FONTE10 para $CONFIG_DESTINO10..."
    if [ ! -d "$CONFIG_FONTE10" ]; then
         echo "    ERRO: Diretório '$CONFIG_FONTE10' não encontrado!"
         exit 5
    fi
    sudo mv "$CONFIG_FONTE10" "$CONFIG_DESTINO10"
    echo "    Movido com sucesso."

    echo ">>> Compilando código C em /etc/sistema_presenca/codigo-c..."
    if [ -d "/etc/sistema_presenca/codigo-c" ]; then
        (cd /etc/sistema_presenca/codigo-c && sudo make) # Executa em subshell para não perder o diretório
        if [ $? -eq 0 ]; then
            echo "    Compilado com sucesso."
        else
            echo "    ERRO: Falha na compilação do código C."
            # Poderia adicionar 'exit 6'
        fi
    else
        echo "    AVISO: Diretório /etc/sistema_presenca/codigo-c não encontrado, pulando compilação."
    fi

    echo
    echo "================================================="
    echo " Instalação do Restante da Solução Concluída"
    echo "================================================="
    echo

else
    echo
    echo ">>> Instalação do restante da solução foi cancelada pelo usuário."
    echo
fi

# --- Finalização ---
echo "================================================="
echo "      Processo de Instalação Finalizado."
echo "================================================="
echo "O sistema será reiniciado para aplicar as alterações."
echo "Obrigado por utilizar a solução!"
echo "Para mais informações, consulte a documentação em /docs."
echo "================================================="

sudo reboot
