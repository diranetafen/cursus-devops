#!/bin/bash
set -e

echo
echo "[FIX] Dépôts CentOS 7 -> vault.centos.org"
echo
sudo sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

echo
echo "[INSTALL] Mise à jour et installation des dépendances..."
echo
sudo yum install -y epel-release
sudo yum update -y
sudo yum install -y libvirt qemu-kvm curl NetworkManager

echo
echo "[INSTALL] Activation des services..."
echo
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo
echo "[INSTALL] Ajout de vagrant aux groupes libvirt et kvm..."
echo
sudo usermod -a -G libvirt vagrant
sudo usermod -a -G kvm vagrant

echo
echo "[INSTALL] Téléchargement du pull secret..."
echo
sudo curl -s https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt -o /home/vagrant/pull-secret.json
sudo chown vagrant:vagrant /home/vagrant/pull-secret.json

echo
echo "[INSTALL] Téléchargement et installation de CRC v2.30.0..."
echo
CRC_VERSION="2.30.0"
cd /tmp
curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz"
tar -xf crc-linux-amd64.tar.xz
sudo mv crc-linux-*/crc /usr/local/bin/

echo
echo "[INSTALL] CRC installé :"
echo
export PATH=$PATH:/usr/local/bin
crc version

# Redémarrage nécessaire pour prise en compte des groupes
touch /home/vagrant/needs_reboot
