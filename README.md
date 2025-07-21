# Simple Vagrant to setup K8s cluster
based on - https://exxsyseng@bitbucket.org/exxsyseng/k8s_ubuntu.git

## Prerequisites

### VMware Workstation 17 Setup
This Vagrant configuration is designed to work with VMware Workstation 17. You'll need:

1. **VMware Workstation 17** installed on your system
2. **Vagrant VMware Desktop Provider** plugin installed:
   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```
3. **Vagrant VMware Utility** installed (required for the plugin to work):
   - Download from: https://www.vagrantup.com/vmware/downloads
   - For Ubuntu/Debian: `sudo dpkg -i vagrant-vmware-utility_*.deb`
   - For RHEL/CentOS: `sudo rpm -i vagrant-vmware-utility-*.rpm`

### System Requirements
- VMware Workstation 17
- Vagrant 2.2.19 or later
- At least 4GB of available RAM (2GB for master + 1GB per worker node)
- At least 2 CPU cores available for allocation
- At least 10GB free disk space in `/DATA/VMs` for VM storage

## Usage

1. Clone this repository
2. Navigate to the project directory
3. Start the cluster:
   ```bash
   vagrant up
   ```

The setup will create:
- 1 master node (kmaster) with 2GB RAM and 2 CPUs
- 2 worker nodes (kworker1, kworker2) with 1GB RAM and 1 CPU each

## Network Configuration
- Master node: 192.168.56.100
- Worker node 1: 192.168.56.101  
- Worker node 2: 192.168.56.102

## VM Storage
- All VMs are deployed to: `/DATA/VMs`
- Each VM gets its own subdirectory with all VMware files (.vmx, .vmdk, etc.)
- VMs will appear in VMware Workstation library for easy management

## Accessing the Cluster
After the setup completes, you can access the master node:
```bash
vagrant ssh kmaster
```

The kubeconfig file will be available at `/home/vagrant/.kube/config` on the master node.