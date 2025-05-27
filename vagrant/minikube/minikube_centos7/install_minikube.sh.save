#!/bin/bash

set -e
set -o pipefail
export ENABLE_ZSH=true

# Variables
ENABLE_ZSH=true
MINIKUBE_VERSION="v1.34.0"
CRICTL_VERSION="v1.31.0"
GO_VERSION="1.21.1"
CNI_VERSION="v1.5.1"
KUBERNETES_VERSION="1.31.1"

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

# Installation de Minikube
curl -LO "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Installation de kubeadm, kubectl et kubelet
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum install -y kubelet-${KUBERNETES_VERSION} kubeadm-${KUBERNETES_VERSION} kubectl-${KUBERNETES_VERSION} --disableexcludes=kubernetes

#sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Installation de conntrack
sudo yum install -y conntrack-tools

# Installation de crictl
curl -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
tar -zxvf "crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
sudo mv crictl /usr/local/bin/

# Installation de Go
wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile

# Installation des plugins CNI
curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzvf "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

# Installation de cri-dockerd
# Définir les variables
CRIDOCKERD_VERSION="0.3.15"
ARCH="amd64"
RELEASE_URL="https://github.com/Mirantis/cri-dockerd/releases/download/v${CRIDOCKERD_VERSION}/cri-dockerd-${CRIDOCKERD_VERSION}.${ARCH}.tgz"
TAR_FILE="cri-dockerd-${CRIDOCKERD_VERSION}.${ARCH}.tgz"
EXTRACTED_DIR="cri-dockerd"
DESTINATION="/usr/local/bin/cri-dockerd"

# Télécharger le fichier
wget ${RELEASE_URL}

# Extraire le fichier tar
tar -xvf ${TAR_FILE}

# Déplacer le binaire dans le répertoire /usr/local/bin
sudo mv ${EXTRACTED_DIR}/cri-dockerd ${DESTINATION}

# Donner les permissions d'exécution
sudo chmod +x ${DESTINATION}

# Installation de socat
sudo yum install -y socat

# Création des fichiers de service systemd
cat <<EOF | sudo tee /etc/systemd/system/cri-dockerd.service
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
EOF

cat <<EOF | sudo tee /etc/systemd/system/cri-docker.socket
[Unit]
Description=Socket for CRI for Docker

[Socket]
ListenStream=0.0.0.0:50051
Accept=yes

[Install]
WantedBy=sockets.target
EOF

# Recharger les définitions des services
sudo systemctl daemon-reload

# Activer et démarrer les services
sudo systemctl enable --now cri-dockerd.service
sudo systemctl enable --now cri-docker.socket

# Démarrer Minikube
#minikube start --driver=none --kubernetes-version v1.31.1
su - vagrant -c "minikube start --driver=none --kubernetes-version v${KUBERNETES_VERSION}"
sudo yum install bash-completion -y
echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc
echo 'alias k=kubectl' >> ~vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo yum -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git docker docker-compose helm kubectl kubectx minikube colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
    echo "The zsh is not installed on this server"
fi


IS_MINIKUBE_UP=$(curl -k https://localhost:8443/livez?verbose | grep -i "livez check passed")

if [[ ($IS_MINIKUBE_UP == "livez check passed") ]]
then
    echo -e "Everything is Good, minikube is ready. \nFor this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
else
    echo "Error, your minikube server (Kubernetes) is not running"
fi
