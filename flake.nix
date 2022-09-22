{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    snowflake.url = "github:snowflakelinux/snowflake-modules";
    snowflake.inputs.nixpkgs.follows = "nixpkgs";
    os-installer.url = "github:snowflakelinux/os-installer-nix";
    os-installer.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, snowflake, ... }@inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      rec
      {
        iso = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
            ./base.nix
            ./graphical.nix
            ./iso-image.nix
            snowflake.nixosModules.snowflake
          ];
          specialArgs = { inherit inputs; inherit system; };
        };
        defaultPackage = iso.config.system.build.isoImage;
      });
}
