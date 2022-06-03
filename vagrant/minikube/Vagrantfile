# -*- mode: ruby -*-
# vi: set ft=ruby :
# To enable zsh, please set ENABLE_ZSH env var to "true" before launching vagrant up 
#   + On windows => $env:ENABLE_ZSH="true"
#   + On Linux  => export ENABLE_ZSH="true

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
      shell.env = { 'ENABLE_ZSH' => ENV['ENABLE_ZSH'] }
    end
  end
end
