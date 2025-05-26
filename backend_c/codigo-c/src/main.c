#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <unistd.h>

const char* BINAUTH_CSV_PATH = "/tmp/nodogsplash_debug/dados_completos.csv";
const char* C_PROJECT_CSV_DIR = "/home/victo/codigo-c/csv";
const char* EVENTS_LOG_CSV_PATH = "/home/victo/codigo-c/csv/eventos_sessoes_C.csv";
const char* EFFECTIVELY_ACTIVE_MACS_FILE_PATH = "/home/victo/codigo-c/csv/c_macs_efetivamente_ativos_anterior.txt";
const char* UPTIME_REPORT_CSV_PATH = "/home/victo/codigo-c/htdocs/relatorio_usuarios_C.csv";

const char* HEADER_EVENTS_LOG_CSV = "\"Timestamp_Evento\",\"MAC_Cliente\",\"Nome_Usuario\",\"Matricula\",\"Tipo_Evento\"\n";
const char* HEADER_UPTIME_REPORT_CSV = "\"MAC_Cliente\",\"Nome_Usuario\",\"Matricula\",\"Primeira_Conexao_Geral_TS\",\"Ultimo_Evento_Registrado_TS\",\"Status_Atual_Inferido\",\"Total_Uptime_Segundos\",\"Numero_De_Sessoes\"\n";

#define MAX_LINE_LEN 1024
#define MAC_LEN 18
#define NAME_LEN 100
#define MATRICULA_LEN 20
#define TIMESTAMP_LEN 80 // Aumentado para garantir espaço
#define EVENT_TYPE_LEN 20

typedef struct MACNode {
    char mac[MAC_LEN];
    struct MACNode* next;
} MACNode;

typedef struct UsuarioReportInfo {
    char mac_cliente[MAC_LEN];
    char nome_usuario[NAME_LEN];
    char matricula[MATRICULA_LEN];
    char primeira_conexao_ts[TIMESTAMP_LEN];
    char ultimo_evento_ts[TIMESTAMP_LEN];
    char status_atual[EVENT_TYPE_LEN];
    long total_uptime_segundos;
    int numero_sessoes;
    time_t sessao_ativa_start_epoch;
    struct UsuarioReportInfo* next;
} UsuarioReportInfo;

typedef struct EventoLog {
    char timestamp_evento[TIMESTAMP_LEN];
    char mac_cliente[MAC_LEN];
    char tipo_evento[EVENT_TYPE_LEN];
    time_t timestamp_epoch;
    struct EventoLog* next;
} EventoLog;

MACNode* create_mac_node(const char* mac);
void add_mac_to_list(MACNode** head, const char* mac);
int is_mac_in_list(MACNode* head, const char* mac);
void free_mac_list(MACNode** head);
void print_mac_list(MACNode* head, const char* list_name);

void load_macs_from_file(const char* filepath, MACNode** head);
void save_macs_to_file(const char* filepath, MACNode* head);
int get_user_details_from_binauth_csv(const char* mac_to_find, char* out_nome, size_t nome_len, char* out_matricula, size_t matricula_len);
void append_event_to_csv(const char* timestamp, const char* mac, const char* nome, const char* matricula, const char* event_type);

void parse_ndsctl_line(char* line, MACNode** head);
void parse_iw_station_line(char* line, MACNode** head);
int execute_and_parse_macs_from_command(const char* command,
                                        void (*parse_line_callback)(char* line, MACNode** head),
                                        MACNode** head);

void monitor_activity_single_run();

UsuarioReportInfo* create_usuario_report_node(const char* mac, const char* nome, const char* matricula, const char* primeira_ts);
void add_usuario_report_to_list(UsuarioReportInfo** head, UsuarioReportInfo* newNode);
void free_usuario_report_list(UsuarioReportInfo** head);
void free_event_log_list(EventoLog** head);
int carregar_dados_base_usuarios_e_macs(const char* filepath, UsuarioReportInfo** users_head, MACNode** unique_macs_head);
void sort_event_log_list(EventoLog** head);
int carregar_eventos_de_sessao_por_mac(const char* events_csv_path, const char* mac_filter, EventoLog** events_head);
void calcular_uptime_e_status_para_usuario(UsuarioReportInfo* usuario, EventoLog* user_events_head, time_t now_epoch);
void escrever_relatorio_final_csv(const char* report_filepath, UsuarioReportInfo* users_head);
void executar_calculo_uptime_geral();

time_t timestamp_str_para_epoch(const char* timestamp_str);

int copiar_arquivo_csv() {
    const char *origem = "/home/victo/codigo-c/csv/eventos_sessoes_C.csv";
    const char *destino = "/home/victo/codigo-c/htdocs/eventos_sessoes_C.csv";
    FILE *src = fopen(origem, "rb");
    FILE *dst = fopen(destino, "wb");
    if (!src || !dst) {
        if (src) fclose(src);
        if (dst) fclose(dst);
        return -1;
    }

    char buffer[4096];
    size_t bytes;
    while ((bytes = fread(buffer, 1, sizeof(buffer), src)) > 0) {
        fwrite(buffer, 1, bytes, dst);
    }

    fclose(src);
    fclose(dst);
    return 0;
}

int main() {
    printf("Iniciando Servico C de Monitoramento e Relatório Nodogsplash...\n");

    char command_mkdir[256];
    snprintf(command_mkdir, sizeof(command_mkdir), "mkdir -p %s", C_PROJECT_CSV_DIR);
    if (system(command_mkdir) != 0) {
        // Silencioso
    }

    FILE* fp_touch_active_macs = fopen(EFFECTIVELY_ACTIVE_MACS_FILE_PATH, "a");
    if (fp_touch_active_macs) {
        fclose(fp_touch_active_macs);
    }

    char ts_buf[TIMESTAMP_LEN]; // Buffer declarado aqui!
    time_t t_now;

    while (1) {
        t_now = time(NULL);
        strftime(ts_buf, sizeof(ts_buf), "%Y-%m-%d %H:%M:%S", localtime(&t_now));
        printf("\n[%s] --- Iniciando ciclo de execução ---\n", ts_buf);

        monitor_activity_single_run();
        printf("------------------------------------------------------\n");

        executar_calculo_uptime_geral();
        printf("------------------------------------------------------\n");

        t_now = time(NULL);
        strftime(ts_buf, sizeof(ts_buf), "%Y-%m-%d %H:%M:%S", localtime(&t_now));
        printf("[%s] --- Ciclo de execução concluído. Aguardando 60 segundos... ---\n", ts_buf);

        copiar_arquivo_csv();
        sleep(60);
    }

    printf("Serviço C encerrado (isso não deveria acontecer normalmente).\n");
    return 0;
}


MACNode* create_mac_node(const char* mac_input) {
    MACNode* newNode = (MACNode*)malloc(sizeof(MACNode));
    if (newNode == NULL) {
        perror("Erro ao alocar memória para MACNode");
        return NULL;
    }
    int i = 0;
    for (i = 0; mac_input[i] && i < MAC_LEN - 1; i++) {
        newNode->mac[i] = tolower(mac_input[i]);
    }
    newNode->mac[i] = '\0';
    newNode->next = NULL;
    return newNode;
}

void add_mac_to_list(MACNode** head, const char* mac) {
    if (mac == NULL || mac[0] == '\0') return;
    if (is_mac_in_list(*head, mac)) {
        return;
    }
    MACNode* newNode = create_mac_node(mac);
    if (newNode == NULL) return;
    newNode->next = *head;
    *head = newNode;
}

int is_mac_in_list(MACNode* head, const char* mac_to_find) {
    if (mac_to_find == NULL) return 0;
    char mac_to_find_lower[MAC_LEN];
    int i = 0;
    for (i = 0; mac_to_find[i] && i < MAC_LEN - 1; i++) {
        mac_to_find_lower[i] = tolower(mac_to_find[i]);
    }
    mac_to_find_lower[i] = '\0';

    MACNode* current = head;
    while (current != NULL) {
        if (strcmp(current->mac, mac_to_find_lower) == 0) {
            return 1;
        }
        current = current->next;
    }
    return 0;
}

void free_mac_list(MACNode** head) {
    MACNode* current = *head;
    MACNode* next_node;
    while (current != NULL) {
        next_node = current->next;
        free(current);
        current = next_node;
    }
    *head = NULL;
}

void print_mac_list(MACNode* head, const char* list_name) {
    printf("DEBUG: Lista de MACs '%s': ", list_name);
    MACNode* current = head;
    if (current == NULL) {
        printf("[VAZIA]\n");
        return;
    }
    int count = 0;
    while (current != NULL) {
        printf("[%s] ", current->mac);
        current = current->next;
        count++;
    }
    printf("(Total: %d)\n", count);
}

void load_macs_from_file(const char* filepath, MACNode** head) {
    FILE* fp = fopen(filepath, "r");
    if (fp == NULL) {
        printf("INFO: Arquivo de MACs anteriores '%s' não encontrado ou vazio. Iniciando com lista vazia.\n", filepath);
        return;
    }
    char line[MAX_LINE_LEN];
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\r\n")] = 0;
        if (strlen(line) == (MAC_LEN -1) ) {
            add_mac_to_list(head, line);
        }
    }
    fclose(fp);
}

void save_macs_to_file(const char* filepath, MACNode* head) {
    FILE* fp = fopen(filepath, "w");
    if (fp == NULL) {
        perror("Erro ao abrir arquivo para salvar MACs");
        fprintf(stderr, "Caminho: %s\n", filepath);
        return;
    }
    MACNode* current = head;
    while (current != NULL) {
        fprintf(fp, "%s\n", current->mac);
        current = current->next;
    }
    fclose(fp);
}

char* extract_csv_field(const char* line, int field_index) {
    const char* p = line;
    char* field_value = NULL;
    int current_field = 0;
    int in_quotes = 0;
    char buffer[MAX_LINE_LEN];
    int buffer_idx = 0;

    while (*p) {
        if (*p == '"') {
            in_quotes = !in_quotes;
            if (!in_quotes && current_field == field_index) {
                buffer[buffer_idx] = '\0';
                field_value = strdup(buffer);
                return field_value;
            }
        } else if (*p == ',' && !in_quotes) {
            if (current_field == field_index) {
                buffer[buffer_idx] = '\0';
                field_value = strdup(buffer);
                return field_value;
            }
            current_field++;
            buffer_idx = 0;
        } else {
            if (in_quotes || (*p != ' ' && *p != '\t')) {
                 if (current_field == field_index && buffer_idx < MAX_LINE_LEN -1) {
                    buffer[buffer_idx++] = *p;
                }
            }
        }
        p++;
    }

    if (current_field == field_index && buffer_idx > 0) {
        buffer[buffer_idx] = '\0';
        field_value = strdup(buffer);
        return field_value;
    }
    return NULL;
}


int get_user_details_from_binauth_csv(const char* mac_to_find_input, char* out_nome, size_t nome_len, char* out_matricula, size_t matricula_len) {
    FILE* fp = fopen(BINAUTH_CSV_PATH, "r");
    if (fp == NULL) {
        fprintf(stderr, "ERRO: Não foi possível abrir %s para ler detalhes do usuário.\n", BINAUTH_CSV_PATH);
        strncpy(out_nome, "N/A_FALHA_ARQ", nome_len);
        out_nome[nome_len-1] = '\0';
        strncpy(out_matricula, "N/A_FALHA_ARQ", matricula_len);
        out_matricula[matricula_len-1] = '\0';
        return 0;
    }

    char line_buffer[MAX_LINE_LEN];
    char mac_to_find_lower[MAC_LEN];

    int k = 0;
    for (k = 0; mac_to_find_input[k] && k < MAC_LEN - 1; k++) {
        mac_to_find_lower[k] = tolower(mac_to_find_input[k]);
    }
    mac_to_find_lower[k] = '\0';

    if (fgets(line_buffer, sizeof(line_buffer), fp) == NULL) {
        fclose(fp); return 0;
    }

    int found = 0;
    while (fgets(line_buffer, sizeof(line_buffer), fp)) {
        line_buffer[strcspn(line_buffer, "\r\n")] = 0;

        char* mac_csv = extract_csv_field(line_buffer, 1);
        char* nome_csv = NULL;
        char* matricula_csv = NULL;

        if (mac_csv) {
            char mac_csv_lower[MAC_LEN];
            int l=0;
            for(l=0; mac_csv[l] && l < MAC_LEN -1; l++) mac_csv_lower[l] = tolower(mac_csv[l]);
            mac_csv_lower[l] = '\0';

            if (strcmp(mac_csv_lower, mac_to_find_lower) == 0) {
                nome_csv = extract_csv_field(line_buffer, 2);
                matricula_csv = extract_csv_field(line_buffer, 3);

                if (nome_csv) {
                    strncpy(out_nome, nome_csv, nome_len - 1);
                    out_nome[nome_len - 1] = '\0';
                    free(nome_csv);
                } else {
                    strncpy(out_nome, "N/A_NOME", nome_len);
                    out_nome[nome_len-1] = '\0';
                }
                if (matricula_csv) {
                    strncpy(out_matricula, matricula_csv, matricula_len - 1);
                    out_matricula[matricula_len - 1] = '\0';
                    free(matricula_csv);
                } else {
                     strncpy(out_matricula, "N/A_MAT", matricula_len);
                     out_matricula[matricula_len-1] = '\0';
                }
                found = 1;
                free(mac_csv);
                break;
            }
            free(mac_csv);
        }
    }
    fclose(fp);

    if (!found) {
        strncpy(out_nome, "NaoEncontrado", nome_len);
        out_nome[nome_len-1] = '\0';
        strncpy(out_matricula, "N/A", matricula_len);
        out_matricula[matricula_len-1] = '\0';
    }
    return found;
}

void append_event_to_csv(const char* timestamp, const char* mac, const char* nome, const char* matricula, const char* event_type) {
    FILE* fp = fopen(EVENTS_LOG_CSV_PATH, "a");
    if (fp == NULL) {
        perror("Erro ao abrir events_log_csv para append");
        fprintf(stderr, "Caminho: %s\n", EVENTS_LOG_CSV_PATH);
        return;
    }
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    if (size == 0) {
        fprintf(fp, "%s", HEADER_EVENTS_LOG_CSV);
    }
    fprintf(fp, "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n", timestamp, mac, nome, matricula, event_type);
    fclose(fp);
    printf("INFO: Evento [%s] para MAC [%s] logado em %s\n", event_type, mac, EVENTS_LOG_CSV_PATH);
}

int execute_and_parse_macs_from_command(const char* command,
                                        void (*parse_line_callback)(char* line, MACNode** head),
                                        MACNode** head) {
    FILE* pipe;
    char buffer[MAX_LINE_LEN];
    int initial_mac_count = 0;
    MACNode* temp_count_node = *head;
    while(temp_count_node) { initial_mac_count++; temp_count_node = temp_count_node->next; }

    pipe = popen(command, "r");
    if (!pipe) {
        perror("Falha ao executar popen");
        fprintf(stderr, "Comando que falhou: %s\n", command);
        return -1;
    }

    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        parse_line_callback(buffer, head);
    }

    int pclose_status = pclose(pipe);
    if (pclose_status == -1) {
        perror("Erro ao fechar pipe (pclose)");
    }

    int final_mac_count = 0;
    temp_count_node = *head;
    while(temp_count_node) { final_mac_count++; temp_count_node = temp_count_node->next; }

    return final_mac_count - initial_mac_count;
}

void parse_ndsctl_line(char* line, MACNode** head) {
    static char current_mac_candidate[MAC_LEN] = "";
    static int in_client_block_for_mac = 0;

    char line_copy[MAX_LINE_LEN];
    strncpy(line_copy, line, MAX_LINE_LEN -1);
    line_copy[MAX_LINE_LEN-1] = '\0';

    if (strncmp(line_copy, "Client ", strlen("Client ")) == 0) {
        in_client_block_for_mac = 1;
        current_mac_candidate[0] = '\0';
        return;
    }

    if (in_client_block_for_mac) {
        char* mac_ptr = strstr(line_copy, "MAC:");
        if (mac_ptr) {
            sscanf(mac_ptr + strlen("MAC:"), " %17[0-9a-fA-F:]", current_mac_candidate);
        }

        char* state_ptr = strstr(line_copy, "State:");
        if (state_ptr) {
            if (strstr(state_ptr + strlen("State:"), "Authenticated") && current_mac_candidate[0] != '\0') {
                add_mac_to_list(head, current_mac_candidate);
            }
            in_client_block_for_mac = 0;
            current_mac_candidate[0] = '\0';
        }
        else if (line_copy[0] != ' ' && line_copy[0] != '\t' && line_copy[0] != '\n' && line_copy[0] != '\r') {
            in_client_block_for_mac = 0;
        }
    }
}

void parse_iw_station_line(char* line, MACNode** head) {
    if (strncmp(line, "Station ", strlen("Station ")) == 0) {
        char mac_buffer[MAC_LEN];
        if (sscanf(line + strlen("Station "), "%17[0-9a-fA-F:]", mac_buffer) == 1) {
            add_mac_to_list(head, mac_buffer);
        }
    }
}

void monitor_activity_single_run() {
    char current_timestamp_str[TIMESTAMP_LEN];
    time_t now_time = time(NULL);
    strftime(current_timestamp_str, TIMESTAMP_LEN, "%Y-%m-%d %H:%M:%S", localtime(&now_time));

    printf("INFO: Executando monitor_activity_single_run em %s\n", current_timestamp_str);

    MACNode* previous_effectively_active_macs = NULL;
    MACNode* current_nds_auth_macs = NULL;
    MACNode* current_wifi_assoc_macs = NULL;
    MACNode* current_effectively_active_macs = NULL;

    load_macs_from_file(EFFECTIVELY_ACTIVE_MACS_FILE_PATH, &previous_effectively_active_macs);
    print_mac_list(previous_effectively_active_macs, "MACs Efetivamente Ativos ANTERIORES");

    execute_and_parse_macs_from_command("sudo ndsctl status", parse_ndsctl_line, &current_nds_auth_macs);
    print_mac_list(current_nds_auth_macs, "MACs Autenticados NDS (Atuais)");

    execute_and_parse_macs_from_command("sudo iw dev wlan0 station dump", parse_iw_station_line, &current_wifi_assoc_macs);
    print_mac_list(current_wifi_assoc_macs, "MACs Associados WiFi (Atuais)");

    MACNode* nds_node = current_nds_auth_macs;
    while (nds_node != NULL) {
        if (is_mac_in_list(current_wifi_assoc_macs, nds_node->mac)) {
            add_mac_to_list(&current_effectively_active_macs, nds_node->mac);
        }
        nds_node = nds_node->next;
    }
    print_mac_list(current_effectively_active_macs, "MACs Efetivamente Ativos ATUAIS (NDS+WiFi)");

    MACNode* current_node = current_effectively_active_macs;
    while (current_node != NULL) {
        if (!is_mac_in_list(previous_effectively_active_macs, current_node->mac)) {
            char nome[NAME_LEN] = "N/A";
            char matricula[MATRICULA_LEN] = "N/A";
            get_user_details_from_binauth_csv(current_node->mac, nome, sizeof(nome), matricula, sizeof(matricula));
            append_event_to_csv(current_timestamp_str, current_node->mac, nome, matricula, "CONECTADO");
        }
        current_node = current_node->next;
    }

    MACNode* previous_node = previous_effectively_active_macs;
    while (previous_node != NULL) {
        if (!is_mac_in_list(current_effectively_active_macs, previous_node->mac)) {
            char nome[NAME_LEN] = "N/A";
            char matricula[MATRICULA_LEN] = "N/A";
            get_user_details_from_binauth_csv(previous_node->mac, nome, sizeof(nome), matricula, sizeof(matricula));
            append_event_to_csv(current_timestamp_str, previous_node->mac, nome, matricula, "DESCONECTADO");
        }
        previous_node = previous_node->next;
    }

    save_macs_to_file(EFFECTIVELY_ACTIVE_MACS_FILE_PATH, current_effectively_active_macs);

    free_mac_list(&previous_effectively_active_macs);
    free_mac_list(&current_nds_auth_macs);
    free_mac_list(&current_wifi_assoc_macs);
    free_mac_list(&current_effectively_active_macs);
}

time_t timestamp_str_para_epoch(const char* timestamp_str) {
    struct tm tms = {0};
    if (timestamp_str == NULL) return (time_t)-1;

    if (sscanf(timestamp_str, "%d-%d-%d %d:%d:%d",
               &tms.tm_year, &tms.tm_mon, &tms.tm_mday,
               &tms.tm_hour, &tms.tm_min, &tms.tm_sec) == 6) {
        tms.tm_year -= 1900;
        tms.tm_mon -= 1;
        tms.tm_isdst = -1;
        return mktime(&tms);
    }
    return (time_t)-1;
}

UsuarioReportInfo* create_usuario_report_node(const char* mac, const char* nome, const char* matricula, const char* primeira_ts) {
    UsuarioReportInfo* newNode = (UsuarioReportInfo*)malloc(sizeof(UsuarioReportInfo));
    if (!newNode) {
        perror("Erro ao alocar UsuarioReportInfo");
        return NULL;
    }
    strncpy(newNode->mac_cliente, mac, MAC_LEN - 1); newNode->mac_cliente[MAC_LEN - 1] = '\0';
    strncpy(newNode->nome_usuario, nome, NAME_LEN - 1); newNode->nome_usuario[NAME_LEN - 1] = '\0';
    strncpy(newNode->matricula, matricula, MATRICULA_LEN - 1); newNode->matricula[MATRICULA_LEN - 1] = '\0';
    strncpy(newNode->primeira_conexao_ts, primeira_ts, TIMESTAMP_LEN - 1); newNode->primeira_conexao_ts[TIMESTAMP_LEN - 1] = '\0';

    strcpy(newNode->ultimo_evento_ts, primeira_ts);
    strcpy(newNode->status_atual, "Inativo");
    newNode->total_uptime_segundos = 0;
    newNode->numero_sessoes = 0;
    newNode->sessao_ativa_start_epoch = 0;
    newNode->next = NULL;
    return newNode;
}

void add_usuario_report_to_list(UsuarioReportInfo** head, UsuarioReportInfo* newNode) {
    if (!newNode) return;
    newNode->next = *head;
    *head = newNode;
}

void free_usuario_report_list(UsuarioReportInfo** head) {
    UsuarioReportInfo* current = *head;
    UsuarioReportInfo* next_node;
    while (current != NULL) {
        next_node = current->next;
        free(current);
        current = next_node;
    }
    *head = NULL;
}

EventoLog* create_event_log_node(const char* ts, const char* mac, const char* tipo) {
    EventoLog* newNode = (EventoLog*)malloc(sizeof(EventoLog));
    if(!newNode) {
        perror("Falha ao alocar EventoLog node");
        return NULL;
    }
    strncpy(newNode->timestamp_evento, ts, TIMESTAMP_LEN -1); newNode->timestamp_evento[TIMESTAMP_LEN-1] = '\0';
    strncpy(newNode->mac_cliente, mac, MAC_LEN -1); newNode->mac_cliente[MAC_LEN-1] = '\0';
    strncpy(newNode->tipo_evento, tipo, EVENT_TYPE_LEN-1); newNode->tipo_evento[EVENT_TYPE_LEN-1] = '\0';
    newNode->timestamp_epoch = timestamp_str_para_epoch(ts);
    newNode->next = NULL;
    return newNode;
}

void add_event_to_list_sorted(EventoLog** head, EventoLog* newEvent) {
    if (newEvent == NULL || newEvent->timestamp_epoch == (time_t)-1) {
        if(newEvent) free(newEvent);
        return;
    }
    EventoLog* current;
    if (*head == NULL || (*head)->timestamp_epoch >= newEvent->timestamp_epoch) {
        newEvent->next = *head;
        *head = newEvent;
    } else {
        current = *head;
        while (current->next != NULL && current->next->timestamp_epoch < newEvent->timestamp_epoch) {
            current = current->next;
        }
        newEvent->next = current->next;
        current->next = newEvent;
    }
}


void free_event_log_list(EventoLog** head) {
    EventoLog* current = *head;
    EventoLog* next_node;
    while (current != NULL) {
        next_node = current->next;
        free(current);
        current = next_node;
    }
    *head = NULL;
}

int carregar_dados_base_usuarios_e_macs(const char* filepath, UsuarioReportInfo** users_head, MACNode** unique_macs_head) {
    FILE* fp = fopen(filepath, "r");
    if (!fp) {
        fprintf(stderr, "ERRO: Não foi possível abrir %s para ler dados base dos usuários.\n", filepath);
        return 0;
    }

    char line_buffer[MAX_LINE_LEN];
    if (!fgets(line_buffer, sizeof(line_buffer), fp)) { fclose(fp); return 0; }

    int count = 0;
    while (fgets(line_buffer, sizeof(line_buffer), fp)) {
        line_buffer[strcspn(line_buffer, "\r\n")] = 0;
        char* ts_csv = extract_csv_field(line_buffer, 0);
        char* mac_csv = extract_csv_field(line_buffer, 1);
        char* nome_csv = extract_csv_field(line_buffer, 2);
        char* matricula_csv = extract_csv_field(line_buffer, 3);

        if (mac_csv && nome_csv && matricula_csv && ts_csv) {
            char mac_norm[MAC_LEN];
            int k=0;
            for(k=0; mac_csv[k] && k < MAC_LEN -1; k++) mac_norm[k] = tolower(mac_csv[k]);
            mac_norm[k] = '\0';

            if (!is_mac_in_list(*unique_macs_head, mac_norm)) {
                add_mac_to_list(unique_macs_head, mac_norm);
                UsuarioReportInfo* newUser = create_usuario_report_node(mac_norm, nome_csv, matricula_csv, ts_csv);
                if (newUser) {
                    add_usuario_report_to_list(users_head, newUser);
                    count++;
                }
            }
        }
        free(ts_csv); free(mac_csv); free(nome_csv); free(matricula_csv);
    }
    fclose(fp);
    return count;
}

int carregar_eventos_de_sessao_por_mac(const char* events_csv_path, const char* mac_filter_input, EventoLog** events_head) {
    FILE* fp_events = fopen(events_csv_path, "r");
    if (!fp_events) {
        fprintf(stderr, "ERRO: Não foi possível abrir %s para ler eventos de sessão.\n", events_csv_path);
        return 0;
    }

    char line_buffer[MAX_LINE_LEN];
    if (!fgets(line_buffer, sizeof(line_buffer), fp_events)) { fclose(fp_events); return 0; }

    char mac_filter_lower[MAC_LEN];
    int k=0;
    for(k=0; mac_filter_input[k] && k < MAC_LEN-1; k++) mac_filter_lower[k] = tolower(mac_filter_input[k]);
    mac_filter_lower[k] = '\0';

    int count = 0;
    *events_head = NULL;

    while (fgets(line_buffer, sizeof(line_buffer), fp_events)) {
        line_buffer[strcspn(line_buffer, "\r\n")] = 0;
        char* ts_evento_csv = extract_csv_field(line_buffer, 0);
        char* mac_csv = extract_csv_field(line_buffer, 1);
        char* tipo_evento_csv = extract_csv_field(line_buffer, 4);

        if (ts_evento_csv && mac_csv && tipo_evento_csv) {
            char current_mac_csv_lower[MAC_LEN];
            int j=0;
            for(j=0; mac_csv[j] && j < MAC_LEN-1; j++) current_mac_csv_lower[j] = tolower(mac_csv[j]);
            current_mac_csv_lower[j] = '\0';

            if (strcmp(current_mac_csv_lower, mac_filter_lower) == 0) {
                EventoLog* newEvent = create_event_log_node(ts_evento_csv, current_mac_csv_lower, tipo_evento_csv);
                if(newEvent && newEvent->timestamp_epoch != (time_t)-1) {
                    add_event_to_list_sorted(events_head, newEvent);
                    count++;
                } else if (newEvent) {
                    free(newEvent);
                }
            }
        }
        free(ts_evento_csv); free(mac_csv); free(tipo_evento_csv);
    }
    fclose(fp_events);
    return count;
}


void calcular_uptime_e_status_para_usuario(UsuarioReportInfo* usuario, EventoLog* user_events_head, time_t now_epoch) {
    if (!usuario ) return;

    usuario->total_uptime_segundos = 0;
    usuario->numero_sessoes = 0;
    usuario->sessao_ativa_start_epoch = 0;
    strcpy(usuario->status_atual, "Inativo");
    if (user_events_head == NULL) {
         strcpy(usuario->ultimo_evento_ts, usuario->primeira_conexao_ts);
         return;
    }


    EventoLog* current_event = user_events_head;
    while (current_event != NULL) {
        strcpy(usuario->ultimo_evento_ts, current_event->timestamp_evento);

        if (strcmp(current_event->tipo_evento, "CONECTADO") == 0) {
            if (usuario->sessao_ativa_start_epoch > 0 && current_event->timestamp_epoch > usuario->sessao_ativa_start_epoch) {
                long duracao_anomala = current_event->timestamp_epoch - usuario->sessao_ativa_start_epoch;
                usuario->total_uptime_segundos += duracao_anomala;
            }
            usuario->sessao_ativa_start_epoch = current_event->timestamp_epoch;
            strcpy(usuario->status_atual, "Ativo");
            usuario->numero_sessoes++;
        } else if (strcmp(current_event->tipo_evento, "DESCONECTADO") == 0) {
            if (usuario->sessao_ativa_start_epoch > 0 && current_event->timestamp_epoch >= usuario->sessao_ativa_start_epoch) {
                long duracao_desta_sessao = current_event->timestamp_epoch - usuario->sessao_ativa_start_epoch;
                usuario->total_uptime_segundos += duracao_desta_sessao;
                usuario->sessao_ativa_start_epoch = 0;
            }
            strcpy(usuario->status_atual, "Inativo");
        }
        current_event = current_event->next;
    }

    if (usuario->sessao_ativa_start_epoch > 0) {
        long duracao_sessao_aberta = now_epoch - usuario->sessao_ativa_start_epoch;
        if (duracao_sessao_aberta > 0) {
            usuario->total_uptime_segundos += duracao_sessao_aberta;
        }
        strcpy(usuario->status_atual, "Ativo");
    }

    if (usuario->total_uptime_segundos > 0 && usuario->numero_sessoes == 0 && strcmp(usuario->status_atual, "Ativo")==0 ) {
        usuario->numero_sessoes = 1;
    }
}

void escrever_relatorio_final_csv(const char* report_filepath, UsuarioReportInfo* users_head) {
    FILE* fp = fopen(report_filepath, "w");
    if (!fp) {
        perror("Erro ao abrir arquivo de relatório para escrita");
        fprintf(stderr, "Caminho: %s\n", report_filepath);
        return;
    }
    printf("INFO: Escrevendo relatório final em %s\n", report_filepath);
    fprintf(fp, "%s", HEADER_UPTIME_REPORT_CSV);

    UsuarioReportInfo* current_user = users_head;
    while (current_user != NULL) {
        fprintf(fp, "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",%ld,%d\n",
                current_user->mac_cliente,
                current_user->nome_usuario,
                current_user->matricula,
                current_user->primeira_conexao_ts,
                current_user->ultimo_evento_ts,
                current_user->status_atual,
                current_user->total_uptime_segundos,
                current_user->numero_sessoes);
        current_user = current_user->next;
    }
    fclose(fp);
}

void executar_calculo_uptime_geral() {
    printf("INFO: Iniciando executar_calculo_uptime_geral...\n");
    UsuarioReportInfo* lista_usuarios_report = NULL;
    MACNode* lista_macs_unicos = NULL;
    time_t agora_epoch = time(NULL);

    if (carregar_dados_base_usuarios_e_macs(BINAUTH_CSV_PATH, &lista_usuarios_report, &lista_macs_unicos) == 0) {
        fprintf(stderr, "AVISO: Nenhum dado base de usuário carregado. O relatório pode estar vazio ou incompleto.\n");
    }
    print_mac_list(lista_macs_unicos, "MACs Únicos para Relatório");

    UsuarioReportInfo* current_user_for_processing = lista_usuarios_report;
    while(current_user_for_processing != NULL) {
        printf("INFO: Processando eventos para MAC: %s (Nome: %s)\n",
            current_user_for_processing->mac_cliente, current_user_for_processing->nome_usuario);
        EventoLog* eventos_deste_usuario_head = NULL;

        carregar_eventos_de_sessao_por_mac(EVENTS_LOG_CSV_PATH, current_user_for_processing->mac_cliente, &eventos_deste_usuario_head);

        if (eventos_deste_usuario_head != NULL) {
             calcular_uptime_e_status_para_usuario(current_user_for_processing, eventos_deste_usuario_head, agora_epoch);
        } else {
            printf("INFO: Nenhum evento de sessão encontrado para MAC: %s. Status permanecerá Inativo.\n", current_user_for_processing->mac_cliente);
        }

        free_event_log_list(&eventos_deste_usuario_head);
        current_user_for_processing = current_user_for_processing->next;
    }

    escrever_relatorio_final_csv(UPTIME_REPORT_CSV_PATH, lista_usuarios_report);

    free_usuario_report_list(&lista_usuarios_report);
    free_mac_list(&lista_macs_unicos);
    printf("INFO: executar_calculo_uptime_geral concluído.\n");
}