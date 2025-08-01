#!/bin/bash
ENABLE_ZSH=true
# VERSION_STRING=2.9.10*
VERSION_STRING=2.9.6+dfsg-1

# Install Common Package
sudo apt -y update
sudo apt install -y python3 git curl wget 
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
# sudo add-apt-repository ppa:ansible/ansible -y
# sudo apt install ansible=$VERSION_STRING

if [ $1 == "master" ]
then

  # #install ansible
  # curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | sudo python3
  # /usr/local/bin/pip3 install ansible==$VERSION_STRING  
  sudo apt install ansible=$VERSION_STRING -y

  apt install -y sshpass
  
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
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
