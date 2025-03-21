#!/bin/bash
yum -y update
yum -y install epel-release

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
        yum install -y docker net-tools

        groupadd docker || true
        usermod -aG docker vagrant || true

        systemctl restart docker || true
        systemctl enable docker || true

        yum install -y sshpass
        SSH_CONFIG="/etc/ssh/sshd_config"
        sudo sed -i 's/^#\s*\(PubkeyAuthentication\s.*\)/\1/' "$SSH_CONFIG"
        sudo systemctl restart sshd
        echo "La ligne 'PubkeyAuthentication yes' a été décommentée et le service SSH a été redémarré."
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi