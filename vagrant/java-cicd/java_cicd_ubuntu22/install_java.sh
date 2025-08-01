#!/bin/sh

VERSION_STRING="5:25.0.3-1~ubuntu.22.04~jammy"
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

# Install epel-release,firefox,  git, java
sudo apt -y install epel-release git java-11-openjdk-devel

# Installation de maven 3.8
cd /usr/local/src/
sudo apt install wget -y
wget https://downloads.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz 
tar -xvf apache-maven-3.8.5-bin.tar.gz 
mv apache-maven-3.8.5 /usr/local/maven/
echo -e "# Apache Maven Environment Variables\n# MAVEN_HOME for Maven 1 - M2_HOME for Maven 2\nexport M2_HOME=/usr/local/maven\nexport PATH=\${M2_HOME}/bin:\${PATH}" > /etc/profile.d/maven.sh
chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

# Configure docker host requirements for sonar container
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192

echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo -e "Connect through ssh on the VM and then run \n 'sudo alternatives --config java' and then press '1' + Enter. \n Also, run 'sudo alternatives --config javac', and then press '1' + Enter. \n The second time is not a repetition, there is 'c' after 'java'"
