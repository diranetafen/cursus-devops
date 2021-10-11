
#!/bin/bash
yum -y update
yum -y install epel-release

# Install docker
yum remove -y docker\
  docker-client\
  docker-client-latest\
  docker-common\
  docker-latest\
  docker-latest-logrotate\
  docker-logrotate\
  docker-selinux\
  docker-engine-selinux\
  docker-engine\
  docker-ce

rm /etc/yum.repos.d/docker*.repo || echo "not found"
echo "https://storebits.docker.com/ee/trial/sub-76c16081-298d-4950-8d02-7f5179771813/centos" >/etc/yum/vars/dockerurl
echo "7" > /etc/yum/vars/dockerosversion
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo "https://storebits.docker.com/ee/trial/sub-76c16081-298d-4950-8d02-7f5179771813/centos/docker-ee.repo"
yum -y install docker-ee

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
