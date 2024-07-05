
#!/bin/bash
yum -y update
yum -y install epel-release

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
systemctl enable docker
systemctl start docker
yum install -y sshpass

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
