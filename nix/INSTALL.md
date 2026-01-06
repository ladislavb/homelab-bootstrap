# Automated Installation Guide

## Prerequisites

1. Boot from NixOS minimal ISO
2. Network connection (DHCP or manual)
3. Git installed (usually available on minimal ISO)

### Proxmox VM Settings (Recommended)

**Use UEFI boot (this configuration is designed for it):**
- **BIOS: OVMF (UEFI)** ✓
- **Machine: q35** (recommended for UEFI)
- **Disk: SCSI** or VirtIO (must be /dev/sda or adjust disco.nix)
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
```

### 4. Run automated installation

```bash
cd homelab-bootstrap/nix
./install.sh
```

The script will:
1. Partition the disk with disko
2. Install NixOS with your configuration
3. Setup bootloader
4. Configure everything automatically

### 5. Reboot

```bash
reboot
```

## Post-Installation

After reboot, the system will:
- Have static IP: `192.168.0.99`
- SSH available on port 22 (key-based authentication only)
- Nginx Proxy Manager (NPM) running on http://192.168.0.99:81
- SemaphoreUI running on http://192.168.0.99 (behind NPM)

### Access the system

```bash
ssh admin@192.168.0.101
```

### Change default passwords

1. Log into SemaphoreUI (through NPM on port 81 or directly localhost:3000)
   - Username: `admin`
   - Password: `changeme`
   - **Change immediately after first login!**

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
│                     │   - /boot (512M, EFI/FAT32)
│                     │   - / (remaining, ext4)
└─────────────────────┘
    ↓
┌─────────────────────┐
│ 2. NixOS Install    │ → Install base system
│                     │   + Static IP
│                     │   + SSH config
│                     │   + Docker
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
