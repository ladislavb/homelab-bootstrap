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
cd /opt/homelab-bootstrap/nix
sudo nixos-rebuild boot --flake .#<hostname>
sudo reboot

# 3. Connect to final static IP
ssh homelab@<static-ip>
```

## Structure

```
nix/
├── flake.nix              # Flake definition
├── minimal/
│   └── configuration.nix  # Universal base config
├── hosts/
│   └── <hostname>.nix     # Host-specific configs
└── minimal_install.sh     # Bootstrap installer
```

## Available Hosts

- **[semaphoreui](nix/hosts/)** - SemaphoreUI + Nginx Proxy Manager + PostgreSQL

## Adding New Hosts

1. Create `nix/hosts/newhost.nix`
2. Add to `nix/flake.nix`:
   ```nix
   nixosConfigurations.newhost = nixpkgs.lib.nixosSystem {
     inherit system;
     modules = [ ./hosts/newhost.nix ];
   };
   ```
3. Deploy: `nixos-rebuild switch --flake .#newhost`

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
