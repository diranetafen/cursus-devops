#!/bin/bash
# VERSION_STRING="5:23.0.6-1~ubuntu.20.04~focal"
VERSION_STRING="5:25.0.3-1~ubuntu.22.04~jammy"
ENABLE_ZSH=true

# Mise à jour du système
echo 
echo "[INFO] Mise à jour du système"
echo
sudo apt update
sudo apt upgrade -y

# Installation des paquets nécessaires

# Add Docker's official GPG key:
echo 
echo "[INFO] Ajout de la clé GPG officielle de Docker"
echo
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo 
echo "[INFO] Ajout des Dépôts aux sources APT"
echo 
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker
echo 
echo "[INFO] Installation de Docker"
echo 
sudo apt-get update
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker vagrant
echo '1' | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

# Installation de Minikube
echo 
echo "[INFO] Installation de Minikube"
echo
MINIKUBE_VERSION="v1.35.0"
curl -LO "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Installation de kubeadm, kubectl et kubelet
echo 
echo "[INFO] Pré-requis pour l'installation de kubernetes"
echo
sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Configuration du dépôt pour Kubernetes 1.32
echo 
echo "[INFO] Configuration du dépôt pour Kubernetes 1.32"
echo
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Installation des composants Kubernetes
echo 
echo "[INFO] Installation des composants de Kubernetes"
echo
sudo apt-get install -y kubelet kubeadm kubectl

# Empêcher les mises à jour automatiques de kubelet, kubeadm et kubectl
echo 
echo "[INFO] Empêcher les mises à jour automatiques de kubelet, kubeadm et kubectl"
echo
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Installation de conntrack
echo 
echo "[INFO] Installation de conntrack"
echo
sudo apt install -y conntrack

# Installation de crictl
echo 
echo "[INFO] Installation de crictl"
echo
CRICTL_VERSION="v1.31.0"
curl -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
tar -zxvf "crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
sudo mv crictl /usr/local/bin/

# Mise à jour et installation de Git et Build Essentials
echo 
echo "[INFO] Mise à jour et installation de Git et Build Essentials"
echo
sudo apt update
sudo apt install -y git build-essential

# Installation de Go
echo 
echo "[INFO] Installation de Go"
echo
GO_VERSION="1.21.1"
wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile

# Installation des plugins CNI
echo 
echo "[INFO] Installation des plugins CNI"
echo
CNI_VERSION="v1.5.1"
curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzvf "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

# Installation de cri-dockerd
echo 
echo "[INFO] Installation de cri-dockerd"
echo
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd-0.3.15.amd64.tgz
tar -xvf cri-dockerd-0.3.15.amd64.tgz
mv cri-dockerd/cri-dockerd /usr/local/bin/
sudo chmod +x /usr/local/bin/cri-dockerd

# Installation de socat
echo 
echo "[INFO] Installation de socat"
echo
sudo apt-get install -y socat

# Créer et configurer les fichiers systemd pour cri-dockerd
echo 
echo "[INFO] Créer et configurer les fichiers systemd pour cri-dockerd"
echo
sudo bash -c 'cat <<EOF > /etc/systemd/system/cri-dockerd.service
[Unit]
Description=CRI for Docker
Documentation=https://github.com/Mirantis/cri-dockerd
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/cri-dockerd
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF'

# Recharger les définitions des services
echo 
echo "[INFO] Recharger les définitions des services"
echo
sudo systemctl daemon-reload

# Activer et démarrer cri-dockerd.service
echo 
echo "[INFO] Activer et démarrer cri-dockerd.service"
echo
sudo systemctl enable cri-dockerd.service
sudo systemctl start cri-dockerd.service

# Créer et écrire dans /etc/systemd/system/cri-docker.socket
echo 
echo "[INFO] Mise à jour de la socket cri-docker"
echo
sudo bash -c 'cat <<EOF > /etc/systemd/system/cri-docker.socket
[Unit]
Description=Socket for CRI for Docker

[Socket]
ListenStream=0.0.0.0:50051
Accept=yes

[Install]
WantedBy=sockets.target
EOF'

# Recharger les définitions des services
echo 
echo "[INFO] Recharger les définitions des services"
echo
sudo systemctl daemon-reload

# Activer et démarrer cri-docker.socket
echo 
echo "[INFO] Activer et démarrer cri-docker.socket"
echo
sudo systemctl enable cri-docker.socket
sudo systemctl start cri-docker.socket

echo 
echo "[INFO] Démarrer Minikube avec le driver none"
echo
minikube start --kubernetes-version v1.32.0 --driver=none

# Installer et Configurer l'auto-completion
echo 
echo "[INFO] Installer et Configurer l'auto-completion"
echo
sudo apt-get update
sudo apt install bash-completion -y
echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc
echo 'alias k=kubectl' >> ~vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc

# Install zsh if needed
echo 
echo "[INFO] Installation de zsh si nécessaire"
echo
if [[ -n "$ENABLE_ZSH"  &&  $ENABLE_ZSH == "true" ]]; then
  echo "We are going to install zsh"
  sudo apt -y install zsh git
  echo "vagrant" | chsh -s /bin/zsh vagrant
  su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
  echo "plugins=(git  colored-man-pages aliases copyfile  copypath zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
  echo "The zsh is not installed on this server"
fi

# IP=$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)192\.168\.\d+\.\d+' | head -n1)
echo 
echo "[INFO] For this Stack, you will use $IP IP Address"
echo