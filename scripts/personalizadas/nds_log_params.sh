#!/bin/sh

# Diretório e arquivos de log
LOG_DIR="/tmp/nodogsplash_debug"
MAIN_LOG_FILE="$LOG_DIR/binauth_main_details.log"
CSV_DATA_FILE="$LOG_DIR/dados_completos.csv"
CSV_HEADER="\"Timestamp_Conexao\",\"MAC_Cliente\",\"Nome_Usuario\",\"Matricula\",\"Timestamp_Desconexao\""

# Função para log detalhado
log_main_detail() {
    echo "$(date +"%Y-%m-%d %T") - $1" >> "$MAIN_LOG_FILE" 2>&1
}

# Inicialização
mkdir -p "$LOG_DIR" > /dev/null 2>&1

# Cria o CSV com cabeçalho, se necessário
if [ ! -f "$CSV_DATA_FILE" ] || ! grep -q "Timestamp_Conexao" "$CSV_DATA_FILE"; then
    echo "$CSV_HEADER" > "$CSV_DATA_FILE" 2>&1
fi

# Logs iniciais
log_main_detail "=============================================="
log_main_detail "Script BinAuth chamado."
log_main_detail "Ação recebida (Argumento 1): [$1]"
log_main_detail "MAC do Cliente (Argumento 2): [$2]"

CLIENT_MAC="$2"

### Tratamento da ação "auth_client" ###
if [ "$1" = "auth_client" ]; then
    RECEIVED_USERNAME_ARG="$3"
    RECEIVED_PASSWORD_ARG="$4"
    TIMESTAMP_CONEXAO=$(date +"%Y-%m-%d %T")
    TIMESTAMP_DESCONEXAO="0"

    log_main_detail "Tentativa de autenticação (auth_client detectada):"
    log_main_detail "Username (Nome) bruto recebido (Arg 3): [$RECEIVED_USERNAME_ARG]"
    log_main_detail "Password (Matrícula) bruto recebido (Arg 4): [$RECEIVED_PASSWORD_ARG]"

    # Decodificação e limpeza
    DECODED_USERNAME_WITH_SPACES=$(echo "$RECEIVED_USERNAME_ARG" | sed 's/%20/ /g; s/%25/%/g; s/%2B/+/g')
    DECODED_USERNAME=$(printf '%b' "$DECODED_USERNAME_WITH_SPACES")
    CLEANED_USERNAME=$(echo "$DECODED_USERNAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    CLEANED_PASSWORD=$(echo "$RECEIVED_PASSWORD_ARG" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    log_main_detail "Username Decodificado e Limpo: [$CLEANED_USERNAME]"
    log_main_detail "Password Limpo: [$CLEANED_PASSWORD]"

    # Grava no CSV se válido
    if [ -n "$CLEANED_USERNAME" ] && [ -n "$CLEANED_PASSWORD" ]; then
        echo "\"$TIMESTAMP_CONEXAO\",\"$CLIENT_MAC\",\"$CLEANED_USERNAME\",\"$CLEANED_PASSWORD\",\"$TIMESTAMP_DESCONEXAO\"" >> "$CSV_DATA_FILE" 2>&1
    else
        log_main_detail "AVISO: Username ou Password limpos estão vazios. Não gravando no CSV desta vez."
    fi

    # Resposta ao nodogsplash
    printf "7200 0 0\n"
    exit 0
fi

### Tratamento de ações de desautenticação ###
if [ "$1" = "client_deauth" ] || [ "$1" = "idle_deauth" ] || \
   [ "$1" = "timeout_deauth" ] || [ "$1" = "ndsctl_deauth" ] || \
   [ "$1" = "shutdown_deauth" ]; then

    SESSION_START_EPOCH="$5"
    SESSION_END_EPOCH="$6"

    SESSION_START_HR=$(date -d "@$SESSION_START_EPOCH" +"%Y-%m-%d %T" 2>/dev/null || echo "$SESSION_START_EPOCH")
    SESSION_END_HR=$(date -d "@$SESSION_END_EPOCH" +"%Y-%m-%d %T" 2>/dev/null || echo "$SESSION_END_EPOCH")

    log_main_detail "Evento de Desautenticação: [$1] para MAC [$CLIENT_MAC]"
    log_main_detail "Bytes Entrando: [$3], Bytes Saindo: [$4]"
    log_main_detail "Início Sessão (Epoch): [$SESSION_START_EPOCH] -> [$SESSION_START_HR]"
    log_main_detail "Fim Sessão (Epoch): [$SESSION_END_EPOCH] -> [$SESSION_END_HR]"

    exit 0
fi

### Tratamento de outras autenticações ###
if [ "$1" = "client_auth" ] || [ "$1" = "ndsctl_auth" ]; then
    log_main_detail "Evento de Autenticação (não 'auth_client'): [$1] para MAC [$CLIENT_MAC]. Args: $3 $4 $5 $6"
    exit 0
fi

# Ação não reconhecida
log_main_detail "Ação '$1' não tratada explicitamente ou inesperada. Saindo com erro."
exit 1
