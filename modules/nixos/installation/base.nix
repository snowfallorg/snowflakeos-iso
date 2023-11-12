{ pkgs, config, lib, inputs, system, ... }:
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

  boot.kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;

  environment.systemPackages = with pkgs; [
    git
    glibcLocales
    glxinfo
    gparted
    nano
    rsync
    vim
  ];

  i18n.supportedLocales = [ "all" ];

  networking.hostName = "snowflakeos";
  networking.wireless.enable = false;

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
  users.groups.nixos = {};
}
