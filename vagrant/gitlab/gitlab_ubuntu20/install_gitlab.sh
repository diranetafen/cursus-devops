#!/bin/bash
# VERSION_STRING="5:20.10.0~3-0~ubuntu-focal"
VERSION_STRING="5:23.0.6-1~ubuntu.20.04~focal"
ENABLE_ZSH=true

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
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
#Install ansible 
curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | sudo python3
/usr/local/bin/pip3 install ansible
apt install -y sshpass
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