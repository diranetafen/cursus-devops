#!/bin/bash
DOCKER_VERSION="3:19.03.2-3.el7"
ENABLE_ZSH=true

# Mise à jour du système et remplacement des dépôts
sudo sed -i -e 's/mirror.centos.org/vault.centos.org/g' \
           -e 's/^#.*baseurl=http/baseurl=http/g' \
           -e 's/^mirrorlist=http/#mirrorlist=http/g' \
           /etc/yum.repos.d/*.repo
sudo yum -y update

# Installation des paquets nécessaires
sudo yum install -y yum-utils git wget curl iptables iptables-services

# Installation de Docker
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine || true
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo yum -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git  docker docker-compose colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
  else
    echo "The zsh is not installed on this server"    
fi

echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
