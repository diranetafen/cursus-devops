#!/bin/bash

# Mise à jour des paquets
sudo yum -y update

# Installation des prérequis
sudo yum -y install python3
sudo yum -y install python3-pip
sudo yum -y install @development-tools
sudo yum -y install epel-release
sudo yum -y install xorg-x11-xauth x11-xkb-utils

# Installation de PyCharm via Snap
sudo yum -y install snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install pycharm-community --classic

# Configuration du clavier en français
sudo setxkbmap fr
echo "setxkbmap fr" >> /home/vagrant/.bashrc
sudo chown vagrant:vagrant /home/vagrant/.bashrc

# Configuration du fuseau horaire
sudo timedatectl set-timezone Europe/Paris

# Affichage de l'adresse IP de la machine
IP_ADDRESS=$(ip -o -4 addr show eth1 | awk '{print $4}' | cut -d/ -f1)
echo "##############"
echo "## VM ready ##"
echo "##############"
echo "For this Stack, you will use $IP_ADDRESS IP Address"
echo "The VM will restart, please wait until 2 minutes before connecting to the VM"

# Redémarrage de la machine
sudo reboot

