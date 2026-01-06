{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../minimal/configuration.nix
  ];

  # Hardware configuration (adjust as needed)
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.hostName = "semaphoreui";

  # Extend homelab user with docker group
  users.users.homelab.extraGroups = [ "wheel" "docker" ];

  # Static IP
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."management" = {
    matchConfig.Name = "en*";
    networkConfig = {
      Address = "192.168.0.99/24";
      Gateway = "192.168.0.1";
      DNS = "192.168.0.1";
    };
  };

  # Firewall - TCP 22 + 80, 443 + 81 (NPM Admin)
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 81 443 ]; # Optional: limit NPM admin UI exposure (port 81) later via firewall rules.

  # Nix basics
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  # Persist dirs (survives rebuilds)
  systemd.tmpfiles.rules = [
    "d /opt/docker4u 0750 admin docker -"
    "d /opt/docker4u/npm-data 0750 admin docker -"
    "d /opt/docker4u/npm-letsencrypt 0750 admin docker -"
    "d /opt/docker4u/semaphoreui 0750 admin docker -"
    "d /opt/docker4u/postgres 0750 admin docker -"
    "d /opt/docker4u/secrets 0700 root root -"
  ];

  # Docker network for internal comms
  systemd.services."docker-create-docker4u-net" = {
    description = "Create docker network for IaC stack";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect docker4u >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create docker4u
    '';
  };

  # Auto-generate postgres password on first run
  systemd.services."generate-postgres-password" = {
    description = "Generate postgres password if it doesn't exist";
    wantedBy = [ "multi-user.target" ];
    before = [ "docker-semaphoreui-db.service" "docker-semaphoreui.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      PASSWORD_FILE="/opt/docker4u/secrets/postgres_password"
      if [ ! -f "$PASSWORD_FILE" ]; then
        echo "Generating new postgres password..."
        ${pkgs.openssl}/bin/openssl rand -base64 32 > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
        echo "Postgres password generated and saved to $PASSWORD_FILE"
      else
        echo "Postgres password already exists, skipping generation"
      fi
    '';
  };

  virtualisation.oci-containers.backend = "docker";

  # PostgreSQL for Semaphore
  virtualisation.oci-containers.containers.semaphoreui-db = {
    image = "postgres:17";
    autoStart = true;

    environment = {
      POSTGRES_DB = "semaphoreui";
      POSTGRES_USER = "semaphoreui";
      POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password";
    };

    volumes = [
      "/opt/docker4u/postgres:/var/lib/postgresql/data"
      "/opt/docker4u/secrets/postgres_password:/run/secrets/postgres_password:ro"
    ];

    extraOptions = [
      "--network=docker4u"
    ];

    dependsOn = [ ];
  };

  # SemaphoreUI (bound to localhost only)
  virtualisation.oci-containers.containers.semaphoreui = {
    image = "semaphoreui/semaphore:v2.16.47-powershell7.5.0";
    autoStart = true;

    # Only local, so it's hidden behind NPM.
    ports = [
      "127.0.0.1:3000:3000"
    ];

    environment = {
      SEMAPHORE_DB_DIALECT = "postgres";
      SEMAPHORE_DB_HOST = "semaphoreui-db";
      SEMAPHORE_DB_PORT = "5432";
      SEMAPHORE_DB_NAME = "semaphoreui";
      SEMAPHORE_DB_USER = "semaphoreui";
      SEMAPHORE_DB_PASS_FILE = "/run/secrets/postgres_password";

      SEMAPHORE_ADMIN = "admin";
      SEMAPHORE_ADMIN_NAME = "Admin";
      SEMAPHORE_ADMIN_EMAIL = "admin@example.invalid";
      SEMAPHORE_ADMIN_PASSWORD = "changeme";
    };

    volumes = [
      "/opt/docker4u/semaphoreui:/var/lib/semaphore"
      "/opt/docker4u/secrets/postgres_password:/run/secrets/postgres_password:ro"
    ];

    dependsOn = [ "semaphoreui-db" ];

    extraOptions = [
      "--network=docker4u"
    ];
  };

  # Nginx Proxy Manager
  # Default is HTTP :80. TLS/443 ready for manual config.
  virtualisation.oci-containers.containers.npm = {
    image = "jc21/nginx-proxy-manager:v2.13.5";
    autoStart = true;

    ports = [
      "80:80"
      "443:443"
      "81:81" # NPM admin UI
    ];

    volumes = [
      "/opt/docker4u/npm-data:/data"
      "/opt/docker4u/npm-letsencrypt:/etc/letsencrypt"
    ];

    dependsOn = [ ];

    extraOptions = [
      "--network=docker4u"
    ];
  };

  # Ensure network and secrets exist before containers start
  systemd.services."docker-semaphoreui-db".after = [ "docker-create-docker4u-net.service" "generate-postgres-password.service" ];
  systemd.services."docker-semaphoreui".after = [ "docker-create-docker4u-net.service" "generate-postgres-password.service" ];
  systemd.services."docker-npm".after = [ "docker-create-docker4u-net.service" ];

}
