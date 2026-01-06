{ config, pkgs, ... }:

{
  imports = [
    ../common/hardware-configuration-proxmox.nix
  ];

  # Base system configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Prague";

  # SSH
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };

  # Proxmox guest
  services.qemuGuest.enable = true;

  # Base user
  users.users.homelab = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOTm0wfJpY+JLZ7qIBGYjQxx5YqLL0VkBiXg8ZZxQ6yqD7YBfVNJXT1zxOvf6unUTB0Ur+R2RFXDP8/hJdyDhHpoyv2IcvBYOsk91xjU7HzKsqLgS+9Tf+QUIUCHK/7orXMjP8VUCw6DRZr50TTD2om9GwdKyJOXFiSypClPp6T25Qld036dNVyyYvYKVLdbP5ADgtLRigv4xK6MXHhf6fFQqvdNaB6eBvcupL3ijXZ5LiWliwcRaqUy6RRSulTSRFrN9EfxCEdcy4D4RNJuxlPzX96fV3ZmeLBx7K6EPRLFSXyrKuom9omO9Dcd7Mt5Y4QIpXc6iW7RccAXGE4s8UiGceyqItjRRaMlLi+yQn+VNeApnwvXGQLTDrsh45Nfc/TNlvP37xH3cSmNH8GwYJ+W6eapCzeA7tsAZo1F9wRYzgqk2GpFaUb/y2bREWf0WLPsw8REmCpEZ0+KkVcT7UD34uD5imXlVkHvvxYMpxuBDbaOPcVLqDEbaH7G3TySM="
    ];
  };

  # System users to match container UIDs/GIDs, so tmpfiles and chown succeed.
  users.groups.postgres-container.gid = 999;
  users.users.postgres-container = {
    isSystemUser = true;
    uid = 999;
    group = "postgres-container";
    description = "Postgres container user (matches image UID/GID)";
  };
  users.groups.semaphore-container.gid = 1001;
  users.users.semaphore-container = {
    isSystemUser = true;
    uid = 1001;
    group = "semaphore-container";
    description = "Semaphore container user (matches image UID/GID)";
  };

  security.sudo.wheelNeedsPassword = false;

  # Base tools
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
  ];

  networking.hostName = "semaphoreui";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";

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

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  # Persist dirs (survives rebuilds)
  systemd.tmpfiles.rules = [
    # Ensure a clean secret path before recreation
    "r /opt/docker4u/secrets/postgres_password - - - -"
    "d /opt/docker4u 0750 homelab docker -"
    "d /opt/docker4u/npm-data 0750 1000 1000 -"
    "d /opt/docker4u/npm-letsencrypt 0750 1000 1000 -"
    "d /opt/docker4u/semaphoreui 0750 semaphore-container semaphore-container -"
    "d /opt/docker4u/postgres 0700 postgres-container postgres-container -"
    "d /opt/docker4u/secrets 0750 root postgres-container -"
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
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      PASSWORD_FILE="/opt/docker4u/secrets/postgres_password"
      mkdir -p /opt/docker4u/secrets
      chown root:postgres-container /opt/docker4u/secrets
      chmod 750 /opt/docker4u/secrets
      if [ -d "$PASSWORD_FILE" ]; then
        echo "Found directory at $PASSWORD_FILE; removing so the secret file can be created."
        rm -rf "$PASSWORD_FILE"
      fi
      if [ ! -f "$PASSWORD_FILE" ]; then
        echo "Generating new postgres password..."
        ${pkgs.openssl}/bin/openssl rand -base64 32 > "$PASSWORD_FILE"
        chmod 640 "$PASSWORD_FILE"
        chown postgres-container:postgres-container "$PASSWORD_FILE"
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
    # Run as the image default postgres uid/gid 999 for correct initdb ownership.
    user = "999:999";

    environment = {
      POSTGRES_DB = "semaphoreui";
      POSTGRES_USER = "semaphoreui";
      POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_password";
    };

    volumes = [
      "/opt/docker4u/postgres:/var/lib/postgresql/data"
      "/opt/docker4u/secrets:/run/secrets:ro"
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
    # Run as image uid 1001 with group 999 so it can read the shared secret.
    user = "1001:999";

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
      "/opt/docker4u/secrets:/run/secrets:ro"
    ];

    dependsOn = [ "semaphoreui-db" ];

    extraOptions = [
      "--network=docker4u"
    ];
  };

  # Nginx Proxy Manager
  # Default is HTTP :80. TLS/443 ready for manual config.
  virtualisation.oci-containers.containers.npm = {
    image = "jc21/nginx-proxy-manager:2.13.5";
    autoStart = true;
    environment = {
      PUID = "1000";
      PGID = "1000";
    };

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
  systemd.services."docker-semaphoreui-db".requires = [ "generate-postgres-password.service" ];
  systemd.services."docker-semaphoreui".after = [ "docker-create-docker4u-net.service" "generate-postgres-password.service" ];
  systemd.services."docker-semaphoreui".requires = [ "generate-postgres-password.service" ];
  systemd.services."docker-npm".after = [ "docker-create-docker4u-net.service" ];

}
