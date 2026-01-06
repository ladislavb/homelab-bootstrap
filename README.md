# Homelab Bootstrap

Automated NixOS homelab infrastructure with declarative configuration using Nix flakes.

## Concept

Two-step deployment process:

1. **Universal base** - Minimal NixOS with SSH, user, basic tools
2. **Host-specific config** - Applied via flake per machine

All configuration is declarative, version-controlled, and reproducible.

## Quick Start

```bash
# 1. Boot from NixOS ISO, clone repo
sudo -i
git clone https://github.com/ladislavb/homelab-bootstrap.git
cd homelab-bootstrap/nix
./minimal_install.sh
reboot

# 2. After reboot, apply host config
ssh homelab@<dhcp-ip>
sudo -i
cd /opt/homelab-bootstrap/nix
nixos-rebuild boot --flake .#<hostname>
reboot

# 3. Connect to final static IP
ssh homelab@<static-ip>
```

## Structure

```
nix/
├── flake.nix                         # Flake definition
├── INSTALL.md                        # Installation walkthrough
├── minimal_install.sh                # Bootstrap installer (partitions + base copy)
├── minimal/
│   └── configuration.nix             # Universal base config
└── hosts/
    ├── common/
    │   └── hardware-configuration-proxmox.nix  # Shared HW profile for Proxmox VMs
    └── semaphoreui/
        ├── configuration.nix         # Host-specific config
        └── README.md                 # Host notes
```

## Available Hosts

- **[semaphoreui](nix/hosts/semaphoreui/)** - SemaphoreUI + Nginx Proxy Manager + PostgreSQL

## Adding New Hosts

1. Create `nix/hosts/<hostname>/configuration.nix` (and optional `README.md`).
2. Register it in `nix/flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     inherit system;
     modules = [
       ./hosts/common/hardware-configuration-proxmox.nix
       ./hosts/newhost/configuration.nix
     ];
   };
   ```
3. Deploy: `nixos-rebuild switch --flake .#<newhost>`

## Requirements

- NixOS minimal ISO
- UEFI-capable VM/hardware
- Network connectivity
- SSH public key

## Documentation

- [Installation Guide](nix/INSTALL.md)
- [Host Configurations](nix/hosts/)

## License

MIT
