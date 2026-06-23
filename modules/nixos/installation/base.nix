{
  pkgs,
  lib,
  ...
}:
{
  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # error: Refusing to evaluate package 'zfs-kernel-2.4.1-7.0.3' in /nix/store/wjfxdzblindbl9sp2hbwhi4iyh5jh348-source/pkgs/os-specific/linux/zfs/generic.nix:327 because it has problems:
  #- broken: This package is broken.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  environment.systemPackages = with pkgs; [
    git
    glibcLocales
    mesa-demos
    gparted
    nano
    rsync
    vim
  ];

  i18n.supportedLocales = [ "all" ];

  networking.hostName = "snowflakeos";
  networking.wireless.enable = lib.mkForce false;

  users.users = {
    snowflake = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
      ];
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
  users.groups.nixos = { };
}
