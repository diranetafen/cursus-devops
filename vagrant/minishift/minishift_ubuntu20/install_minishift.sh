#!/bin/bash
sudo apt -y update

if [ $1 == "minishift" ]
then
        echo "###################################################"
        echo "Install minishift"
        echo "###################################################"
        curl -L https://github.com/minishift/minishift/releases/download/v1.34.3/minishift-1.34.3-linux-amd64.tgz -o minishift.tar.gz
        tar -xvzf minishift.tar.gz
        cd minishift-1.34.3-linux-amd64
        cp minishift /usr/bin/
        export PATH=$PWD:$PATH
        export MINISHIFT_ENABLE_EXPERIMENTAL=y
        minishift addons disable minishift-mobilecore-addon
        minishift delete
        rm -rf ~/.minishift/machines
        minishift start --vm-driver generic --remote-ipaddress $2 --remote-ssh-user vagrant --remote-ssh-key /home/vagrant/.ssh/minishift.key --openshift-version v3.10.0
        cp /root/.minishift/cache/oc/v3.10.0/linux/oc /usr/bin/

        echo "###################################################"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
        echo "###################################################"
else
        echo "###################################################"
        echo "Create docker host"
        echo "###################################################"
        # Install docker

        #ref : https://github.com/mikenairn/minishift-vagrant
        # VERSION_STRING="5:20.10.0~3-0~ubuntu-focal"
        VERSION_STRING="5:23.0.6-1~ubuntu.20.04~focal"
        ENABLE_ZSH=true

        # Add Docker's official GPG key:
        sudo apt-get update
        sudo apt-get install ca-certificates curl net-tools  -y
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
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker vagrant
        sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
        SSH_CONFIG="/etc/ssh/sshd_config"
        sudo sed -i 's/^#\s*\(PubkeyAuthentication\s.*\)/\1/' "$SSH_CONFIG"
        sudo apt install -y sshpass
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi
