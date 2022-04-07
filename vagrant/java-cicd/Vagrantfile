# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "jenkins" do |jenkins|
    jenkins.vm.box = "geerlingguy/centos7"
    jenkins.vm.network "private_network", type: "dhcp"
    jenkins.vm.hostname = "jenkins"
    jenkins.vm.provider "virtualbox" do |v|
      v.name = "jenkins"
      v.memory = 2048
      v.cpus = 2
    end
    jenkins.vm.provision :shell do |shell|
      shell.path = "install_jenkins.sh"
    end
  end
end
