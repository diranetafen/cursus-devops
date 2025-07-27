#!/bin/bash

set -e

# Mise à jour des dépôts et upgrade système
sudo apt update && sudo apt -y upgrade

# Installation des outils de base
sudo apt install -y curl wget git libvirt-daemon-system libvirt-clients qemu-kvm virtinst bridge-utils unzip net-tools

# Vérification que libvirtd est actif
sudo systemctl enable --now libvirtd

# Ajout de l’utilisateur vagrant au groupe libvirt
sudo usermod -aG libvirt vagrant

# Téléchargement de la pull secret
# Mettre le pull secret dans le home de vagrant
curl -o /home/vagrant/pull-secret.txt https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt
chown vagrant:vagrant /home/vagrant/pull-secret.txt

# Téléchargement de CRC
#CRC_VERSION="2.9.0"
CRC_VERSION="2.52.0"
CRC_ARCHIVE="crc-linux-amd64.tar.xz"
#CRC_URL="https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/${CRC_VERSION}/${CRC_ARCHIVE}"
CRC_URL="https://mirror.openshift.com/pub/openshift-v4/clients/crc/${CRC_VERSION}/${CRC_ARCHIVE}"
wget $CRC_URL
tar -xf $CRC_ARCHIVE
sudo cp crc-linux-${CRC_VERSION}-amd64/crc /usr/local/bin/
sudo chmod +x /usr/local/bin/crc

# Configuration de CRC
# Exécuter crc setup et start via su - vagrant, avec environnement mis à jour
# CRC config et setup en tant que vagrant
su - vagrant -c 'crc config set pull-secret-file /home/vagrant/pull-secret.txt'
su - vagrant -c 'crc config set consent-telemetry yes'
su - vagrant -c 'crc config set skip-check-root-user true'
su - vagrant -c 'crc setup'
su - vagrant -c 'crc start'

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
