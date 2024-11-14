#!/bin/bash
VERSION_STRING="5:20.10.0~3-0~ubuntu-focal"
ENABLE_ZSH=true

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker Community Edition
sudo apt-get update
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant

# Installation de Minikube
MINIKUBE_VERSION="v1.34.0"
curl -LO "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Installation de kubeadm, kubectl et kubelet
# sudo snap install kubeadm --classic
# sudo snap install kubectl --classic
# sudo snap install kubelet --classic

# sudo systemctl start kubelet
# sudo systemctl enable kubelet
sudo apt-get update

# apt-transport-https may be a dummy package; if so, you can skip that package

sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Installation de conntrack
sudo apt install -y conntrack

# Installation de crictl
CRICTL_VERSION="v1.31.0"
curl -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
tar -zxvf "crictl-${CRICTL_VERSION}-linux-amd64.tar.gz"
sudo mv crictl /usr/local/bin/

# Mise à jour et installation de Git et Build Essentials
sudo apt update
sudo apt install -y git build-essential

# Installation de Go
GO_VERSION="1.21.1"
wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile

# Installation des plugins CNI
CNI_VERSION="v1.5.1"
curl -LO "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzvf "cni-plugins-linux-amd64-${CNI_VERSION}.tgz"

# Installation de cri-dockerd
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd-0.3.15.amd64.tgz
tar -xvf cri-dockerd-0.3.15.amd64.tgz
mv cri-dockerd/cri-dockerd /usr/local/bin/
sudo chmod +x /usr/local/bin/cri-dockerd

# Installation de socat
sudo apt-get install -y socat
# Créer et écrire dans /etc/systemd/system/cri-dockerd.service
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
sudo systemctl daemon-reload

# Activer et démarrer cri-dockerd.service
sudo systemctl enable cri-dockerd.service
sudo systemctl start cri-dockerd.service

# Créer et écrire dans /etc/systemd/system/cri-docker.socket
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
sudo systemctl daemon-reload

# Activer et démarrer cri-docker.socket
sudo systemctl enable cri-docker.socket
sudo systemctl start cri-docker.socket

# Créer et écrire dans /etc/systemd/system/cri-docker.service
sudo bash -c 'cat <<EOF > /etc/systemd/system/cri-docker.service
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
sudo systemctl daemon-reload

# Activer et démarrer cri-docker.service
sudo systemctl enable cri-docker.service
sudo systemctl start cri-docker.service

# Assurer que cri-docker.socket est démarré
sudo systemctl start cri-docker.socket
minikube start --driver=none


#Run argocd
echo
echo ...Getting rid of existing instances
echo
kubectl delete ns argocd
#pkill kubectl
echo
echo ...Installing argocd
echo
# install argocd
# ref: https://argo-cd.readthedocs.io/en/stable/getting_started/
kubectl create ns argocd

#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.3/manifests/install.yaml
echo
echo ...Waiting for pods to be ready
echo
kubectl wait --for=condition=Ready pod --all -n argocd
echo
echo ...Getting initial ArgoCD password
echo

# # If you want to get the password
# # dump out the initial argocd password
echo
echo ArgoCD password follows:
echo
echo !!!!!!!!!!!!!
echo
argocd=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo
echo !!!!!!!!!!!!!
echo Change The default Service port for ArgoCD Server
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: argocd
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8080
    nodePort: 30000
  selector:
    app.kubernetes.io/name: argocd-server
  type: NodePort
EOF

#Init Git directory
sudo mkdir /repos
cd /repos
git init --bare

#tools for kubernetes
echo 
echo ...kubens and kubectx installing
echo 
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
echo "source /opt/kubectx/completion/kubectx.bash" >> ~/.bashrc
echo "source /opt/kubectx/completion/kubens.bash" >> ~/.bashrc

#tools for ArgoCD
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.9.3/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

#Kustomize tools
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.5/kustomize_v3.8.5_linux_amd64.tar.gz
tar zxf kustomize_v3.8.5_linux_amd64.tar.gz 
sudo mv  kustomize /usr/local/bin
which kustomize
kustomize version

# Install zsh if needed
if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
    then
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

fi

echo "IMPORTANT !!!!!!!!!!!!!!"
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo "For ArgoCD Server Use this credentials: User = admin && Password = "$argocd " with this NodePort Service = 30000"



