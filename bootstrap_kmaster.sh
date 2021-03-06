#!/bin/bash

echo "****** Setting up master node ******"
echo "Running kubeadm init"
kubeadm init --apiserver-advertise-address=172.42.42.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown vagrant:vagrant $HOME/.kube/config

# Deploy network plugin
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.WEAVE_MTU=1337"

# Generate Cluster join command
echo "Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh