# Lista de Materiais

1. Leds RGB (4 unidade)
2. Jumpers Macho-Fêmea (13 unidades)
3. Jumpers Macho-Macho (4 unidades)
4. Resistor de 300 Ω (12 unidade)

## Montagem:

1. Conecte o pino GPIO 2 do Raspberry Pi à protoboard.

2. Na mesma linha da protoboard onde o GPIO 2 foi inserido, conecte uma ponta de um resistor de 300 Ω. A outra ponta do resistor deve ir para uma seção diferente da protoboard, que será conectada à entrada verde do LED 1.

3. Conecte o pino GPIO 3 do Raspberry Pi à protoboard. Na mesma linha da protoboard onde o GPIO 3 foi inserido, conecte uma ponta de um resistor de 300 Ω. A outra ponta do resistor deve ir para uma seção diferente da protoboard, que será conectada à entrada vermelha do LED 1.

4. Conecte o pino GPIO 4 do Raspberry Pi à protoboard. Na mesma linha da protoboard onde o GPIO 4 foi inserido, conecte uma ponta de um resistor de 300 Ω. A outra ponta do resistor deve ir para uma seção diferente da 
protoboard, que será conectada à entrada azul do LED 1.

5. Ligue o pino GND (Terra) do Raspberry Pi a uma das barras laterais de alimentação da protoboard.

6. Conecte um fio jumper macho-macho da barra lateral de GND da protoboard (onde você conectou o GND do Raspberry Pi) à entrada negativa (comum) do LED 1.

### Repita os passos 1 a 4 para os LEDs restantes, utilizando os pinos GPIO e as cores correspondentes, e o passo 6 para conectar o GND de cada LED à barra lateral da protoboard.

LED 2:

* GPIO 27 para a entrada verde
* GPIO 22 para a entrada vermelha
* GPIO 17 para a entrada azul

LED 3:

* GPIO 9 para a entrada verde
* GPIO 11 para a entrada vermelha
* GPIO 10 para a entrada azul

LED 4:

* GPIO 5 para a entrada verde
* GPIO 6 para a entrada vermelha
* GPIO 26 para a entrada azul

## Portas GPIO

Para referência detalhada dos pinos GPIO do Raspberry Pi, você pode consultar o seguinte link:

[RaspGPIO](https://pinout.xyz/pinout/5v_power)