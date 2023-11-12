{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    snowflakeos-modules = {
      url = "github:snowflakelinux/snowflakeos-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    icicle = {
      url = "github:snowflakelinux/icicle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-data = {
      url = "github:snowflakelinux/nix-data";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake rec {
      inherit inputs;
      channels-config.allowUnfree = true;

      systems.modules.nixos = with inputs; [
        nix-data.nixosModules.nix-data
        icicle.nixosModules.icicle
        snowflakeos-modules.nixosModules.gnome
        snowflakeos-modules.nixosModules.kernel
        snowflakeos-modules.nixosModules.networking
        snowflakeos-modules.nixosModules.pipewire
        snowflakeos-modules.nixosModules.printing
        snowflakeos-modules.nixosModules.snowflakeos
        snowflakeos-modules.nixosModules.metadata
      ];

      src = ./.;
    };
}
