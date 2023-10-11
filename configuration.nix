{ pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # allows remote rebuild
      trusted-users = [ "james" ];
    };
    gc.automatic = true;
  };

  networking.hostName = "phalanx";

  # bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # time zone
  time.timeZone = "Europe/London";

  # locale
  i18n.defaultLocale = "en_GB.UTF-8";

  # networking
  networking = {
    firewall.enable = true;
  };
  services.tailscale.enable = true;

  # ssh
  services.openssh = {
    enable = true;
    ports = [ 97 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    ignoreIP = [ "countess" "baron" ]; # whitelist tailscale hosts
  };

  services.endlessh = {
    enable = true;
    openFirewall = true;
    port = 22;
  };

  networking.firewall.allowedTCPPorts = [ 
    97 # ssh
    80 443 # web interface and file sharing
    5222 # client connections
    5269 # federation
    5000 # file transfer proxy
    3478 3479 # STUN/TURN
    5349 5350 # STUN/TURN TLS
    3000 4000 # mastodon
  ];
  networking.firewall.allowedUDPPorts = [ 
    3478 3479 # STUN/TURN
    5349 5350 # STUN/TURN TLS
  ];
  # for TURN data
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 60000;
      to = 61023;
    }
  ];

  # user
  users.users = {
    james = {
      isNormalUser = true;
      shell = pkgs.fish;
      initialPassword = "changethisyoupickle";
      extraGroups = [
        "wheel"
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW4ofxuyFKtDXCHHR6UDf5hGolKwZqt3h7SFLCCy++6 james@baron" # desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzFa1hmBsCrPL5HvJZhXVEaWiZIMi34oR6AOcKD35hQ james@countess" # laptop
      ];
    };
  };
  programs.fish.enable = true;

  # docker
  virtualisation.docker = {
    enable = true;
    liveRestore = false;
    autoPrune.enable = true;
  };

  # cron
  services.cron = {
    enable = true;
    systemCronJobs = [
      "@weekly      root     sh /etc/cron-jobs/mastodon-cleanup.sh"
      "@weekly      root     sh /etc/cron-jobs/backup.sh /home/james/phalanx-docker"
    ];
  };

  # link scripts to etc
  environment.etc = {
    "cron-jobs/mastodon-cleanup.sh" = {
      source = ./jobs/mastodon-cleanup.sh;
    };
    "cron-jobs/backup.sh" = {
      source = ./jobs/backup.sh;
    };
  };

  environment.systemPackages = with pkgs; [ 
    docker-compose
    rsync
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";

}
