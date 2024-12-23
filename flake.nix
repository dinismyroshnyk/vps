{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, disko, ...}: {
        nixosConfigurations = {
            ampere-install = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    disko.nixosModules.disko
                    ./ampere-install/configuration.nix
                    ./ampere-install/hardware-configuration.nix
                ];
            };
            ampere-config = nixpkgs.lib.nixosSystem {
                system = "aarch64-linux";
                modules = [
                    disko.nixosModules.disko
                    ./ampere-config/configuration.nix
                    ./ampere-config/hardware-configuration.nix
                ];
            };
        };
        ampere-config = self.nixosConfigurations.ampere-config.config.system.build.toplevel;
    };
}