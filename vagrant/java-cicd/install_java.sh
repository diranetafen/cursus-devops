#!/bin/sh
sudo yum -y update

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker vagrant
systemctl enable docker
sudo systemctl start docker
yum install -y sshpass

# Install epel-release,firefox,  git, java
sudo yum -y install epel-release git java-11-openjdk-devel

# Installation de maven 3.8
cd /usr/local/src/
sudo yum install wget -y
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
