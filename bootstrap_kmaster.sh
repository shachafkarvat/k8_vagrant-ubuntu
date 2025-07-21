#!/bin/bash

echo "****** Setting up master node ******"
echo "Running kubeadm init"
kubeadm init --apiserver-advertise-address=192.168.56.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>&1

if [ $? -eq 0 ]; then
    echo "kubeadm init completed successfully"
else
    echo "kubeadm init failed, check /root/kubeinit.log for details"
    exit 1
fi

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown vagrant:vagrant $HOME/.kube/config

# Wait for the API server to be ready
echo "Waiting for API server to be ready..."
while ! kubectl get nodes >/dev/null 2>&1; do
    echo "Waiting for API server..."
    sleep 5
done

# Deploy network plugin (using Calico instead of Weave)
echo "Deploying Calico network plugin..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Generate Cluster join command
echo "Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh