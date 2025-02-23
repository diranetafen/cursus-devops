#!/bin/bash
#
# Variables
ROLE=$1
#MASTER_IP=$2
#TOKEN_FILE="/vagrant/kube_token_info.txt"

# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration

# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

sudo systemctl restart systemd-resolved

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

## Install CRIO Runtime

sudo apt-get update -y
apt-get install -y software-properties-common curl apt-transport-https ca-certificates
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI runtime installed successfully"

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-get install -y jq

# Disable auto-update services
sudo apt-mark hold kubelet kubectl kubeadm cri-o


local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF


if [ "$ROLE" == "controlplane" ]; then
    # Setup for Control Plane (Master) servers

    set -euxo pipefail

    NODENAME=$(hostname -s)

    sudo kubeadm config images pull

    echo "Preflight Check Passed: Downloaded All Required Images"

    sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

    mkdir -p "$HOME"/.kube
    sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
    sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

    # Save Configs to shared /Vagrant location

    # For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

    config_path="/vagrant/configs"

    if [ -d $config_path ]; then
    rm -f $config_path/*
    else
    mkdir -p $config_path
    fi

    cp -i /etc/kubernetes/admin.conf $config_path/config
    touch $config_path/join.sh
    chmod +x $config_path/join.sh

    kubeadm token create --print-join-command > $config_path/join.sh

    # Install Calico Network Plugin

    curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O

    kubectl apply -f calico.yaml

    sudo -i -u vagrant bash << EOF
    whoami
    mkdir -p /home/vagrant/.kube
    sudo cp -i $config_path/config /home/vagrant/.kube/
    sudo chown 1000:1000 /home/vagrant/.kube/config 
EOF

    # Install Metrics Server

    kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

elif [ "$ROLE" == "node" ]; then
    # Setup for Node servers

    set -euxo pipefail

    config_path="/vagrant/configs"

    /bin/bash $config_path/join.sh -v

    sudo -i -u vagrant bash << EOF
    whoami
    mkdir -p /home/vagrant/.kube
    sudo cp -i $config_path/config /home/vagrant/.kube/
    sudo chown 1000:1000 /home/vagrant/.kube/config
    NODENAME=$(hostname -s)
    kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
EOF

fi

# Activer kubelet au démarrage
sudo systemctl enable kubelet
sudo systemctl start kubelet

# Installer et Configurer l'auto-completion
sudo apt install bash-completion -y
echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc
echo 'alias k=kubectl' >> ~vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc

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

echo -e "Everything is Good, $ROLE is ready. \nFor this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
