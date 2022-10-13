#!/bin/bash
yum -y update

# install usefull tools
yum install -y git wget

# install libvirt
yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install
systemctl enable libvirtd
systemctl start libvirtd

# download secret
curl https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt > /root/pull-secret.txt

# download crc
wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/2.9.0/crc-linux-amd64.tar.xz
tar -xf crc-linux-amd64.tar.xz
cp ./crc-linux-2.9.0-amd64/crc /usr/bin/ && chmod +x /usr/bin/crc
crc config set pull-secret-file /root/pull-secret.txt
crc config set consent-telemetry yes
crc config set skip-check-root-user true
crc setup
crc start

# dns entry in hosts file
# 127.0.0.1	api.crc.testing oauth-openshift.apps-crc.testing console-openshift-console.apps-crc.testing

# Deploy webapp
# oc new-project webapp
# oc new-app -S nginx
# oc process openshift//nginx-example --parameters
# oc new-app openshift/nginx-example -p NAME=webapp -p NGINX_VERSION=1.20-ubi9
# oc delete project webapp

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    yum -y install zsh git
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