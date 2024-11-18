#!/bin/bash
sudo yum -y update

# install docker
sudo yum install -y git python3 epel-release
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker vagrant
sudo systemctl enable docker
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
#Install ansible 
curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | sudo python3
/usr/local/bin/pip3 install ansible
yum install -y sshpass
git clone https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
/usr/local/bin/ansible-galaxy install -r roles/requirements.yml
#before install gitlab-ci we get the punlic dns


GITLAB_EXTERNAL_HOSTNAME=`ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`

# Create cert path for docker
sudo mkdir -p  /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME

# Create cert path for GitLab
sudo mkdir -p /opt/gitlab/cert/

# Generate selfsigned certificate (.cert and .key)
sudo echo -e "\n\n\n\n\n"$GITLAB_EXTERNAL_HOSTNAME"\n" | openssl req -newkey rsa:4096 -nodes -sha256 -keyout /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.key -x509 -days 365 -out /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.crt

# Change rules for .crt and .key files
chmod 600 /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.key
chmod 600 /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.crt

# Copy .crt and .key files in cert path for GitLab
cp /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.key /opt/gitlab/cert/$GITLAB_EXTERNAL_HOSTNAME.key
cp /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.crt /opt/gitlab/cert/$GITLAB_EXTERNAL_HOSTNAME.crt

# Deploy GitLab with Ansible
/usr/local/bin/ansible-playbook install_gitlab_ci.yml --extra-var "gitlab_external_hostname=${GITLAB_EXTERNAL_HOSTNAME}"

# Manage .crt and .key files to enable authentication
rm -f /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.key
mv /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.crt /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/ca.crt

# End message
echo "IMPORTANT"
echo "Depending on your internet connection speed the download image operation must take some times"
echo "So don't be worry if gitlab container was not up immedialty, you can check the progress state with the following command"
echo "sudo journalctl -u gitlab-docker.service"
echo "or docker ps to check if containers are already up and running"
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
