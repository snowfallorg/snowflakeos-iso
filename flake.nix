{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    snowflake = {
      url = "github:snowflakelinux/snowflake-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    os-installer = {
      url = "github:snowflakelinux/os-installer-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-data = {
      url = "github:snowflakelinux/nix-data";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-software-center = {
      url = "github:vlinkz/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snow = {
      url = "github:snowflakelinux/snow";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }@inputs:
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
            inputs.snowflake.nixosModules.snowflake
            inputs.nix-data.nixosModules.${system}.nix-data
          ];
          specialArgs = { inherit inputs; inherit system; };
        };
        defaultPackage = iso.config.system.build.isoImage;
      });
}
