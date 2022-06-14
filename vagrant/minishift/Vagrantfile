# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "openshift" do |openshift|
    openshift.vm.disk :disk, size: "50GB", primary: true
    openshift.vm.box = "geerlingguy/centos7"
    openshift.vm.network "private_network", type: "static", ip: "192.168.99.11"
    openshift.vm.hostname = "openshift"
    openshift.vm.provider "virtualbox" do |v|
      v.name = "openshift"
      v.memory = 4096
      v.cpus = 2
    end
    openshift.vm.provision "file", source: "minishift.key.pub", destination: "/home/vagrant/.ssh/minishift.key.pub"
    openshift.vm.provision "shell", inline: <<-SHELL
      cat /home/vagrant/.ssh/minishift.key.pub >> /home/vagrant/.ssh/authorized_keys
      SHELL
    openshift.vm.provision :shell do |shell|
      shell.path = "install_minishift.sh"
      shell.args = ["openshift", "192.168.99.11"]
    end
  end
  config.vm.define "minishift" do |minishift|
    minishift.vm.box = "geerlingguy/centos7"
    minishift.vm.network "private_network", type: "static", ip: "192.168.99.10"
    minishift.vm.hostname = "minishift"
    minishift.vm.provider "virtualbox" do |v|
        v.name = "minishift"
        v.memory = 1024
        v.cpus = 1
      end
      minishift.vm.provision "file", source: "minishift.key", destination: "/home/vagrant/.ssh/minishift.key"
    minishift.vm.provision :shell do |shell|
      shell.path = "install_minishift.sh"
      shell.args = ["minishift", "192.168.99.11"]
    end
  end
end