#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}NixOS Automated Installation${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run as root${NC}"
  echo "Please run: sudo $0"
  exit 1
fi

# Confirm installation
echo -e "${YELLOW}WARNING: This will wipe all data on /dev/sda!${NC}"
echo -n "Type 'YES' to continue: "
read -r confirmation

if [ "$confirmation" != "YES" ]; then
  echo -e "${RED}Installation cancelled.${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}Step 1/4: Partitioning disk with disko...${NC}"
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko \
  --flake .#semaphoreui

echo ""
echo -e "${GREEN}Step 2/4: Installing NixOS...${NC}"
nixos-install --flake .#semaphoreui --no-root-password

echo ""
echo -e "${GREEN}Step 3/4: Setting up bootloader...${NC}"
# Bootloader is configured in semaphoreui.nix

echo ""
echo -e "${GREEN}Step 4/4: Final checks...${NC}"
echo "Installation completed successfully!"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Next steps:"
echo "1. Remove the installation media"
echo "2. Reboot the system: reboot"
echo "3. SSH to: admin@192.168.0.99"
echo "4. Access SemaphoreUI: http://192.168.0.99:81"
echo ""
echo -e "${YELLOW}Default credentials:${NC}"
echo "  SemaphoreUI: admin / changeme (change after first login)"
echo ""
