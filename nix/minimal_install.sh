#!/usr/bin/env bash
# Minimal NixOS installation script for UEFI systems.

set -euo pipefail

DISK="/dev/sda"
MOUNT="/mnt"

echo "=== Preflight: unmounting /mnt and disabling swap (if any) ==="
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

echo "=== Preflight: wiping old signatures ==="
wipefs -a /dev/sda || true

echo "=== [1/7] Partitioning disk $DISK (UEFI) ==="
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 513MiB 100%

echo "=== [2/7] Formatting partitions ==="
mkfs.fat -F32 -n boot "${DISK}1"
mkfs.ext4 -F -L nixos "${DISK}2"

echo "=== [3/7] Mounting filesystems ==="
mount "${DISK}2" "$MOUNT"
mkdir -p "$MOUNT/boot"
mount "${DISK}1" "$MOUNT/boot"

echo "=== [4/7] Generating hardware config ==="
nixos-generate-config --root "$MOUNT"

echo "=== [5/7] Installing minimal NixOS config ==="
mkdir -p "$MOUNT/etc/nixos"
cp "./minimal/configuration.nix" "$MOUNT/etc/nixos/configuration.nix"

echo "=== [6/7] Copying repo to installed system ==="
mkdir -p "$MOUNT/opt"
cp -r "$(pwd)/../.." "$MOUNT/opt/"
echo "Repository copied to /opt/homelab-bootstrap"

echo "=== [7/7] Installing NixOS ==="
nixos-install --no-root-passwd

echo "=== DONE ==="
echo ""
echo "Repository is available at: /opt/homelab-bootstrap"
echo ""
echo "Next steps:"
echo "1. reboot"
echo "2. ssh admin@<ip-address>"
echo "3. cd /opt/homelab-bootstrap/nix"
echo "4. sudo nixos-rebuild switch --flake .#semaphoreui"
