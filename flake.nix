{
  inputs = {
    nixpkgs.url = "github:vlinkz/nixpkgs/kpmcorefix";
    snowflake.url = "github:snowflakelinux/snowflake-modules";
    snowflake.inputs.nixpkgs.follows = "nixpkgs";
    calamares-snowflakeos-extensions.url = "github:snowflakelinux/calamares-snowflakeos-extensions";
    calamares-snowflakeos-extensions.inputs.nixpkgs.follows = "nixpkgs";
    os-installer.url = "github:/snowflakelinux/os-installer-nix";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, snowflake, ... }@inputs:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        name = "snowflake-iso";
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
