{ modulesPath, lib, pkgs, ... }:
let
    NETDATA_USERNAME= "netdata";                    # Username for Netdata
    NETDATA_PASSWORD= "netdata_password";      # Password for Netdata
    # DOMAIN_NAME = "your_domain_name.com";         # Domain Name (Uncomment when available)
    EMAIL_ADDRESS = "your_email@example.com";       # Email for ACME
in
{
    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../disk-config.nix
    ];

    # Allow unfree packages.
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "netdata"
    ];

    # Bootloader.
    boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
    };

    # OpenSSH.
    services.openssh = {
        enable = true;
        settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
        };
    };

    # Netdata.
    services.netdata = {
        enable = true;
        package = pkgs.netdata.override {
            withCloudUi = true;
        };
        config = {
            web = {
                mode = "static-threaded";
                bind_to = "127.0.0.1";
            };
        };
    };

    users = {
        users.netdata-htpasswd-user = {
            isSystemUser = true;
            createHome = false;
            group = "netdata-htpasswd-user";
        };
        groups.netdata-htpasswd-user = {};
    };

    systemd = {
        tmpfiles.rules = [
            "d /var/lib/netdata 0755 netdata-htpasswd-user netdata-htpasswd-user -"
        ];
        services.generate-htpasswd = {
            description = "Generate htpasswd file";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                Type = "oneshot";
                User = "netdata-htpasswd-user";
                RemainAfterExit = true;
                ExecStart = ''
                    ${pkgs.apacheHttpd}/bin/htpasswd -c -b /var/lib/netdata/htpasswd ${NETDATA_USERNAME} ${NETDATA_PASSWORD}
                '';
            };
        };
    };

    # Nginx.
    services.nginx = {
        enable = true;
        virtualHosts."netdata-proxy" = {
            forceSSL = true;
            enableACME = true; # No certificate provided. One will be generated.
            locations."/" = {
                proxyPass = "http://127.0.0.1:19999";
                basicAuth = {
                    realm = "Netdata Access";
                    file = "/var/lib/netdata/htpasswd";
                };
            };
        };
    };

    # ACME Configuration (No certificate provided. One will be generated.)
    security.acme = {
        acceptTerms = true;
        defaults.email = EMAIL_ADDRESS;
    };

    # System packages.
    environment.systemPackages = with pkgs; [
        apacheHttpd
    ];

    # Enabled programs.
    programs = {
        git.enable = true;
        neovim = {
            enable = true;
            vimAlias = true;
            viAlias = true;
        };
    };

    # Firewall settings.
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Remove sudo password requirement for specified users. Currently not working.
    security.sudo.extraRules = [{
        users = [ "dinis" "ricol" ];
        commands =  [ { command = "/home/root/secret.sh"; options = [ "SETENV" "NOPASSWD" ]; } ];
    }];

    # Users.
    users.users = {
        root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBuRiGrNd5DLnjN3EbqV2wRvlnOh9iMmIOTsLfMvQRE dinis@omen-15"
        ];
        dinis = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBuRiGrNd5DLnjN3EbqV2wRvlnOh9iMmIOTsLfMvQRE dinis@omen-15"
            ];
        };
        ricol = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = [];
        };
    };

    # Enable flake support.
    nix.settings.experimental-features = [ "flakes" "nix-command" ];

    # System state version.
    system.stateVersion = "24.11";
}