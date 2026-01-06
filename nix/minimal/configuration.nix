{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ---------------- BOOT (UEFI) ----------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------------- NETWORK ----------------
  # hostname is set per-host in hosts/*.nix
  networking.useDHCP = true;

  # ---------------- TIME ----------------
  time.timeZone = "Europe/Prague";

  # ---------------- SSH ----------------
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # ---------------- USER ----------------
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # SSH PUBLIC KEY
      # "ssh-ed25519 AAAA...REPLACE_ME"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOTm0wfJpY+JLZ7qIBGYjQxx5YqLL0VkBiXg8ZZxQ6yqD7YBfVNJXT1zxOvf6unUTB0Ur+R2RFXDP8/hJdyDhHpoyv2IcvBYOsk91xjU7HzKsqLgS+9Tf+QUIUCHK/7orXMjP8VUCw6DRZr50TTD2om9GwdKyJOXFiSypClPp6T25Qld036dNVyyYvYKVLdbP5ADgtLRigv4xK6MXHhf6fFQqvdNaB6eBvcupL3ijXZ5LiWliwcRaqUy6RRSulTSRFrN9EfxCEdcy4D4RNJuxlPzX96fV3ZmeLBx7K6EPRLFSXyrKuom9omO9Dcd7Mt5Y4QIpXc6iW7RccAXGE4s8UiGceyqItjRRaMlLi+yQn+VNeApnwvXGQLTDrsh45Nfc/TNlvP37xH3cSmNH8GwYJ+W6eapCzeA7tsAZo1F9wRYzgqk2GpFaUb/y2bREWf0WLPsw8REmCpEZ0+KkVcT7UD34uD5imXlVkHvvxYMpxuBDbaOPcVLqDEbaH7G3TySM="
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # ---------------- BASIC TOOLS ----------------
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
  ];

  # ---------------- PROXMOX HELPERS ----------------
  services.qemuGuest.enable = true;

  # ---------------- NIX ----------------
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ---------------- REQUIRED ----------------
  system.stateVersion = "25.11";
}
