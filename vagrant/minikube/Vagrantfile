# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "minikube" do |minikube|
    minikube.vm.box = "geerlingguy/centos7"
    minikube.vm.network "private_network", type: "dhcp"
    minikube.vm.hostname = "minikube"
    minikube.vm.provider "virtualbox" do |v|
      v.name = "minikube"
      v.memory = 4096
      v.cpus = 2
    end
    minikube.vm.provision :shell do |shell|
      shell.path = "install_minikube.sh"
    end
  end
end
