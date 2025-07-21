# VMware VM Storage Configuration

## ✅ Configuration Complete

The Vagrant VMs are now configured to deploy to `/DATA/VMs` instead of the default Vagrant directory.

### Storage Location Settings
- **Master Node (kmaster)**: Deployed to `/DATA/VMs`
- **Worker Nodes (kworker1, kworker2)**: Deployed to `/DATA/VMs`
- Each VM gets its own UUID-based subdirectory

### Configuration Changes Made
1. Added `v.clone_directory = "/DATA/VMs"` to all VM provider configurations
2. Updated README.md with disk space requirements and storage information
3. All VMware files (.vmx, .vmdk, .nvram, etc.) are now stored in `/DATA/VMs`

### Benefits
- ✅ **Organized Storage**: All Kubernetes VMs in one dedicated location
- ✅ **VMware Integration**: VMs appear in VMware Workstation library
- ✅ **Easy Management**: All VM files centralized for backup/maintenance
- ✅ **Performance**: Can be optimized if `/DATA/VMs` is on faster storage

### Verification
- Test VM successfully created in `/DATA/VMs`
- Display name correctly set to "kmaster"
- All VMware files properly generated
- VM boots and runs successfully
- Vagrant commands work correctly with new storage location

## Usage Examples

```bash
# Start all VMs (they will be created in /DATA/VMs)
vagrant up

# Start specific VM
vagrant up kmaster

# Check VM files location
ls -la /DATA/VMs/

# VM status
vagrant status
```

The configuration is fully tested and ready for production use!
