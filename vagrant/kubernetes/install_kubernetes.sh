
#!/bin/bash
sudo apt  -y update
# install ansible
sudo apt  -y install ansible
# retrieve ansible code
sudo apt  -y install git
rm -Rf kubernetes-certification-stack || echo "previous folder removed"
git clone -b ubuntu https://github.com/ulrich-sun/cursus-devops.git
cd  cursus-devops/vagrant/kubernetes/
KUBERNETES_VERSION=1.31.1
ansible-galaxy install -r roles/requirements.yml
if [ $1 == "master" ]
then
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=control_plane kubernetes_apiserver_advertise_address=$2 kubernetes_version_ubuntu_package='$KUBERNETES_VERSION' installation_method=vagrant"
        sudo apt  install bash-completion -y && kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
        echo "###################################################"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
        echo "You need to be root to use kubectl in $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') VM (run 'sudo su -' to become root and then use kubectl as you want)"
        echo "###################################################"
else
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=$1 kubernetes_apiserver_advertise_address=$2 kubernetes_version_ubuntu_package='$KUBERNETES_VERSION' kubernetes_join_command='kubeadm join {{ kubernetes_apiserver_advertise_address }}:6443 --ignore-preflight-errors=all --token={{ token }}  --discovery-token-unsafe-skip-ca-verification'"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi
