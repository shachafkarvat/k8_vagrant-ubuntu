#!/bin/bash

echo "****** Setting up master node ******"

# Create kubeadm configuration file with security best practices
cat > /root/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 172.42.42.100
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  kubeletExtraArgs:
    cgroup-driver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.32.0
controlPlaneEndpoint: 172.42.42.100:6443
networking:
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
apiServer:
  extraArgs:
    audit-log-maxage: "30"
    audit-log-maxbackup: "3"
    audit-log-maxsize: "100"
    audit-log-path: /var/log/kube-apiserver-audit.log
    enable-admission-plugins: NodeRestriction,ResourceQuota
controllerManager:
  extraArgs:
    bind-address: 0.0.0.0
scheduler:
  extraArgs:
    bind-address: 0.0.0.0
etcd:
  local:
    extraArgs:
      listen-metrics-urls: http://0.0.0.0:2381
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
serverTLSBootstrap: true
EOF

echo "Running kubeadm init with configuration file"
kubeadm init --config=/root/kubeadm-config.yaml >> /root/kubeinit.log 2>&1

if [ $? -eq 0 ]; then
    echo "kubeadm init completed successfully"
else
    echo "kubeadm init failed, check /root/kubeinit.log for details"
    exit 1
fi

# Setup kubeconfig for vagrant user and root
echo "Setting up kubeconfig for vagrant user..."
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
chmod 600 /home/vagrant/.kube/config

# Also setup for root user
echo "Setting up kubeconfig for root user..."
mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config

# Verify kubeconfig setup
echo "Verifying kubeconfig setup..."
su - vagrant -c "kubectl version --client" || echo "Warning: kubectl client check failed"

# Wait for the API server to be ready
echo "Waiting for API server to be ready..."
max_attempts=30
attempt=1
while ! su - vagrant -c "kubectl get nodes" >/dev/null 2>&1; do
    echo "Attempt $attempt/$max_attempts: Waiting for API server..."
    if [ $attempt -ge $max_attempts ]; then
        echo "ERROR: API server failed to become ready after $max_attempts attempts"
        echo "Check /root/kubeinit.log for details"
        exit 1
    fi
    sleep 10
    ((attempt++))
done
echo "API server is ready!"

# Deploy network plugin (using latest Calico)
echo "Deploying Calico network plugin..."
su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml"

# Wait for Calico pods to be ready
echo "Waiting for Calico pods to be ready..."
su - vagrant -c "kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s"
su - vagrant -c "kubectl wait --for=condition=ready pod -l k8s-app=calico-kube-controllers -n kube-system --timeout=300s"

# Generate Cluster join command
echo "Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh
chmod +x /joincluster.sh

# Make join command available for host access (for debugging)
cp /joincluster.sh /vagrant/joincluster.sh 2>/dev/null || echo "Note: /vagrant mount not available"

# Install kubectl completion for bash
echo "Setting up kubectl completion and aliases..."
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'alias k=kubectl' >> /home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/vagrant/.bashrc

# Also add to root's bashrc
echo 'source <(kubectl completion bash)' >> /root/.bashrc
echo 'alias k=kubectl' >> /root/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /root/.bashrc

# Create a simple pod security policy
echo "Setting up basic pod security standards"
su - vagrant -c "kubectl label --overwrite ns kube-system pod-security.kubernetes.io/enforce=privileged"
su - vagrant -c "kubectl label --overwrite ns kube-system pod-security.kubernetes.io/audit=privileged"
su - vagrant -c "kubectl label --overwrite ns kube-system pod-security.kubernetes.io/warn=privileged"

# Show cluster info
echo "Cluster setup complete. Cluster info:"
su - vagrant -c "kubectl cluster-info"
su - vagrant -c "kubectl get nodes -o wide"

# Create a marker file to indicate successful completion
touch /tmp/k8s-master-setup-complete
echo "Master node setup completed successfully at $(date)"