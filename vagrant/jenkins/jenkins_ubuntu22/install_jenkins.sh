#!/bin/bash

VERSION_STRING="5:25.0.3-1~ubuntu.22.04~jammy"
ENABLE_ZSH=true
sudo apt install -y git curl wget

# Install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -aG docker vagrant
systemctl enable docker
systemctl start docker
sudo apt install -y sshpass
sudo mkdir jenkins && cd jenkins
# curl -o docker-compose.yml https://raw.githubusercontent.com/diranetafen/cursus-devops/refs/heads/master/jenkins/docker-compose.yml
curl -o docker-compose.yml https://raw.githubusercontent.com/OlivierKouokam/cursus-devops-stack/refs/heads/master/jenkins/docker-compose-official.yml
docker compose up -d

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo apt -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git docker docker-compose helm kubectl kubectx minikube colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
    echo "The zsh is not installed on this server"
fi
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo -e "to get jenkins password, please use the following command  \n *** docker exec \$(docker ps -a | grep jenkins | awk '{print \$1}') bash -c 'cat /var/jenkins_home/secrets/initialAdminPassword' ***"
