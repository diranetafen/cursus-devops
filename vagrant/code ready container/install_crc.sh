#!/bin/bash
sudo yum -y update

# install usefull tools
sudo yum install -y git wget

# install libvirt
sudo yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# download secret
su - vagrant  -c  '  curl https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt > /home/vagrant/pull-secret.txt'

# download crc
su - vagrant  -c  'wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/2.9.0/crc-linux-amd64.tar.xz'
su - vagrant  -c  'tar -xf crc-linux-amd64.tar.xz'
su - vagrant  -c  'sudo cp ./crc-linux-2.9.0-amd64/crc /usr/bin/ && sudo chmod +x /usr/bin/crc'
su - vagrant  -c  'crc config set pull-secret-file /home/vagrant/pull-secret.txt'
su - vagrant  -c  'crc config set consent-telemetry yes'
su - vagrant  -c  'crc setup'
su - vagrant  -c  'crc start'

# dns entry in hosts file
# 127.0.0.1	api.crc.testing oauth-openshift.apps-crc.testing console-openshift-console.apps-crc.testing

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