# Configuração AP

## Inicialização AP

Para inicializar o AP, utilizei o seguinte comando:

```bash

sudo nmcli device wifi hotspot ssid freq password 12345678

```

Com isso, obtive sucesso na criação do AP, e pude acessar através de meu dispositivo móvel. Utilizando o comando " iw dev wlan0 station dump ", pude obter os dados dos dispositivos conectados, e a saída foi:

```
victo@rasp3:~ $ iw dev wlan0 station dump
Station 52:94:fd:3f:a6:3e (on wlan0)
        inactive time:  1000 ms
        rx bytes:       6074
        rx packets:     52
        tx bytes:       26158
        tx packets:     174
        tx failed:      5
        tx bitrate:     65.0 MBit/s
        rx bitrate:     1.0 MBit/s
        authorized:     yes
        authenticated:  yes
        associated:     yes
        WMM/WME:        yes
        TDLS peer:      no
        DTIM period:    2
        beacon interval:100
        short slot time:yes
        connected time: 30 seconds
        current time:   1747777024952 ms
```

Onde, pude obter o MAC adress do dispositivo, e mais alguns outros parâmetros da conexão, como o bitrate disponível da conexão, a quantidade de pacotes e bytes enviados & recebidos, além do tempo de conexão do dispositivo. 

-------------------------------------------------


