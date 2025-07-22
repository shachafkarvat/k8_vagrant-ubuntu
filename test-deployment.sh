#!/bin/bash

# test-deployment.sh
# Quick test script to verify the Vagrant Kubernetes deployment

set -e

echo "========================================"
echo "Testing Vagrant Kubernetes Deployment"
echo "========================================"

# Check if we're in the right directory
if [[ ! -f "Vagrantfile" ]]; then
    echo "Error: Vagrantfile not found. Please run this script from the vagrant project directory."
    exit 1
fi

echo "1. Checking Vagrant status..."
vagrant status

echo ""
echo "2. Testing master node SSH and kubectl..."
if vagrant ssh kmaster -c "kubectl get nodes" 2>/dev/null; then
    echo "✅ Master node kubectl is working!"
else
    echo "❌ Master node kubectl test failed!"
fi

echo ""
echo "3. Testing worker node SSH..."
if vagrant ssh kworker1 -c "echo 'Worker 1 SSH OK'" 2>/dev/null; then
    echo "✅ Worker 1 SSH is working!"
else
    echo "❌ Worker 1 SSH test failed!"
fi

if vagrant ssh kworker2 -c "echo 'Worker 2 SSH OK'" 2>/dev/null; then
    echo "✅ Worker 2 SSH is working!"
else
    echo "❌ Worker 2 SSH test failed!"
fi

echo ""
echo "4. Testing host kubectl setup script..."
if [[ -x "./setup-host-kubectl.sh" ]]; then
    echo "✅ setup-host-kubectl.sh is executable"
    echo "Run './setup-host-kubectl.sh' to set up host kubectl access"
else
    echo "❌ setup-host-kubectl.sh is not executable"
fi

echo ""
echo "========================================"
echo "Test Complete!"
echo "========================================"
