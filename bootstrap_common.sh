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
apt-get upgrade
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "[ add account to the docker group ]"
usermod -aG docker vagrant

# Set up the Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
echo "Create /etc/systemd/system/docker.service.d"
mkdir -p /etc/systemd/system/docker.service.d
ls -l /etc/systemd/system/docker.service.d

# Enable docker service
echo "[ Enable and start docker service ]"
systemctl enable docker >/dev/null 2>&1
systemctl restart docker

echo "------> Letting iptables see bridged traffic <------"
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[ Disable swap ]"
echo "------> Disable and turn off SWAP <------"
sed -i '/swap/d' /etc/fstab
swapoff -a
echo "============> end prerequisites <============"

echo "============> Install kubadm, kubectl & kublet <============"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -y
apt-get install -y kubelet kubeadm kubectl 
apt-mark hold kubelet kubeadm kubectl kubernetes-cni

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl enable kubelet >/dev/null 2>&1
systemctl start kubelet >/dev/null 2>&1

echo "============> End install kubadm, kubectl & kublet <============"


# Enable ssh password authentication
echo "============> Enable ssh password authentication <============"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Set Root password
echo "============> Set root password <============"
echo -e "kubeadmin\nkubeadmin" | passwd root
#echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc