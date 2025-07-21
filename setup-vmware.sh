#!/bin/bash

echo "Setting up VMware Workstation environment for Vagrant..."

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    echo "Error: Vagrant is not installed. Please install Vagrant first."
    echo "Visit: https://www.vagrantup.com/downloads"
    exit 1
fi

echo "Vagrant version:"
vagrant --version

# Check if VMware Workstation is running (Linux check)
if pgrep -x "vmware" > /dev/null || pgrep -x "vmware-hostd" > /dev/null; then
    echo "VMware Workstation appears to be running."
else
    echo "Warning: VMware Workstation doesn't appear to be running."
    echo "Please ensure VMware Workstation 17 is installed and running."
fi

# Check if vagrant-vmware-desktop plugin is installed
if vagrant plugin list | grep -q "vagrant-vmware-desktop"; then
    echo "✓ vagrant-vmware-desktop plugin is already installed"
else
    echo "Installing vagrant-vmware-desktop plugin..."
    vagrant plugin install vagrant-vmware-desktop
    
    if [ $? -eq 0 ]; then
        echo "✓ VMware Desktop plugin installed successfully"
    else
        echo "✗ Failed to install VMware Desktop plugin"
        exit 1
    fi
fi

# Check if VMware Utility is installed
UTILITY_PATH="/opt/vagrant-vmware-desktop/certificates/vagrant-utility.client.crt"
if [ -f "$UTILITY_PATH" ]; then
    echo "✓ Vagrant VMware Utility is installed"
else
    echo "✗ Vagrant VMware Utility is not installed"
    echo ""
    echo "IMPORTANT: You need to install the Vagrant VMware Utility separately."
    echo "This is required for the VMware provider to work."
    echo ""
    echo "Download and install from:"
    echo "https://www.vagrantup.com/vmware/downloads"
    echo ""
    echo "For Linux, you can download the .deb/.rpm package and install it:"
    echo "- For Ubuntu/Debian: sudo dpkg -i vagrant-vmware-utility_*.deb"
    echo "- For RHEL/CentOS: sudo rpm -i vagrant-vmware-utility-*.rpm"
    echo ""
    echo "After installing the utility, run this script again."
    exit 1
fi

# Test the configuration
echo "Testing Vagrant configuration..."
vagrant validate

if [ $? -eq 0 ]; then
    echo "✓ Vagrant configuration is valid"
else
    echo "✗ Vagrant configuration validation failed"
    exit 1
fi

# List installed plugins
echo -e "\nInstalled Vagrant plugins:"
vagrant plugin list

echo -e "\n✓ Setup complete! You can now run 'vagrant up' to start your Kubernetes cluster."
echo "Note: Make sure VMware Workstation 17 is running before starting the VMs."
