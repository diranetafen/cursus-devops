#!/bin/bash
set -e

echo
echo "[INSTALL] Mise à jour et installation des dépendances..."
echo
sudo apt-get update
sudo apt-get install -y libvirt-daemon-system libvirt-clients qemu-kvm curl network-manager

echo
echo "[INSTALL] Ajout de l'utilisateur vagrant aux groupes kvm/libvirt..."
echo
sudo usermod -a -G libvirt vagrant
sudo usermod -a -G kvm vagrant

echo
echo "[INSTALL] Activation de NetworkManager..."
echo
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo
echo "[INSTALL] Téléchargement et installation de CRC v2.30.0..."
echo
CRC_VERSION="2.30.0"
cd /tmp
curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz"
tar -xf crc-linux-amd64.tar.xz
sudo mv crc-linux-*/crc /usr/local/bin/

echo
echo "[INSTALL] Version CRC installée :"
echo
crc version

# Flag pour redémarrage
touch /home/vagrant/needs_reboot
