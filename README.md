# ECOP11A_Rasp-Attend
Criação de um sistema de controle de presença baseado no tempo de conexão a um Access Point (AP) interno.


## Requisitos:

- Raspberry Pi 3 B+ (Pode ser compativel com outras raspberry, porém só ocorreu o desenvolvimento e os testes foram realizados neste modelo)
- Cabo RJ45 - Conexão de rede cabeada para o raspberry
- Fonte 5v 2A (10W) - Alimentação do Raspberry

## Instalação da solução:

**Avisos**
Para que o acesso via ssh se mantenha após a instalação base, é obrigatório que o acesso seja via cabo (eth0), pois, uma vez instalado, o hotspot é ligado automaticamente após o reboot

1. Atualização do sistema

Antes de iniciar a instalação, recomenda-se fortemente a atualização de todos os pacotes e serviços do Raspberry, para isso, execute os seguintes comandos:

*Tenha cuidado ao atualizar o serviço ssh, pois pode acarretar na perda do acesso.

```bash

sudo apt-get update && sudo apt-get full-upgrade

sudo reboot

```

2. Clonagem do repositório

Para a realização da instalação, será necessário a clonagem deste repositório, recomenda-se que seja clonado na pasta home de seu usuário, mas, poderá ser realizado em qualquer outro local. Para a realização, execute o seguinte comando:

```bash

git clone https://github.com/Victor-Augusto-2025016677/ECOP11A_Rasp-Attend.git

cd ./ECOP11A_Rasp-Attend

```

3. Instalação Inicial - Configurações Padrão (Obrigatório)

Nesta seção, iremos realizar a instalação manipulada o RaspAP (responsável pelo Acess Point), e do Nodogsplash (Responsável pela Página de login)

Para realizar a instalação, execute seu terminal dentro deste repositório, e após, execute:

```bash

sudo ./install_base.sh

```

Este comando executa a instalação personalizada do RaspAP, a instalação do Nodogsplash e suas dependências e a atualização da configuração do nodogsplash

Após a conclusão, o sistema irá se comportar com as definições padrão do RaspAP, junto ao captive portal padrão, para mais informações, consulte:

[RaspAP](https://raspap.com/)
[Captive_Portal](https://docs.raspap.com/captive/#starting-the-captive-portal)

*Infelizmente a documentação oficial do "Nodogsplash" se encontra indisponivel, para a realização de consultas parciais, recomendo o uso de Modelos LLM treinados antes de sua indisponibilidade (GPT, Gemini, Claude e etc)

4. Aplicação da personalização central

Este comando, irá realizar toda a instalação da personalização realizada por mim, ela consiste em página de login com recolhimento de nome e número de matrícula, scripts e services para a hospedagem local http, e a solução em Ansi C para a manipulação de csv's e outras implicações para o funcionamento do código. 

### **Em andamento**