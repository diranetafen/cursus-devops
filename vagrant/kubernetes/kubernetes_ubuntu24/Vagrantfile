# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Nombre de workers
  workers = 1
  ram_worker = 2048
  cpu_worker = 2

  # Master
  config.vm.define "master" do |master|
    master.vm.box = "eazytraining/ubuntu24"
    master.vm.box_version = "1.0"
    master.vm.network "private_network", ip: "192.168.99.10"
    master.vm.hostname = "master"

    master.vm.provider "virtualbox" do |v|
      v.name = "master"
      v.memory = 2048
      v.cpus = 2
    end

    master.vm.provision "shell" do |s|
      s.path = "install_kubernetes.sh"
      s.args = ["master", "192.168.99.10"]
    end
  end

  # Workers
  (1..workers).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.box = "eazytraining/ubuntu24"
      worker.vm.box_version = "1.0"
      worker.vm.network "private_network", ip: "192.168.99.1#{i}"
      worker.vm.hostname = "worker#{i}"

      worker.vm.provider "virtualbox" do |v|
        v.name = "worker#{i}"
        v.memory = ram_worker
        v.cpus = cpu_worker
      end

      worker.vm.provision "shell" do |s|
        s.path = "install_kubernetes.sh"
        s.args = ["worker", "192.168.99.10"]
      end
    end
  end
end
