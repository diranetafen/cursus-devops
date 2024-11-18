#!/bin/bash

#Update Operating System  && install docker and  docker-compose
echo
echo ...Update and Docker installation
echo
sudo yum update -y
sudo curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo service docker start
sudo  usermod -aG docker $USER
sudo chkconfig docker on
sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo yum install -y git python3 python3-pip
sudo setenforce 0

#Git Installation
echo 
echo ...Installing Git
echo 
sudo yum -y remove git
sudo yum -y remove git-*
sudo yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
sudo yum install git git-core -y 

#Jenkins Installation
sudo yum update -y 
sudo yum install java-11-openjdk-devel -y
sudo yum install -y wget
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins


#minikube Installation
echo
echo ...Installing Minikube
echo
sudo yum -y update
sudo yum -y install epel-release
sudo yum -y install git libvirt qemu-kvm virt-install virt-top libguestfs-tools bridge-utils
sudo yum install socat -y
sudo yum install -y conntrack
sudo yum -y install wget
sudo wget https://storage.googleapis.com/minikube/releases/v1.28.0/minikube-linux-amd64
sudo chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/bin/minikube
sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.0/bin/linux/amd64/kubectl
sudo chmod +x kubectl
sudo mv kubectl  /usr/bin/
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sudo systemctl enable docker.service
sudo minikube start --driver=none --addons=registry --kubernetes-version v1.23.0 --listen-address=0.0.0.0
sudo yum install bash-completion -y
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -F __start_kubectl k' >> /root/.bashrc


#Run argocd
echo
echo ...Getting rid of existing instances
echo
kubectl delete ns argocd
#pkill kubectl
echo
echo ...Installing argocd
echo
# install argocd
# ref: https://argo-cd.readthedocs.io/en/stable/getting_started/
kubectl create ns argocd

#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.9.3/manifests/install.yaml
echo
echo ...Waiting for pods to be ready
echo
kubectl wait --for=condition=Ready pod --all -n argocd
echo
echo ...Getting initial ArgoCD password
echo

# # If you want to get the password
# # dump out the initial argocd password
echo
echo ArgoCD password follows:
echo
echo !!!!!!!!!!!!!
echo
argocd=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo
echo !!!!!!!!!!!!!
echo Change The default Service port for ArgoCD Server
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: argocd-server
  namespace: argocd
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8080
    nodePort: 30000
  selector:
    app.kubernetes.io/name: argocd-server
  type: NodePort
EOF

#Init Git directory
sudo mkdir /repos
cd /repos
git init --bare

#tools for kubernetes
echo 
echo ...kubens and kubectx installing
echo 
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
echo "source /opt/kubectx/completion/kubectx.bash" >> ~/.bashrc
echo "source /opt/kubectx/completion/kubens.bash" >> ~/.bashrc

#tools for ArgoCD
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.9.3/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

#Kustomize tools
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.5/kustomize_v3.8.5_linux_amd64.tar.gz
tar zxf kustomize_v3.8.5_linux_amd64.tar.gz 
sudo mv  kustomize /usr/local/bin
which kustomize
kustomize version

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "We are going to install zsh"
    sudo yum -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git  docker docker-compose colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
  else
    echo "The zsh is not installed on this server"    
fi

echo "IMPORTANT !!!!!!!!!!!!!!"
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
echo "For ArgoCD Server Use this credentials: User = admin && Password = "$argocd " with this NodePort Service = 30000"



