
#!/bin/bash
yum -y update
yum -y install epel-release

# install ansible
yum -y install ansible
# retrieve ansible code
yum -y install git
rm -Rf cursus-devops || echo "previous folder removed"
git clone -b kubernetes-var https://github.com/diranetafen/cursus-devops.git
cd cursus-devops/ansible
ansible-galaxy install -r roles/requirements.yml
if [ $1 == "master" ]
then
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=$1 kubernetes_apiserver_advertise_address=$2"
else
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=$1 kubernetes_apiserver_advertise_address=$2 kubernetes_join_command='kubeadm join {{ kubernetes_apiserver_advertise_address }}:6443 --ignore-preflight-errors=all --token={{ token }}  --discovery-token-unsafe-skip-ca-verification'"
fi
#sudo usermod -aG docker vagrant
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
