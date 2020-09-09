# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# Master
Vagrant.configure(2) do |config|
  
  config.vm.provision "shell", path: "bootstrap_common.sh"

  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = "bento/ubuntu-20.04"
    kmaster.vm.hostname = "kmaster.firefly.local"
    kmaster.vm.network "private_network", ip: "172.42.42.100"
    kmaster.vm.network "public_network"
    kmaster.vm.provider "virtualbox" do |v|
      v.name = "kmaster"
      v.memory = 2048
      v.cpus = 2
    end
    kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end
  
  NodeCount = 2
  
  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box = "bento/ubuntu-20.04"
      workernode.vm.hostname = "kworker#{i}.firefly.local"
      workernode.vm.network "private_network", ip: "172.42.42.10#{i}"
      workernode.vm.network "public_network"
      workernode.vm.provider "virtualbox" do |v|
        v.name = "kworker#{i}"
        v.memory = 1024
        v.cpus = 1
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
    end
  end
end
