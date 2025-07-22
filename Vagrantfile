# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# Master
Vagrant.configure(2) do |config|
  
  # Disable the default synced folder to avoid mount issues
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Use a stable box with consistent networking
  config.vm.box_check_update = false
  
  # Common provisioning for all nodes
  config.vm.provision "shell", path: "bootstrap_common.sh"

  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = "generic/ubuntu2204"
    kmaster.vm.hostname = "kmaster.firefly.local"
    kmaster.vm.network "private_network", ip: "172.42.42.100"
    # Removed public_network to avoid manual interface selection
    kmaster.vm.provider "libvirt" do |v|
      v.memory = 2048
      v.cpus = 2
    end
    kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end
  
  NodeCount = 2
  
  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box = "generic/ubuntu2204"
      workernode.vm.hostname = "kworker#{i}.firefly.local"
      workernode.vm.network "private_network", ip: "172.42.42.10#{i}"
      # Removed public_network to avoid manual interface selection
      workernode.vm.provider "libvirt" do |v|
        v.memory = 1024
        v.cpus = 1
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
    end
  end
end
