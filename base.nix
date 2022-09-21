{ pkgs, lib, inputs, system, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Fix issue with zfs on latest kernel: https://github.com/NixOS/nixpkgs/issues/58959
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
  environment.systemPackages = with pkgs; [
    glibcLocales
  ];
  i18n.supportedLocales = [ "all" ];
  networking.hostName = "snowflakeos";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.settings.auto-optimise-store = true;
  users.users = {
    snowflake = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" ];
      # Allow the graphical user to login without password
      initialHashedPassword = "";
    };
    # Prevent default nixos user form appearing in the login screen
    nixos = {
      isSystemUser = true;
      isNormalUser = lib.mkForce false;
      group = "nixos";
    };
  };
}
