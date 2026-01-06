# Shared hardware configuration for Proxmox VMs
# This configuration is common across all Proxmox VM hosts using:
# - UEFI boot
# - SCSI/VirtIO disk
# - Labeled filesystems (boot, nixos)

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Kernel modules for Proxmox virtual hardware
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Root filesystem using label (device-independent)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Boot partition using label (device-independent)
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # No swap configured
  swapDevices = [ ];

  # Default platform for Proxmox VMs
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
