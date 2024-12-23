{ lib, modulesPath, ... }:
{
    imports =
        [ (modulesPath + "/profiles/qemu-guest.nix") ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];
    boot.initrd.kernelModules = [ "dm-snapshot" ];
    boot.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}