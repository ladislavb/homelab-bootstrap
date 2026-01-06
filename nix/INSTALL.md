# Automated Installation Guide

## Prerequisites

1. Boot from NixOS minimal ISO
2. Network connection (DHCP or manual)
3. Git installed (usually available on minimal ISO)

### Proxmox VM Settings (Recommended)

**Use legacy BIOS (this configuration is designed for it):**
- **BIOS: SeaBIOS (default)** ✓
- **Machine: i440fx** or q35
- **Disk: SCSI** or VirtIO (must be /dev/sda or adjust disco.nix)
- **CD/DVD: NixOS ISO attached**
- Memory: 4GB minimum
- CPU: 2 cores minimum

> **Note:** This configuration uses GRUB on legacy BIOS. UEFI/OVMF is NOT needed and can cause boot issues with ISO in Proxmox.

## Installation Steps

### 1. Boot into NixOS ISO

Boot your VM from the NixOS minimal ISO.

### 2. Setup network (if needed)

If using DHCP (automatic):
```bash
# Usually works automatically
ping -c 3 github.com
```

If using static IP (manual):
```bash
ip addr add 192.168.0.100/24 dev ens18
ip route add default via 192.168.0.1
echo "nameserver 192.168.0.1" > /etc/resolv.conf
```

### 3. Clone the repository

```bash
nix-shell -p git
git clone https://github.com/ladislavb/homelab-bootstrap.git
cd homelab-bootstrap/nix
```

### 4. (Optional) Customize disk device

If your disk is not `/dev/sda`, edit `disco.nix`:
```bash
nano disco.nix
# Change: device = "/dev/sda"; to your disk (e.g., /dev/vda, /dev/nvme0n1)
```

### 5. Run automated installation

```bash
sudo bash install.sh
```

The script will:
1. Partition the disk with disko
2. Install NixOS with your configuration
3. Setup bootloader
4. Configure everything automatically

### 6. Reboot

```bash
reboot
```

## Post-Installation

After reboot, the system will:
- Have static IP: `192.168.0.101`
- SSH available on port 22 (key-based authentication only)
- SemaphoreUI running on http://localhost:3000 (behind NPM)
- Nginx Proxy Manager on ports 80, 443, 81

### Access the system

```bash
ssh admin@192.168.0.101
```

### Change default passwords

1. Log into SemaphoreUI (through NPM on port 81 or directly localhost:3000)
   - Username: `admin`
   - Password: `changeme`
   - **Change immediately after first login!**

## Troubleshooting

### ISO won't boot with OVMF (UEFI)

**Solution:** Use SeaBIOS instead. The current configuration is designed for legacy BIOS.

In Proxmox:
1. Shut down VM
2. Hardware → BIOS → Change to **SeaBIOS**
3. Remove EFI Disk if added
4. Ensure CD/DVD drive is attached with ISO
5. Boot order: CD/DVD first, then disk
6. Start VM and boot from ISO

### VM not booting after installation

### Check disk device name
```bash
lsblk
```

### Manual disko partitioning
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake .#semaphoreui
```

### Manual NixOS install
```bash
nixos-install --flake .#semaphoreui --no-root-password
```

### View installation logs
```bash
journalctl -xe
```

## Architecture

```
minimal ISO
    ↓
git clone repo
    ↓
./install.sh
    ↓
┌─────────────────────┐
│ 1. Disko            │ → Partition /dev/sda (GPT)
│                     │   - BIOS boot (1M, EF02)
│                     │   - / (remaining, ext4)
└─────────────────────┘
    ↓
┌─────────────────────┐
│ 2. NixOS Install    │ → Install base system
│                     │   + Docker
│                     │   + SSH config
│                     │   + Static IP
└─────────────────────┘
    ↓
┌─────────────────────┐
│ 3. Docker Containers│ → PostgreSQL
│                     │   SemaphoreUI
│                     │   Nginx Proxy Manager
└─────────────────────┘
    ↓
   Reboot → Ready!
```
