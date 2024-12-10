#!/bin/bash
ENABLE_ZSH=true
echo "###################################################"
echo "               Updating system                     " 
echo "###################################################"
sudo apt install -y git curl wget

echo "#######################################################################"
echo "  Install prerequisite for this course (git, docker and docker compose " 
echo "#######################################################################"

# VERSION_STRING="5:20.10.0~3-0~ubuntu-focal"
VERSION_STRING="5:23.0.6-1~ubuntu.20.04~focal"
ENABLE_ZSH=true
sudo apt install -y git curl wget

# Install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
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
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker vagrant
systemctl enable docker
systemctl start docker
sudo apt install -y sshpass

if [ $1 == "haproxy" ]
then
        #echo "###################################################"
        #echo "       Let's go to install HAProxy programm        "
        #echo "###################################################"
        sudo apt install haproxy -y
        sudo sed -i s/5000/50000/g /etc/haproxy/haproxy.cfg
        sudo systemctl enable --now haproxy
        sudo systemctl restart haproxy
        echo "###################################################"
        echo "     Install backend applications for HAProxy      "
        echo "###################################################"
        docker run -d --name red -p 8080:8080 -e APP_COLOR=red kodekloud/webapp-color
        docker run -d --name blue -p 8081:8080 -e APP_COLOR=blue kodekloud/webapp-color
        git clone https://github.com/eazytraining/haproxy-training.git
        cd haproxy-training/TP0
        docker build -t site1  ./site1/
        docker run -d --name site1 -p 81:80 site1
        docker build -t site2 ./site2/
        docker run -d --name site2 -p 82:80 site2
        docker build -t student-list ./student-list/simple_api/
        docker network create student-list
        docker run -d --network student-list --name api -v $PWD/student-list/simple_api/student_age.json:/data/student_age.json -p 5000:5000 student-list
        docker run -d --network student-list -p 83:80 -v $PWD/student-list/website:/var/www/html -e USERNAME=toto -e PASSWORD=python --name ihm-api php:apache
        echo "192.168.99.10 myproxy.eazytraining.com" >> /etc/hosts        

else
        echo "###################################################"
        echo "       Let's go to install Squid programm          "
        echo "###################################################"
        sudo apt install squid -y

fi


if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo apt -y install zsh git
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