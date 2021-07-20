#!/bin/sh
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main" >> /etc/apt/sources.list
apt-get update
apt-get -y install dirmngr --install-recommends
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
apt update
apt -y install ansible

# retrieve ansible code
apt -y install git
git clone https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
ansible-galaxy install -r roles/requirements.yml
ansible-playbook install_docker.yml
usermod -aG docker vagrant
#before install gitlab-ci we get the punlic dns

GITLAB_EXTERNAL_HOSTNAME=`ip -f inet addr show eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`

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
ansible-playbook install_gitlab_ci.yml --extra-var "gitlab_external_hostname=${GITLAB_EXTERNAL_HOSTNAME}"

# Manage .crt and .key files to enable authentication
rm -f /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.key
mv /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/$GITLAB_EXTERNAL_HOSTNAME.crt /etc/docker/certs.d/$GITLAB_EXTERNAL_HOSTNAME/ca.crt

# End message
echo "IMPORTANT"
echo "Depending on your internet connection speed the download image operation must take some times"
echo "So don't be worry if gitlab container was not up immedialty, you can check the progress state with the following command"
echo "sudo journalctl -u gitlab-docker.service"
echo "or docker ps to check if containers are already up and running"
echo "For this Stack, you will use $(ip -f inet addr show eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
