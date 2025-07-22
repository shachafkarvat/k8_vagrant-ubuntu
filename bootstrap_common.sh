#!/bin/bash

# update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.42.42.100 kmaster.firefly.local kmaster
172.42.42.101 kworker1.firefly.local kworker1
172.42.42.102 kworker2.firefly.local kworker2
EOF

echo "==============> Prerequisite <============== "
echo "[ Install Docker ]"
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

# Add Docker's official GPG key (updated method)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "[ add account to the docker group ]"
usermod -aG docker vagrant

# Set up the Docker daemon with security best practices
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF
echo "Create /etc/systemd/system/docker.service.d"
mkdir -p /etc/systemd/system/docker.service.d
ls -l /etc/systemd/system/docker.service.d

# Configure containerd for Kubernetes with CRI
echo "[ Configure containerd for Kubernetes ]"
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Enable SystemdCgroup and configure runc
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml

# Disable disabled_plugins for CRI
sed -i 's/disabled_plugins/#disabled_plugins/' /etc/containerd/config.toml

# Enable docker service
echo "[ Enable and start docker service ]"
systemctl enable docker >/dev/null 2>&1
systemctl restart docker

# Restart containerd with new config
echo "[ Restart containerd with Kubernetes config ]"
systemctl restart containerd

echo "------> Letting iptables see bridged traffic <------"
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
# Load required kernel modules
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Set required sysctl parameters for Kubernetes
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

echo "[ Disable swap ]"
echo "------> Disable and turn off SWAP <------"
sed -i '/swap/d' /etc/fstab
swapoff -a
echo "============> end prerequisites <============"

echo "============> Install kubadm, kubectl & kublet <============"

# Add Kubernetes signing key and repository (updated method for latest version)
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl 
apt-mark hold kubelet kubeadm kubectl

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
systemctl start kubelet >/dev/null 2>&1

echo "============> End install kubadm, kubectl & kublet <============"


# Enable ssh password authentication for vagrant user only
echo "============> Configure SSH for automation <============"
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# Keep root login disabled for security, only allow key-based access
sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd

# Set up inter-node communication via vagrant user
echo "============> Configure vagrant user for cluster communication <============"
# Allow vagrant user to sudo without password for cluster operations
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/vagrant-nopasswd

# Set a password for vagrant user for ssh automation
echo -e "kubeadmin\nkubeadmin" | passwd vagrant

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc