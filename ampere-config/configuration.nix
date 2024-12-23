{ modulesPath, ... }: # Add 'pkgs' if 'environment.systemPackages' is used
{
    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ../disk-config.nix
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

    # environment.systemPackages = with pkgs; [
    #     git
    # ];

    # Enabled programs.
    programs = {
        git.enable = true;
        neovim = {
            enable = true;
            vimAlias = true;
            viAlias = true;
        };
    };

    # Remove sudo password requirement for specified users.
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
    system.stateVersion = "unstable";
}