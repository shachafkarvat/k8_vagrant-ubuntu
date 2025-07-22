#!/bin/bash

# setup-host-kubectl.sh
# Script to set up kubectl access to the Vagrant Kubernetes cluster from the host machine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_DIR="$HOME/.kube"
KUBECONFIG_FILE="$KUBECONFIG_DIR/config-k8s-vagrant"
MASTER_IP="172.42.42.100"
SSH_USER="vagrant"
SSH_PASS="kubeadmin"

echo "========================================"
echo "Setting up kubectl access for Vagrant K8s cluster"
echo "========================================"

# Check if required tools are installed
command -v sshpass >/dev/null 2>&1 || {
    echo "Installing sshpass..."
    sudo apt update && sudo apt install -y sshpass
}

command -v kubectl >/dev/null 2>&1 || {
    echo "Error: kubectl is not installed. Please install kubectl first."
    echo "You can install it with: sudo apt install -y kubectl"
    exit 1
}

# Check if Vagrant cluster is running
echo "Checking if Vagrant cluster is running..."
cd "$SCRIPT_DIR"
if ! vagrant status | grep -q "running"; then
    echo "Error: Vagrant cluster is not running."
    echo "Please start the cluster with: vagrant up"
    exit 1
fi

# Check master node connectivity
echo "Testing connectivity to master node ($MASTER_IP)..."
if ! ping -c 3 "$MASTER_IP" >/dev/null 2>&1; then
    echo "Error: Cannot reach master node at $MASTER_IP"
    echo "Make sure the Vagrant cluster is properly started"
    exit 1
fi

# Wait for master node to be fully ready
echo "Waiting for master node to be ready..."
max_attempts=30
attempt=1
while ! sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$SSH_USER@$MASTER_IP" "sudo test -f /etc/kubernetes/admin.conf" 2>/dev/null; do
    echo "Attempt $attempt/$max_attempts: Master node not ready yet..."
    if [ $attempt -ge $max_attempts ]; then
        echo "Error: Master node failed to become ready after $max_attempts attempts"
        echo "Check the master node logs with: vagrant ssh kmaster -c 'sudo cat /root/kubeinit.log'"
        exit 1
    fi
    sleep 10
    ((attempt++))
done

echo "Master node is ready!"

# Create .kube directory
echo "Creating kubeconfig directory..."
mkdir -p "$KUBECONFIG_DIR"

# Extract kubeconfig from master node
echo "Extracting kubeconfig from master node..."
if ! sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$MASTER_IP" "sudo cat /etc/kubernetes/admin.conf" > "$KUBECONFIG_FILE"; then
    echo "Error: Failed to extract kubeconfig from master node"
    exit 1
fi

echo "Kubeconfig saved to: $KUBECONFIG_FILE"

# Test kubectl connectivity
echo "Testing kubectl connectivity..."
export KUBECONFIG="$KUBECONFIG_FILE"
if kubectl cluster-info >/dev/null 2>&1; then
    echo "✅ kubectl connectivity test successful!"
else
    echo "❌ kubectl connectivity test failed!"
    exit 1
fi

# Display cluster information
echo ""
echo "========================================"
echo "Cluster Information"
echo "========================================"
kubectl cluster-info
echo ""
kubectl get nodes -o wide

# Set up convenient alias
ALIAS_CMD="alias kubectl-vagrant=\"kubectl --kubeconfig=$KUBECONFIG_FILE\""
if ! grep -q "kubectl-vagrant" "$HOME/.bashrc" 2>/dev/null; then
    echo "$ALIAS_CMD" >> "$HOME/.bashrc"
    echo "Added kubectl-vagrant alias to ~/.bashrc"
fi

if ! grep -q "kubectl-vagrant" "$HOME/.zshrc" 2>/dev/null; then
    echo "$ALIAS_CMD" >> "$HOME/.zshrc"
    echo "Added kubectl-vagrant alias to ~/.zshrc"
fi

echo ""
echo "========================================"
echo "Setup Complete! 🎉"
echo "========================================"
echo ""
echo "You can now use kubectl to manage your Vagrant Kubernetes cluster in the following ways:"
echo ""
echo "1. Using environment variable:"
echo "   export KUBECONFIG=$KUBECONFIG_FILE"
echo "   kubectl get nodes"
echo ""
echo "2. Using explicit kubeconfig:"
echo "   kubectl --kubeconfig=$KUBECONFIG_FILE get nodes"
echo ""
echo "3. Using the convenience alias (after sourcing shell config):"
echo "   kubectl-vagrant get nodes"
echo ""
echo "4. To make the environment variable permanent, add this to your shell config:"
echo "   echo 'export KUBECONFIG=$KUBECONFIG_FILE' >> ~/.bashrc"
echo ""
echo "Cluster is ready for use! 🚀"
