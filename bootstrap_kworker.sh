#!/bin/bash

echo "****** Setting up worker node ****** "

# Wait for master node to be ready
echo "Waiting for master node to be ready..."
max_ping_attempts=60
ping_attempt=1
while ! ping -c 1 kmaster.firefly.local >/dev/null 2>&1; do
    echo "Ping attempt $ping_attempt/$max_ping_attempts: Waiting for master node..."
    if [ $ping_attempt -ge $max_ping_attempts ]; then
        echo "ERROR: Master node not reachable after $max_ping_attempts attempts"
        exit 1
    fi
    sleep 5
    ((ping_attempt++))
done
echo "Master node is reachable!"

echo "Installing sshpass"
apt-get update -y
apt-get install -y sshpass >/dev/null 2>&1

echo "Waiting for join script to be available on master..."
max_join_attempts=60
for i in $(seq 1 $max_join_attempts); do
    if sshpass -p "kubeadmin" ssh -o StrictHostKeyChecking=no vagrant@kmaster.firefly.local "sudo test -f /joincluster.sh"; then
        echo "Join script found on master node!"
        break
    fi
    echo "Attempt $i/$max_join_attempts: Join script not ready, waiting..."
    if [ $i -ge $max_join_attempts ]; then
        echo "ERROR: Join script not available on master after $max_join_attempts attempts"
        exit 1
    fi
    sleep 10
done

echo "Copying join script from master"
sshpass -p "kubeadmin" ssh -o StrictHostKeyChecking=no vagrant@kmaster.firefly.local "sudo cat /joincluster.sh" > /joincluster.sh

if [ ! -f /joincluster.sh ]; then
    echo "Failed to copy join script from master"
    exit 1
fi

echo "*** Joining $(hostname) to cluster ***"
chmod +x /joincluster.sh
if bash /joincluster.sh; then
    echo "Successfully joined cluster"
else
    echo "Failed to join cluster"
    exit 1
fi

# Install kubectl completion for bash on worker nodes too
echo "Setting up kubectl completion and aliases on worker node"
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
echo 'alias k=kubectl' >> /home/vagrant/.bashrc
echo 'complete -o default -F __start_kubectl k' >> /home/vagrant/.bashrc

# Create completion marker
touch /tmp/k8s-worker-setup-complete
echo "Worker node $(hostname) setup completed successfully at $(date)"