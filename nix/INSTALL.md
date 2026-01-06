# Automated Installation Guide

## Installation Workflow

This is a two-step installation process:

1. **Minimal Install** - Basic NixOS system with SSH access
2. **Host Configuration** - Apply specific host configuration via flake

## Prerequisites

1. Boot from NixOS minimal ISO
2. Network connection (DHCP or manual)
3. Git installed (usually available on minimal ISO)

### Proxmox VM Settings (Recommended)

**Use UEFI boot (this configuration is designed for it):**
- **BIOS: OVMF (UEFI)** ✓
- **Machine: q35** (recommended for UEFI)
- **Disk: SCSI** or VirtIO (must be /dev/sda or edit minimal_install.sh)
- **EFI Disk: Added** (Hardware → Add → EFI Disk)
- **CD/DVD: NixOS ISO attached**
- Memory: 4GB minimum
- CPU: 2 cores minimum

> **Note:** This configuration uses systemd-boot with UEFI. Legacy BIOS (SeaBIOS) is NOT supported.

## Installation Steps

### 1. Boot into NixOS ISO

Boot your VM from the NixOS minimal ISO.

### 2. Test network

If using DHCP (automatic):
```bash
# Usually works automatically
ping -c 3 github.com
```

### 3. Clone the repository

```bash
sudo -i
git clone https://github.com/ladislavb/homelab-bootstrap.git
cd homelab-bootstrap/nix
```

### 4. Run minimal installation

```bash
./minimal_install.sh <hostname>
```

For example, to install the semaphoreui host:
```bash
./minimal_install.sh semaphoreui
```

This will:
1. Partition the disk (UEFI/GPT)
2. Format filesystems (EFI + ext4)
3. Mount filesystems
4. Generate hardware config
5. Install minimal NixOS
6. Copy repository to /opt/homelab-bootstrap
7. Install base system

### 5. Reboot into installed system

```bash
reboot
```

Remove the ISO from the VM before reboot.

## Post-Installation

### 6. Apply host-specific configuration

After reboot, SSH into the system and apply the flake:

```bash
ssh homelab@<dhcp-ip>
sudo -i
cd /opt/homelab-bootstrap/nix

# Use 'boot' instead of 'switch' to avoid SSH disconnect during IP change
nixos-rebuild boot --flake .#semaphoreui
reboot
```

**Note:** 
- We use `boot` instead of `switch` because the flake changes the IP from DHCP to static (192.168.0.99). Using `switch` would disconnect your SSH session.
- The hardware-configuration.nix was automatically committed to git during installation.

### 7. Connect to final system

After the reboot, connect to the new static IP:

```bash
ssh homelab@<static-ip>
```
