
#!/bin/bash
yum -y update
yum -y install epel-release

# install ansible
yum -y install ansible
# retrieve ansible code
yum -y install git
rm -Rf cursus-devops || echo "previous folder removed"
git clone -b kubernetes https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
ansible-galaxy install -r roles/requirements.yml
ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=$1"
#sudo usermod -aG docker vagrant
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
