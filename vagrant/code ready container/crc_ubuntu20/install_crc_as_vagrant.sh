#!/bin/bash
set -e

# CRC config et start
crc config set pull-secret-file /home/vagrant/pull-secret.txt
crc config set consent-telemetry yes
crc config set skip-check-root-user true
crc setup
crc start

# dns entry in hosts file
# 127.0.0.1	api.crc.testing oauth-openshift.apps-crc.testing console-openshift-console.apps-crc.testing

# Deploy webapp
# oc new-project webapp
# oc new-app -S nginx
# oc process openshift//nginx-example --parameters
# oc new-app openshift/nginx-example -p NAME=webapp -p NGINX_VERSION=1.20-ubi9
# oc delete project webapp

# (Optionnel) Configuration de Zsh si ENABLE_ZSH=true
if [[ ! -z "$ENABLE_ZSH" && "$ENABLE_ZSH" == "true" ]]; then
    echo "Installation de Zsh et Oh My Zsh"
    sudo apt install -y zsh git
    echo "vagrant" | chsh -s /usr/bin/zsh vagrant
    su - vagrant -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    su - vagrant -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
    echo "Zsh ne sera pas installé."
fi

# (Optionnel) Affichage de l’IP de la VM
# IP=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
# echo "L'IP privée de cette VM est : $IP"

IP=$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
echo "For this Stack, you will use $IP IP Address"
