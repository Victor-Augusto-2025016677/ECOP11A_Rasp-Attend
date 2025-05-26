#!/bin/bash

# Script para a instalação do pinctrl

REPO_ROOT=$(pwd)

sudo cd ./pinctrl_lib/pinctrl
sudo cmake .
sudo make
sudo make install
echo ">>> Pinctrl instalado."

cd "$REPO_ROOT"