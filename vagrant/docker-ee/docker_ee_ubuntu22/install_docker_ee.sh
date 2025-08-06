
#!/bin/bash
VERSION_STRING="5:25.0.3-1~ubuntu.22.04~jammy"
ENABLE_ZSH=true
apt update -y

# Install docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

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
sudo apt-get update
sudo apt-get install -y docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker vagrant
systemctl enable docker
systemctl start docker
sudo apt install -y sshpass

if [ $1 == "master" ]
then
        echo "###################################################"
        echo "Initialize docker swarm cluster"
        echo "###################################################"
        docker swarm init --advertise-addr $2
        echo "###################################################"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
        echo "###################################################"
else
        echo "###################################################"
        echo "Add worker to cluster"
        echo "###################################################"
        TOKEN=$( sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@${2} "docker swarm join-token -q worker" | tail -1)
        docker swarm join --token $TOKEN ${2}:2377
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi
