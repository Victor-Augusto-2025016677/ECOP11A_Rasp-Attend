#!/bin/bash

# Define o diretório raiz do repositório
REPO_ROOT=$(pwd)

# --- Funções Auxiliares ---

# Função para fazer perguntas Sim/Não
ask_yes_no() {
    while true; do
        read -p "$1 (s/n): " sn
        case $sn in
            [Ss]* ) return 0;; # Sim
            [Nn]* ) return 1;; # Não
            * ) echo "   ATENÇÃO: Por favor, responda com 's' para sim ou 'n' para não.";;
        esac
    done
}

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

# --- Início da Instalação ---
clear # Limpa a tela para uma melhor visualização
print_section_header "Início da Instalação e Configuração da Solução"

# --- Escolhas do Usuário ---
echo "Serão oferecidas algumas opções de personalização para a sua instalação."
echo "Mais informações sobre cada serviço podem ser encontradas na pasta /docs do repositório."
echo

# Pergunta sobre Leds Automáticos
if ask_yes_no "Deseja instalar o serviço de LEDs automáticos para status?"; then
    INSTALL_LEDS=true
    print_success "Serviço de LEDs será instalado."
else
    INSTALL_LEDS=false
    print_info "Serviço de LEDs NÃO será instalado."
fi
echo

# Pergunta sobre Ventoinha
if ask_yes_no "Deseja instalar o serviço de ventoinha para refrigeração?"; then
    INSTALL_FAN=true
    print_success "Serviço de ventoinha será instalado."
else
    INSTALL_FAN=false
    print_info "Serviço de ventoinha NÃO será instalado."
fi
echo

# --- Instalação da Biblioteca pinctrl (se necessário) ---
if [ "$INSTALL_LEDS" = true ] || [ "$INSTALL_FAN" = true ]; then
    print_section_header "Instalando Biblioteca 'pinctrl'"
    print_step "Iniciando a instalação da biblioteca 'pinctrl' (necessária para LEDs e/ou Ventoinha)"
    PINCTRL_SCRIPT="$REPO_ROOT/pinctrl_lib/pinctrl_install.sh"

    if [ ! -f "$PINCTRL_SCRIPT" ]; then
        print_error "Arquivo '$PINCTRL_SCRIPT' não encontrado! Verifique o caminho e tente novamente."
        exit 1
    fi

    sudo chmod +x "$PINCTRL_SCRIPT"
    if sudo "$PINCTRL_SCRIPT"; then
        print_success "Biblioteca 'pinctrl' instalada com sucesso."
    else
        print_error "Falha ao instalar a biblioteca 'pinctrl'. Verifique os logs acima para mais detalhes."
        exit 2
    fi
    echo
fi

# --- Instalação do Serviço de LEDs ---
if [ "$INSTALL_LEDS" = true ]; then
    print_section_header "Instalando Serviço de LEDs"

    CONFIG_FONTE1="$REPO_ROOT/scripts/personalizadas/led_on/pinctrl-monitor.sh"
    CONFIG_DESTINO1="/usr/local/bin/pinctrl-monitor.sh"
    CONFIG_FONTE2="$REPO_ROOT/scripts/personalizadas/led_on/pinctrl-monitor.service"
    CONFIG_DESTINO2="/etc/systemd/system/pinctrl-monitor.service"
    CONFIG_FONTE5="$REPO_ROOT/scripts/personalizadas/led_on/shutdown_pins.sh"
    CONFIG_DESTINO5="/usr/local/bin/shutdown_pins.sh"
    CONFIG_FONTE6="$REPO_ROOT/scripts/personalizadas/led_on/rede-delay.sh"
    CONFIG_DESTINO6="/usr/local/bin/rede-delay.sh"

    print_step "[1/6] Verificando arquivos necessários para o serviço de LEDs"
    if [ ! -f "$CONFIG_FONTE1" ] || [ ! -f "$CONFIG_FONTE2" ] || [ ! -f "$CONFIG_FONTE5" ] || [ ! -f "$CONFIG_FONTE6" ]; then
        print_error "Um ou mais arquivos do serviço de LEDs não foram encontrados! Certifique-se de executar o script da pasta raiz do repositório."
        exit 3
    fi
    print_success "[1/6] Arquivos do serviço de LEDs verificados."

    print_step "[2/6] Copiando script de monitoramento de LEDs ('$CONFIG_FONTE1')"
    sudo cp "$CONFIG_FONTE1" "$CONFIG_DESTINO1"
    print_success "[2/6] Script de LEDs copiado para '$CONFIG_DESTINO1'."

    print_step "[3/6] Copiando arquivo de serviço systemd para LEDs ('$CONFIG_FONTE2')"
    sudo cp "$CONFIG_FONTE2" "$CONFIG_DESTINO2"
    print_success "[3/6] Arquivo .service de LEDs copiado para '$CONFIG_DESTINO2'."

    print_step "[4/6] Copiando script de desligamento dos LEDs ('$CONFIG_FONTE5')"
    sudo cp "$CONFIG_FONTE5" "$CONFIG_DESTINO5"
    print_info "O script 'shutdown_pins.sh' garante que os LEDs sejam desligados corretamente durante o reboot ou shutdown."
    print_warning "Devido à configuração padrão do Raspberry Pi, alguns LEDs podem acender brevemente durante o boot. Isso é normal e será corrigido após o início completo do sistema."
    print_success "[4/6] Script de desligamento dos LEDs copiado para '$CONFIG_DESTINO5'."

    print_step "[5/6] Copiando script de delay/animação da rede (com LEDs) ('$CONFIG_FONTE6')"
    sudo cp "$CONFIG_FONTE6" "$CONFIG_DESTINO6"
    print_info "O script 'rede-delay.sh' (versão com LEDs) inclui animações indicando o status do boot e da rede."
    print_success "[5/6] Script de delay da rede (com LEDs) copiado para '$CONFIG_DESTINO6'."

    print_step "[6/6] Configurando permissões e ativando o serviço de LEDs"
    sudo chmod +x "$CONFIG_DESTINO1"
    sudo chmod +x "$CONFIG_DESTINO5"
    sudo chmod +x "$CONFIG_DESTINO6"
    print_info "Permissões de execução concedidas aos scripts."
    sudo systemctl daemon-reload
    print_info "Systemd daemon recarregado."
    sudo systemctl enable pinctrl-monitor.service
    sudo systemctl start pinctrl-monitor.service
    if systemctl is-active --quiet pinctrl-monitor.service; then
        print_success "[6/6] Serviço de LEDs habilitado e iniciado com sucesso."
    else
        print_error "[6/6] Falha ao iniciar o serviço de LEDs. Verifique o status com 'systemctl status pinctrl-monitor.service'."
    fi
    print_success "Instalação do Serviço de LEDs concluída."
    echo
fi

# --- Instalação do Serviço de Ventoinha ---
if [ "$INSTALL_FAN" = true ]; then
    print_section_header "Instalando Serviço de Ventoinha"

    CONFIG_FONTE3="$REPO_ROOT/scripts/personalizadas/fan_on/temp-monitor.sh"
    CONFIG_DESTINO3="/usr/local/bin/temp-monitor.sh"
    CONFIG_FONTE4="$REPO_ROOT/scripts/personalizadas/fan_on/temp-monitor.service"
    CONFIG_DESTINO4="/etc/systemd/system/temp-monitor.service"

    print_step "[1/4] Verificando arquivos necessários para o serviço de ventoinha"
    if [ ! -f "$CONFIG_FONTE3" ] || [ ! -f "$CONFIG_FONTE4" ]; then
        print_error "Um ou mais arquivos do serviço de ventoinha não foram encontrados! Certifique-se de executar o script da pasta raiz do repositório."
        exit 3
    fi
    print_success "[1/4] Arquivos do serviço de ventoinha verificados."

    print_step "[2/4] Copiando script de monitoramento de temperatura ('$CONFIG_FONTE3')"
    sudo cp "$CONFIG_FONTE3" "$CONFIG_DESTINO3"
    print_success "[2/4] Script de ventoinha copiado para '$CONFIG_DESTINO3'."

    print_step "[3/4] Copiando arquivo de serviço systemd para ventoinha ('$CONFIG_FONTE4')"
    sudo cp "$CONFIG_FONTE4" "$CONFIG_DESTINO4"
    print_success "[3/4] Arquivo .service de ventoinha copiado para '$CONFIG_DESTINO4'."

    print_step "[4/4] Configurando permissões e ativando o serviço de ventoinha"
    sudo chmod +x "$CONFIG_DESTINO3"
    print_info "Permissão de execução concedida ao script."
    sudo systemctl daemon-reload
    print_info "Systemd daemon recarregado."
    sudo systemctl enable temp-monitor.service
    sudo systemctl start temp-monitor.service
    if systemctl is-active --quiet temp-monitor.service; then
        print_success "[4/4] Serviço de Ventoinha habilitado e iniciado com sucesso."
    else
        print_error "[4/4] Falha ao iniciar o serviço de ventoinha. Verifique o status com 'systemctl status temp-monitor.service'."
    fi
    print_success "Instalação do Serviço de Ventoinha concluída."
    echo
fi

# --- Instalação do Restante da Solução ---
if ask_yes_no "Deseja prosseguir com a instalação do restante da solução (serviços web, backend, configurações de rede)?"; then
    print_section_header "Instalando o Restante da Solução"

    # Copia script rede-delay.sh padrão SE LEDs NÃO foram instalados
    if [ "$INSTALL_LEDS" = false ]; then
        print_step "Copiando script 'rede-delay.sh' padrão (sem LEDs)..."
        CONFIG_FONTE7="$REPO_ROOT/scripts/personalizadas/rede-delay.sh"
        CONFIG_DESTINO7="/usr/local/bin/rede-delay.sh"
        if [ ! -f "$CONFIG_FONTE7" ]; then
            print_error "Arquivo '$CONFIG_FONTE7' (rede-delay.sh padrão) não encontrado!"
            # Considerar se deve sair ou apenas avisar e continuar
        else
            sudo cp "$CONFIG_FONTE7" "$CONFIG_DESTINO7"
            sudo chmod +x "$CONFIG_DESTINO7"
            print_success "Script 'rede-delay.sh' padrão copiado e definido como executável."
        fi
    fi

    # Script nds_log_params.sh
    print_step "Copiando script 'nds_log_params.sh'..."
    CONFIG_FONTE11="$REPO_ROOT/scripts/personalizadas/nds_log_params.sh"
    CONFIG_DESTINO11="/usr/local/bin/nds_log_params.sh"
    if [ -f "$CONFIG_FONTE11" ]; then
        sudo cp "$CONFIG_FONTE11" "$CONFIG_DESTINO11"
        sudo chmod +x "$CONFIG_DESTINO11"
        print_success "Script 'nds_log_params.sh' copiado e configurado."
    else
        print_warning "Arquivo '$CONFIG_FONTE11' não encontrado. Pulando esta etapa."
    fi

    # Arquivos do Nodogsplash htdocs
    print_step "Copiando arquivos de interface do Nodogsplash (splash.html, status.html)..."
    CONFIG_FONTE13="$REPO_ROOT/web/nodogsplash/splash.html"
    CONFIG_DESTINO13="/etc/nodogsplash/htdocs/splash.html"
    CONFIG_FONTE14="$REPO_ROOT/web/nodogsplash/status.html"
    CONFIG_DESTINO14="/etc/nodogsplash/htdocs/status.html"

    if [ -f "$CONFIG_FONTE13" ]; then
        sudo cp "$CONFIG_FONTE13" "$CONFIG_DESTINO13"
        print_success "Arquivo 'splash.html' copiado para '$CONFIG_DESTINO13'."
    else
        print_warning "Arquivo '$CONFIG_FONTE13' não encontrado. Pulando."
    fi
    if [ -f "$CONFIG_FONTE14" ]; then
        sudo cp "$CONFIG_FONTE14" "$CONFIG_DESTINO14"
        print_success "Arquivo 'status.html' copiado para '$CONFIG_DESTINO14'."
    else
        print_warning "Arquivo '$CONFIG_FONTE14' não encontrado. Pulando."
    fi

    # Configuração Nodogsplash
    print_step "Aplicando configuração do Nodogsplash ('nodogsplash.conf')..."
    CONFIG_FONTE12="$REPO_ROOT/configuracoes/personalizadas/nodogsplash.conf"
    CONFIG_DESTINO12="/etc/nodogsplash/nodogsplash.conf"
    if [ -f "$CONFIG_FONTE12" ]; then
        sudo cp "$CONFIG_FONTE12" "$CONFIG_DESTINO12"
        print_success "Arquivo 'nodogsplash.conf' copiado para '$CONFIG_DESTINO12'."
        print_step "Reiniciando Nodogsplash para aplicar configurações..."
        if sudo systemctl restart nodogsplash; then
            print_success "Nodogsplash reiniciado com sucesso."
        else
            print_error "Falha ao reiniciar Nodogsplash. Verifique o status com 'systemctl status nodogsplash'."
        fi
    else
        print_warning "Arquivo '$CONFIG_FONTE12' não encontrado. Pulando configuração do Nodogsplash."
    fi

    # Serviço Painel HTTP
    print_step "Configurando serviço do Painel HTTP ('painel_http.service')..."
    CONFIG_FONTE15="$REPO_ROOT/scripts/personalizadas/painel_http.service"
    CONFIG_DESTINO15="/etc/systemd/system/painel_http.service"
    if [ -f "$CONFIG_FONTE15" ]; then
        sudo cp "$CONFIG_FONTE15" "$CONFIG_DESTINO15"
        print_success "Arquivo 'painel_http.service' copiado para '$CONFIG_DESTINO15'."
    else
        print_warning "Arquivo '$CONFIG_FONTE15' não encontrado. Pulando configuração do Painel HTTP."
    fi

    # Serviço Backend C1
    print_step "Configurando serviço do Backend C1 ('backendc1.service')..."
    CONFIG_FONTE16="$REPO_ROOT/scripts/personalizadas/backendc1.service"
    CONFIG_DESTINO16="/etc/systemd/system/backendc1.service"
    if [ -f "$CONFIG_FONTE16" ]; then
        sudo cp "$CONFIG_FONTE16" "$CONFIG_DESTINO16"
        print_success "Arquivo 'backendc1.service' copiado para '$CONFIG_DESTINO16'."
    else
        print_warning "Arquivo '$CONFIG_FONTE16' não encontrado. Pulando configuração do Backend C1."
    fi

    # Sistema de Presença
    print_step "Movendo e compilando Sistema de Presença..."
    CONFIG_FONTE17="$REPO_ROOT/sistema_presenca"
    CONFIG_DESTINO17_PARENT="/etc/" # Diretório pai onde a pasta será movida
    CONFIG_DESTINO17_FINAL="/etc/sistema_presenca" # Caminho final após mover

    if [ -d "$CONFIG_FONTE17" ]; then
        # Remove o diretório de destino se já existir para evitar erro no mv
        if [ -d "$CONFIG_DESTINO17_FINAL" ]; then
            print_info "Removendo diretório existente '$CONFIG_DESTINO17_FINAL' antes de mover o novo."
            sudo rm -rf "$CONFIG_DESTINO17_FINAL"
        fi
        sudo mv "$CONFIG_FONTE17" "$CONFIG_DESTINO17_PARENT"
        print_success "Pasta 'sistema_presenca' movida para '$CONFIG_DESTINO17_PARENT'."

        if [ -d "$CONFIG_DESTINO17_FINAL/codigo-c" ]; then
            print_step "Compilando código C do Sistema de Presença..."
            # Salva o diretório atual e muda para o diretório do make
            CURRENT_DIR_MAKE=$(pwd)
            cd "$CONFIG_DESTINO17_FINAL/codigo-c/"
            if sudo make; then
                print_success "Código C do Sistema de Presença compilado com sucesso."
            else
                print_error "Falha ao compilar o código C do Sistema de Presença. Verifique as mensagens do 'make'."
            fi
            cd "$CURRENT_DIR_MAKE" # Retorna ao diretório original
        else
            print_warning "Diretório '$CONFIG_DESTINO17_FINAL/codigo-c' não encontrado. Compilação do código C pulada."
        fi
    else
        print_warning "Pasta '$CONFIG_FONTE17' não encontrada. Pulando instalação do Sistema de Presença."
    fi

    # Habilitar e Iniciar Serviços (Painel HTTP e Backend C1)
    print_step "Habilitando e iniciando serviços do Painel HTTP e Backend C1..."
    sudo systemctl daemon-reload # Recarregar caso novos .service tenham sido adicionados
    if [ -f "$CONFIG_DESTINO15" ]; then # Verifica se o arquivo de serviço existe antes de tentar habilitar/iniciar
        sudo systemctl enable painel_http.service
        if sudo systemctl start painel_http.service; then
            print_success "Serviço 'painel_http.service' habilitado e iniciado."
        else
            print_error "Falha ao iniciar 'painel_http.service'. Verifique com 'systemctl status painel_http.service'."
        fi
    else
        print_warning "Serviço 'painel_http.service' não foi copiado, portanto não será habilitado/iniciado."
    fi

    if [ -f "$CONFIG_DESTINO16" ]; then # Verifica se o arquivo de serviço existe
        sudo systemctl enable backendc1.service
        if sudo systemctl start backendc1.service; then
            print_success "Serviço 'backendc1.service' habilitado e iniciado."
        else
            print_error "Falha ao iniciar 'backendc1.service'. Verifique com 'systemctl status backendc1.service'."
        fi
    else
        print_warning "Serviço 'backendc1.service' não foi copiado, portanto não será habilitado/iniciado."
    fi

    # Configuração Hostapd e reinício de serviços de rede
    print_step "Aplicando configuração do Hostapd ('hostapd.conf')..."
    CONFIG_FONTE18="$REPO_ROOT/configuracoes/personalizadas/hostapd.conf"
    CONFIG_DESTINO18="/etc/hostapd/hostapd.conf"
    if [ -f "$CONFIG_FONTE18" ]; then
        sudo cp "$CONFIG_FONTE18" "$CONFIG_DESTINO18"
        print_success "Arquivo 'hostapd.conf' copiado para '$CONFIG_DESTINO18'."
        print_step "Reiniciando serviços de rede (hostapd, dnsmasq, nodogsplash)..."
        if sudo systemctl restart hostapd && sudo systemctl restart dnsmasq && sudo systemctl restart nodogsplash; then
            print_success "Serviços de rede reiniciados com sucesso."
        else
            print_error "Falha ao reiniciar um ou mais serviços de rede. Verifique o status individualmente."
        fi
    else
        print_warning "Arquivo '$CONFIG_FONTE18' não encontrado. Pulando configuração do Hostapd."
    fi

    print_success "Instalação do restante da solução concluída."
    echo
else
    echo
    print_info "Instalação do restante da solução foi CANCELADA pelo usuário."
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
