{ modulesPath, pkgs, ... }:
{
    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        (modulesPath + "/installer/scan/not-detected.nix")
        ../disk-config.nix
    ];

    boot.loader.grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
    };

    services.openssh.enable = true;

    environment.systemPackages = with pkgs; [
        git
    ];

    users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBuRiGrNd5DLnjN3EbqV2wRvlnOh9iMmIOTsLfMvQRE dinis@omen-15"
    ];

    nix.settings.experimental-features = [ "flakes" "nix-command" ];

    system.stateVersion = "24.11";
}