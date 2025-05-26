document.addEventListener('DOMContentLoaded', function () {
    // Referências removidas: loginSection, senhaInput, botaoLogin, erroLoginDiv
    const contentSection = document.getElementById('contentSection');
    const dataTableContainer = document.getElementById('dataTableContainer');
    const lastUpdatedP = document.getElementById('lastUpdated');

    const CSV_URL = './relatorio_usuarios_C.csv';
    const EVENTS_CSV_URL = './eventos_sessoes_C.csv';
    let eventsByMac = {};
    const UPDATE_INTERVAL = 65000; // 65 segundos
    let updateTimerId = null;

    let configAulas = {
        duracaoAulaMin: 55,
        quantidadeAulas: 2,
        percentualMinimoAprovacao: 75
    };

    function loadAulaConfigs() {
        const savedConfigs = localStorage.getItem('configAulasPresenca');
        const defaults = {
            duracaoAulaMin: 55,
            quantidadeAulas: 2,
            percentualMinimoAprovacao: 75
        };
        if (savedConfigs) {
            try {
                const parsed = JSON.parse(savedConfigs);
                configAulas = { ...defaults, ...parsed };

                if (typeof configAulas.duracaoAulaMin !== 'number' ||
                    typeof configAulas.quantidadeAulas !== 'number' ||
                    typeof configAulas.percentualMinimoAprovacao !== 'number') {
                    console.warn("Configurações carregadas do localStorage com tipos inválidos. Redefinindo para padrão.");
                    configAulas = { ...defaults };
                }
            } catch (e) {
                console.error("Erro ao analisar configurações do localStorage. Usando padrões.", e);
                configAulas = { ...defaults };
            }
        } else {
            configAulas = { ...defaults };
        }
        localStorage.setItem('configAulasPresenca', JSON.stringify(configAulas));
    }

    function saveAulaConfigs(duracao, quantidade, percentualMinimo) {
        configAulas.duracaoAulaMin = parseInt(duracao, 10);
        configAulas.quantidadeAulas = parseInt(quantidade, 10);
        configAulas.percentualMinimoAprovacao = parseInt(percentualMinimo, 10);
        localStorage.setItem('configAulasPresenca', JSON.stringify(configAulas));
        loadAndDisplayData();
    }

    const settingsGearIcon = document.getElementById('settingsGear');
    const settingsModalElement = document.getElementById('settingsModal');
    const closeSettingsModalButton = document.getElementById('closeSettingsModal');
    const settingsFormElement = document.getElementById('settingsForm');
    const aulaDuracaoInputElement = document.getElementById('aulaDuracao');
    const quantidadeAulasInputElement = document.getElementById('quantidadeAulas');
    const percentualMinimoInputElement = document.getElementById('percentualMinimo');

    if (settingsGearIcon) {
        settingsGearIcon.onclick = function() {
            loadAulaConfigs();
            aulaDuracaoInputElement.value = configAulas.duracaoAulaMin;
            quantidadeAulasInputElement.value = configAulas.quantidadeAulas;
            percentualMinimoInputElement.value = configAulas.percentualMinimoAprovacao;
            settingsModalElement.style.display = "block";
        }
    }
    if (closeSettingsModalButton) {
        closeSettingsModalButton.onclick = function() {
            settingsModalElement.style.display = "none";
        }
    }
    if (settingsFormElement) {
        settingsFormElement.onsubmit = function(event) {
            event.preventDefault();
            const duracao = aulaDuracaoInputElement.value;
            const quantidade = quantidadeAulasInputElement.value;
            const percentualMinimo = percentualMinimoInputElement.value;

            if (!duracao || !quantidade || !percentualMinimo ||
                parseInt(duracao,10) < 1 ||
                parseInt(quantidade,10) < 1 || parseInt(quantidade,10) > 8 ||
                parseInt(percentualMinimo,10) < 0 || parseInt(percentualMinimo,10) > 100 ) {
                alert("Por favor, insira valores válidos (Duração > 0, Quantidade 1-8, Percentual Mínimo 0-100).");
                return;
            }
            saveAulaConfigs(duracao, quantidade, percentualMinimo);
            settingsModalElement.style.display = "none";
            alert("Configurações salvas! A tabela foi atualizada.");
        }
    }
    window.onclick = function(event) {
        if (event.target == settingsModalElement) {
            settingsModalElement.style.display = "none";
        }
    }

    // Carrega configurações iniciais
    loadAulaConfigs();

    // Lógica de login removida

    function parseCSV(csvText) {
        const lines = csvText.trim().split('\n');
        if (lines.length === 0 || (lines.length === 1 && lines[0].trim() === "")) {
            return { headers: [], data: [] };
        }
        const parseCsvLine = (lineString) => {
            return lineString.split(/,(?=(?:(?:[^"]*"){2})*[^"]*$)/)
                             .map(field => field.trim().replace(/^"|"$/g, ''));
        };
        const headers = parseCsvLine(lines[0]);
        const data = [];
        for (let i = 1; i < lines.length; i++) {
            let line = lines[i].trim();
            if (line === "") continue;
            if (line.endsWith(';')) { line = line.slice(0, -1); }
            const values = parseCsvLine(line);
            if (values.length === headers.length) {
                const rowObject = {};
                headers.forEach((header, index) => {
                    const val = values[index];
                    if (header === "Total_Uptime_Segundos" || header === "Numero_De_Sessoes") {
                        rowObject[header] = parseInt(val, 10);
                    } else {
                        rowObject[header] = val;
                    }
                });
                data.push(rowObject);
            } else {
                console.warn(`Pulando linha CSV ${i+1} (dados). Colunas: ${values.length}, Esperado: ${headers.length}. Linha: "${lines[i]}"`);
            }
        }
        return { headers, data };
    }

    async function loadAndDisplayData() {
        dataTableContainer.innerHTML = '<p class="loading-message">Atualizando dados...</p>';
        try {
            const [mainResponse, eventsResponse] = await Promise.all([
                fetch(CSV_URL + '?t=' + new Date().getTime()),
                fetch(EVENTS_CSV_URL + '?t=' + new Date().getTime())
            ]);
            if (!mainResponse.ok) throw new Error(`CSV Principal: ${mainResponse.statusText}`);
            if (!eventsResponse.ok) throw new Error(`CSV Eventos: ${eventsResponse.statusText}`);
            const mainCsvText = await mainResponse.text();
            const eventsCsvText = await eventsResponse.text();
            const mainParsed = parseCSV(mainCsvText);
            const eventsParsed = parseCSV(eventsCsvText);
            eventsByMac = {};
            if (eventsParsed.data && eventsParsed.data.length > 0) {
                eventsParsed.data.forEach(event => {
                    const mac = event.MAC_Cliente;
                    if (!mac) return;
                    if (!eventsByMac[mac]) { eventsByMac[mac] = []; }
                    eventsByMac[mac].push(event);
                });
                for (const mac in eventsByMac) {
                    eventsByMac[mac].sort((a, b) => new Date(a.Timestamp_Evento) - new Date(b.Timestamp_Evento));
                }
            }
            if (mainParsed.headers.length > 0) {
                renderTable(mainParsed.headers, mainParsed.data);
            } else if (mainCsvText.trim() !== "" && mainParsed.data.length === 0) {
                dataTableContainer.innerHTML = '<p class="error-loading-message">Formato CSV principal não reconhecido.</p>';
            } else {
                dataTableContainer.innerHTML = '<p class="loading-message">CSV principal vazio.</p>';
            }
            lastUpdatedP.textContent = `Última atualização: ${new Date().toLocaleTimeString()}`;
        } catch (error) {
            console.error('Falha ao carregar CSVs:', error);
            dataTableContainer.innerHTML = `<p class="error-loading-message">Falha ao carregar. (${error.message})</p>`;
            lastUpdatedP.textContent = `Falha na atualização: ${new Date().toLocaleTimeString()}`;
        }
    }

    function renderTable(headers, data) {
        dataTableContainer.innerHTML = '';
        const table = document.createElement('table');
        const thead = document.createElement('thead');
        const tbody = document.createElement('tbody');
        const headerRow = document.createElement('tr');

        const expanderHeader = document.createElement('th');
        expanderHeader.className = 'expander-column-header';
        headerRow.appendChild(expanderHeader);

        headers.forEach(originalHeaderText => {
            const th = document.createElement('th');
            let displayHeaderText = originalHeaderText.replace(/_/g, ' ');
            if (originalHeaderText === "Total_Uptime_Segundos") {
                displayHeaderText = "Uptime"; // Alterado
            }
            th.textContent = displayHeaderText;
            th.classList.add('col-' + originalHeaderText.toLowerCase().replace(/[^a-z0-9]/g, '_'));
            headerRow.appendChild(th);
        });

        const presencaHeaderTh = document.createElement('th');
        presencaHeaderTh.textContent = "% Presença"; // Alterado
        presencaHeaderTh.style.textAlign = "center";
        presencaHeaderTh.classList.add('col-percentual-presenca');
        headerRow.appendChild(presencaHeaderTh);

        thead.appendChild(headerRow);
        table.appendChild(thead);

        const totalTableColumns = headers.length + 2;

        if (data.length === 0) {
            dataTableContainer.appendChild(table);
            const noDataMessage = document.createElement('p');
            noDataMessage.className = 'loading-message';
            noDataMessage.textContent = 'Nenhum dado para exibir.';
            dataTableContainer.appendChild(noDataMessage);
            return;
        }

        data.forEach(rowData => {
            const tr = document.createElement('tr');
            if (rowData.MAC_Cliente) { tr.dataset.mac = rowData.MAC_Cliente; }

            const expanderCell = document.createElement('td');
            expanderCell.className = 'expander-cell';
            const expanderButton = document.createElement('span');
            expanderButton.textContent = '▼';
            expanderButton.className = 'expander-arrow';
            expanderButton.title = "Ver histórico";
            expanderButton.onclick = function() {
                toggleDetails(tr, rowData.MAC_Cliente, totalTableColumns);
            };
            expanderCell.appendChild(expanderButton);
            tr.appendChild(expanderCell);

            headers.forEach(header => {
                const td = document.createElement('td');
                let currentClasses = 'col-' + header.toLowerCase().replace(/[^a-z0-9]/g, '_');
                let cellValue = rowData[header];

                if (header === "Total_Uptime_Segundos") {
                    const totalSeconds = parseInt(cellValue, 10) || 0;
                    const hours = Math.floor(totalSeconds / 3600);
                    const minutes = Math.floor((totalSeconds % 3600) / 60);
                    const seconds = totalSeconds % 60;
                    cellValue = `${String(hours).padStart(2,'0')}:${String(minutes).padStart(2,'0')}:${String(seconds).padStart(2,'0')}`;
                }
                td.textContent = cellValue !== undefined ? cellValue : '';

                if (header === "Status_Atual_Inferido") {
                    if (cellValue && String(cellValue).toLowerCase() === 'ativo') { currentClasses += ' status-ativo'; }
                    else if (cellValue && String(cellValue).toLowerCase() === 'inativo') { currentClasses += ' status-inativo'; }
                }
                td.className = currentClasses;
                tr.appendChild(td);
            });

            const presencaCell = document.createElement('td');
            presencaCell.classList.add('col-percentual-presenca');
            const uptimeEmSegundos = parseInt(rowData.Total_Uptime_Segundos, 10) || 0;
            const uptimeEmMinutos = uptimeEmSegundos / 60;

            const tempoDeAulaConfiguradoMin = configAulas.duracaoAulaMin;
            const numeroDeAulasConfigurado = configAulas.quantidadeAulas;
            const percentualMinimoAprovacaoConfigurado = configAulas.percentualMinimoAprovacao;

            const tempoTotalAulasMin = numeroDeAulasConfigurado * tempoDeAulaConfiguradoMin;
            let percentualPresenca = 0;
            if (tempoTotalAulasMin > 0) {
                percentualPresenca = (uptimeEmMinutos / tempoTotalAulasMin) * 100;
            }
            percentualPresenca = Math.max(0, Math.min(percentualPresenca, 100));
            presencaCell.textContent = `${percentualPresenca.toFixed(1)}%`;
            presencaCell.style.textAlign = 'center';

            if (percentualPresenca >= percentualMinimoAprovacaoConfigurado) {
                presencaCell.style.color = '#c8e6c9';
                presencaCell.style.fontWeight = 'bold';
            } else {
                presencaCell.style.color = '#ffccbc';
            }
            tr.appendChild(presencaCell);
            tbody.appendChild(tr);
        });
        table.appendChild(tbody);
        dataTableContainer.appendChild(table);
    }

    function toggleDetails(rowElement, macAddress, colspanValue) {
        const nextRow = rowElement.nextElementSibling;
        const arrow = rowElement.querySelector('.expander-arrow');
        if (nextRow && nextRow.classList.contains('details-row')) {
            nextRow.remove();
            if (arrow) arrow.textContent = '▼';
            rowElement.classList.remove('expanded');
        } else {
            const detailsRow = document.createElement('tr');
            detailsRow.className = 'details-row';
            const detailsCell = document.createElement('td');
            detailsCell.colSpan = colspanValue;
            const userEvents = eventsByMac[macAddress] || [];
            let detailsContent = '<div class="details-content-wrapper">';
            if (userEvents.length > 0) {
                detailsContent += '<strong>Histórico de Eventos:</strong><ul>';
                userEvents.forEach(event => {
                    detailsContent += `<li><strong>${event.Timestamp_Evento}</strong> - ${event.Tipo_Evento}</li>`;
                });
                detailsContent += '</ul>';
            } else {
                detailsContent += '<p>Nenhum histórico de eventos encontrado para este MAC.</p>';
            }
            detailsContent += '</div>';
            detailsCell.innerHTML = detailsContent;
            detailsRow.appendChild(detailsCell);
            rowElement.parentNode.insertBefore(detailsRow, rowElement.nextSibling);
            if (arrow) arrow.textContent = '▲';
            rowElement.classList.add('expanded');
        }
    }

    // --- CARREGA OS DADOS E INICIA A ATUALIZAÇÃO AUTOMÁTICA ---
    loadAndDisplayData(); // Carrega os dados na primeira vez
    if (updateTimerId) clearInterval(updateTimerId); // Limpa timer antigo se houver
    updateTimerId = setInterval(loadAndDisplayData, UPDATE_INTERVAL); // Inicia atualização periódica

});