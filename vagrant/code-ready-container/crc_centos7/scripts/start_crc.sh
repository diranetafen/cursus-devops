#!/bin/bash
set -e

export PATH=$PATH:/usr/local/bin

echo
echo "[START] Configuration CRC..."
echo

crc config set memory 10240
crc config set cpus 4
crc config set consent-telemetry no

echo
echo "[START] Setup CRC..."
echo
crc setup

echo
echo "[START] Lancement de CRC avec pull secret..."
echo
crc start -p /home/vagrant/pull-secret.json

echo
echo "[START] Export du kubeconfig..."
echo
mkdir -p /vagrant/.kube
cp ~/.kube/config /vagrant/.kube/config

echo
echo "[START] Console OpenShift :"
echo
crc console --url

echo
echo "[START] Mot de passe admin (kubeadmin) :"
echo
cat ~/.crc/machines/crc/kubeadmin-password

# Zsh setup si demandé
if [[ ! -z "$ENABLE_ZSH" && "$ENABLE_ZSH" == "true" ]]; then
  echo "Installation de Zsh et Oh My Zsh"
  sudo yum install -y zsh git
  echo "vagrant" | chsh -s /usr/bin/zsh vagrant
  su - vagrant -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
  su - vagrant -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
  echo "plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
  echo "Zsh ne sera pas installé."
fi