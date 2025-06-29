
#!/bin/bash
# 1. Mettre à jour la liste des paquets et appliquer les mises à jour disponibles
sudo apt update

# 2. (Optionnel) Activer le dépôt Universe – l’équivalent le plus proche de « extras »
#    – ainsi que le PPA officiel si vous souhaitez la dernière version stable d’Ansible
sudo add-apt-repository universe
sudo add-apt-repository --yes ppa:ansible/ansible
sudo apt update            # Re-lecture des index après ajout de dépôts

# 3. Installer Ansible
sudo apt -y install ansible

# 4. Installer Git (pour récupérer le code Ansible, par exemple)
sudo apt -y install git

# 5. Nettoyer un éventuel répertoire existant
rm -rf kubernetes-certification-stack || echo "previous folder removed"

git clone -b feat/ubuntu https://github.com/eazytraining/kubernetes-certification-stack.git
cd kubernetes-certification-stack
KUBERNETES_VERSION=1.31
ansible-galaxy install -r roles/requirements.yml
if [ $1 == "master" ]
then
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=control_plane kubernetes_apiserver_advertise_address=$2 installation_method=vagrant kubernetes_version='$KUBERNETES_VERSION'"
        # Installer bash-completion puis enregistrer l’auto-complétion de kubectl
        sudo apt update && sudo apt -y install bash-completion \
        && kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
        echo 'source <(kubectl completion bash)' >> ~/.bashrc

        echo "###################################################"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
        echo "You need to be root to use kubectl in $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') VM (run 'sudo su -' to become root and then use kubectl as you want)"
        echo "###################################################"
else
        ansible-playbook install_kubernetes.yml --extra-vars "kubernetes_role=$1 kubernetes_apiserver_advertise_address=$2 kubernetes_version='$KUBERNETES_VERSION' kubernetes_join_command='kubeadm join {{ kubernetes_apiserver_advertise_address }}:6443 --ignore-preflight-errors=all --token={{ token }}  --discovery-token-unsafe-skip-ca-verification'"
        echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
fi
