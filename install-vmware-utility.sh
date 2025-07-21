#!/bin/bash

# VMware Utility installer for Vagrant
echo "Installing Vagrant VMware Utility..."

# Detect OS
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Please install manually from https://www.vagrantup.com/vmware/downloads"
    exit 1
fi

# Get the latest version
LATEST_VERSION=$(curl -s https://releases.hashicorp.com/vagrant-vmware-utility/ | grep -oP '\d+\.\d+\.\d+' | head -1)
echo "Latest version: $LATEST_VERSION"

# Determine architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    i386|i686) ARCH="386" ;;
    aarch64) ARCH="arm64" ;;
    *) 
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Create temp directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

case $OS in
    ubuntu|debian)
        PACKAGE_FILE="vagrant-vmware-utility_${LATEST_VERSION}-1_${ARCH}.deb"
        DOWNLOAD_URL="https://releases.hashicorp.com/vagrant-vmware-utility/${LATEST_VERSION}/${PACKAGE_FILE}"
        
        echo "Downloading $PACKAGE_FILE..."
        curl -LO "$DOWNLOAD_URL"
        
        if [[ -f "$PACKAGE_FILE" ]]; then
            echo "Installing with dpkg..."
            sudo dpkg -i "$PACKAGE_FILE"
            
            # Fix any dependency issues
            sudo apt-get install -f -y
            
            echo "✓ Vagrant VMware Utility installed successfully"
        else
            echo "✗ Failed to download package"
            exit 1
        fi
        ;;
    
    centos|rhel|fedora)
        PACKAGE_FILE="vagrant-vmware-utility-${LATEST_VERSION}-1.${ARCH}.rpm"
        DOWNLOAD_URL="https://releases.hashicorp.com/vagrant-vmware-utility/${LATEST_VERSION}/${PACKAGE_FILE}"
        
        echo "Downloading $PACKAGE_FILE..."
        curl -LO "$DOWNLOAD_URL"
        
        if [[ -f "$PACKAGE_FILE" ]]; then
            echo "Installing with rpm/yum..."
            if command -v dnf &> /dev/null; then
                sudo dnf install -y "$PACKAGE_FILE"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "$PACKAGE_FILE"
            else
                sudo rpm -i "$PACKAGE_FILE"
            fi
            
            echo "✓ Vagrant VMware Utility installed successfully"
        else
            echo "✗ Failed to download package"
            exit 1
        fi
        ;;
    
    *)
        echo "Unsupported OS: $OS"
        echo "Please install manually from https://www.vagrantup.com/vmware/downloads"
        exit 1
        ;;
esac

# Clean up
cd /
rm -rf "$TEMP_DIR"

# Start and enable the service
echo "Starting Vagrant VMware Utility service..."
sudo systemctl enable vagrant-vmware-utility
sudo systemctl start vagrant-vmware-utility
sudo systemctl status vagrant-vmware-utility --no-pager

echo ""
echo "✓ Installation complete!"
echo "You can now run './setup-vmware.sh' to validate your setup."
