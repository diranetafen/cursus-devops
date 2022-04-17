# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    workers=2
    config.vm.define "jenkins" do |jenkins|
      jenkins.vm.box = "geerlingguy/centos7"
      jenkins.vm.network "private_network", type: "static", ip: "192.168.99.10"
      jenkins.vm.hostname = "jenkins"
      jenkins.vm.provider "virtualbox" do |v|
        v.name = "jenkins"
        v.memory = 2048
        v.cpus = 2
      end
      jenkins.vm.provision :shell do |shell|
        shell.path = "install_jenkins.sh"
        shell.args = ["master", workers]
      end
    end
    ram_worker=2048
    cpu_worker=2
    (1..workers).each do |i|
      config.vm.define "worker#{i}" do |worker|
        worker.vm.box = "geerlingguy/centos7"
        worker.vm.network "private_network", type: "static", ip: "192.168.99.1#{i}"
        worker.vm.hostname = "worker#{i}"
        worker.vm.provider "virtualbox" do |v|
          v.name = "worker#{i}"
          v.memory = ram_worker
          v.cpus = cpu_worker
        end
        worker.vm.provision :shell do |shell|
          shell.path = "install_jenkins.sh"
          shell.args = ["worker", workers]
        end
      end
    end
  end
  