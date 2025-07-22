# Kubernetes Vagrant Cluster - Ubuntu 24.04

A Vagrant-based Kubernetes cluster setup using Ubuntu 24.04 LTS with security best practices and modern configurations.

## Features

- **Ubuntu 24.04 LTS**: Latest stable Ubuntu release
- **Kubernetes 1.32**: Latest stable Kubernetes version
- **Calico CNI**: Modern Container Network Interface with the latest version
- **Security Best Practices**: 
  - Pod Security Standards enabled
  - Secure SSH configuration (no root password login)
  - Container security configurations
  - Audit logging enabled on API server
- **Modern Container Runtime**: Containerd with proper CRI configuration
- **Auto-completion**: kubectl bash completion and aliases pre-configured

## Cluster Architecture

- **Master Node (kmaster)**: 2GB RAM, 2 vCPUs - IP: 172.42.42.100
- **Worker Nodes (kworker1, kworker2)**: 1GB RAM, 1 vCPU each - IPs: 172.42.42.101, 172.42.42.102

## Prerequisites

- Vagrant installed
- Libvirt provider configured
- At least 4GB of available RAM

## Usage

### Quick Start
```bash
# Start the cluster
vagrant up

# Set up kubectl access from host (after cluster is ready)
./setup-host-kubectl.sh

# Use kubectl from host
kubectl-vagrant get nodes
# OR
export KUBECONFIG=~/.kube/config-k8s-vagrant
kubectl get nodes
```

### Manual Steps
```bash
# SSH to master node
vagrant ssh kmaster

# SSH to worker nodes
vagrant ssh kworker1
vagrant ssh kworker2

# Check cluster status (from master node)
kubectl get nodes -o wide
kubectl cluster-info

# Destroy the cluster
vagrant destroy -f
```

## Host CLI Setup

The `setup-host-kubectl.sh` script automatically configures kubectl access from your host machine:

### Features:
- ✅ Automatically extracts kubeconfig from master node
- ✅ Tests connectivity and cluster status
- ✅ Sets up convenient aliases (`kubectl-vagrant`)
- ✅ Provides multiple usage options
- ✅ Error handling and validation
- ✅ Works with existing kubectl installations

### Requirements:
- Vagrant cluster must be running (`vagrant up`)
- `sshpass` utility (auto-installed if missing)
- `kubectl` binary installed on host

### Usage Options After Setup:
```bash
# Option 1: Using environment variable
export KUBECONFIG=~/.kube/config-k8s-vagrant
kubectl get nodes

# Option 2: Using explicit config file
kubectl --kubeconfig=~/.kube/config-k8s-vagrant get nodes

# Option 3: Using convenient alias
kubectl-vagrant get nodes
```

## Security Notes

- Root SSH access is disabled for security
- Inter-node communication uses vagrant user with sudo privileges
- Pod Security Standards are enforced
- API server audit logging is enabled
- Container security configurations are applied

## Troubleshooting

- Check `/root/kubeinit.log` on master for initialization logs
- Verify all nodes are ready: `kubectl get nodes`
- Check pod status: `kubectl get pods --all-namespaces`

Based on: https://exxsyseng@bitbucket.org/exxsyseng/k8s_ubuntu.git

