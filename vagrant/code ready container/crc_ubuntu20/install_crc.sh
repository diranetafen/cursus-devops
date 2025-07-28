#!/bin/bash
set -euxo pipefail

# Installer les outils
sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst curl wget git

# Ajouter vagrant au groupe libvirt
sudo usermod -aG libvirt vagrant

# Téléchargement du CRC binaire
CRC_VERSION="2.52.0"
wget https://mirror.openshift.com/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz
tar -xf crc-linux-amd64.tar.xz
sudo cp crc-linux-${CRC_VERSION}-amd64/crc /usr/local/bin/
sudo chmod +x /usr/local/bin/crc

# Téléchargement du pull-secret
curl -o /home/vagrant/pull-secret.txt https://eazytraining.fr/wp-content/uploads/2022/10/openshift-crc-pull-secret.txt
chown vagrant:vagrant /home/vagrant/pull-secret.txt

cat <<'EOF' > /home/vagrant/install_crc_as_vagrant.sh
#!/bin/bash
set -euxo pipefail

# CRC config et start
crc config set pull-secret-file /home/vagrant/pull-secret.txt
crc config set consent-telemetry yes
crc config set skip-check-root-user true
crc setup
crc start

# DNS (commenté)
# echo "127.0.0.1 api.crc.testing oauth-openshift.apps-crc.testing console-openshift-console.apps-crc.testing" | sudo tee -a /etc/hosts

# Zsh setup si demandé
if [[ ! -z "$ENABLE_ZSH" && "$ENABLE_ZSH" == "true" ]]; then
  echo "Installation de Zsh et Oh My Zsh"
  sudo apt install -y zsh git
  echo "vagrant" | chsh -s /usr/bin/zsh vagrant
  su - vagrant -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
  su - vagrant -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
  echo "plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
  echo "Zsh ne sera pas installé."
fi

# Affichage IP
IP=\$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
#IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1)
echo 
echo "For this Stack, you will use \$IP IP Address"
echo 

EOF

echo 
echo "SSH Connect in crc vm and run the install_crc_as_vagrant.sh script placed in /home/vagrant folder"
echo 

# Rendre le script exécutable
sudo chmod +x /home/vagrant/install_crc_as_vagrant.sh
sudo chown vagrant:vagrant /home/vagrant/install_crc_as_vagrant.sh
