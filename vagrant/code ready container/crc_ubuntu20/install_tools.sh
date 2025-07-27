#!/bin/bash
set -e

# Installer les outils
sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst curl wget git

# Ajouter vagrant au groupe libvirt
sudo usermod -aG libvirt vagrant

# Téléchargement du CRC binaire
CRC_VERSION="2.52.0"
wget https://mirror.openshift.com/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz
tar -xf crc-linux-amd64.tar.xz
sudo cp crc-linux-${CRC_VERSION}-amd64/crc /usr/local/bin/
sudo chmod +x /usr/local/bin/crc

# Téléchargement du pull-secret
curl -o /home/vagrant/pull-secret.txt https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt
chown vagrant:vagrant /home/vagrant/pull-secret.txt

# Redémarrage nécessaire pour que le groupe soit pris en compte
echo "Redémarrage nécessaire pour appliquer le groupe libvirt à l'utilisateur vagrant."
sudo reboot
