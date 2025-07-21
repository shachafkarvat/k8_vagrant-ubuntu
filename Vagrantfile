# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# Master
Vagrant.configure(2) do |config|
  
  # Disable the default synced folder to avoid OneDrive mount issues
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  config.vm.provision "shell", path: "bootstrap_common.sh"

  config.vm.define "kmaster" do |kmaster|
    kmaster.vm.box = "bento/ubuntu-20.04"
    kmaster.vm.hostname = "kmaster.firefly.local"
    kmaster.vm.network "private_network", ip: "192.168.56.100"
    # Removed public_network to avoid manual interface selection
    kmaster.vm.provider "vmware_desktop" do |v|
      v.vmx["displayname"] = "kmaster"
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      # Enable VMware Tools for better integration
      v.vmx["tools.syncTime"] = "TRUE"
      v.vmx["tools.upgrade.policy"] = "upgradeAtPowerCycle"
      # Disable linked clones to avoid snapshot issues
      v.linked_clone = false
      # Set VM storage location
      v.clone_directory = "/DATA/VMs"
      # Show GUI in VMware Workstation (set to false if running headless)
      v.gui = false  # Change to true if you want GUI windows
      # Ensure VM appears in VMware Workstation library
      v.vmx["isolation.tools.unity.disable"] = "FALSE"
      v.vmx["unity.allowCompositingInGuest"] = "TRUE"
      # Make sure VM is manageable from VMware Workstation
      v.vmx["isolation.tools.hgfs.disable"] = "FALSE"
    end
    kmaster.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end
  
  NodeCount = 2
  
  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker#{i}" do |workernode|
      workernode.vm.box = "bento/ubuntu-20.04"
      workernode.vm.hostname = "kworker#{i}.firefly.local"
      workernode.vm.network "private_network", ip: "192.168.56.10#{i}"
      # Removed public_network to avoid manual interface selection
      workernode.vm.provider "vmware_desktop" do |v|
        v.vmx["displayname"] = "kworker#{i}"
        v.vmx["memsize"] = "1024"
        v.vmx["numvcpus"] = "1"
        # Enable VMware Tools for better integration
        v.vmx["tools.syncTime"] = "TRUE"
        v.vmx["tools.upgrade.policy"] = "upgradeAtPowerCycle"
        # Disable linked clones to avoid snapshot issues
        v.linked_clone = false
        # Set VM storage location
        v.clone_directory = "/DATA/VMs"
        # Show GUI in VMware Workstation (set to false if running headless)
        v.gui = false  # Change to true if you want GUI windows
        # Ensure VM appears in VMware Workstation library
        v.vmx["isolation.tools.unity.disable"] = "FALSE"
        v.vmx["unity.allowCompositingInGuest"] = "TRUE"
        # Make sure VM is manageable from VMware Workstation
        v.vmx["isolation.tools.hgfs.disable"] = "FALSE"
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
    end
  end
end
