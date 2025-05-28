# Lista de Materiais

1. Transistor TIP120 (1 unidade)
2. Jumpers Macho-Fêmea (2 unidades)
3. Resistor de 1 kΩ (1 unidade)
4. Ventoinha 5V (1 unidade)

## Montagem:

1. Conecte o pino GPIO 16 do Raspberry Pi à protoboard.
2. Insira uma das pontas do resistor na mesma linha do pino GPIO 16 na protoboard. Conecte a outra ponta do resistor em uma seção diferente da protoboard, na mesma linha onde a base do transistor (pino da esquerda) será conectada.
3. Ligue o pino GND (Terra) do Raspberry Pi ao emissor do transistor (pino da direita).
4. Conecte o terminal negativo da ventoinha ao coletor do transistor (pino central).
5. Conecte o terminal positivo da ventoinha a uma porta de 5V do Raspberry Pi.

## Portas GPIO

Para referência detalhada dos pinos GPIO do Raspberry Pi, você pode consultar o seguinte link:

[RaspGPIO](https://pinout.xyz/pinout/5v_power)