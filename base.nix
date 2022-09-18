{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    glibcLocales
  ];
  i18n.supportedLocales = [ "all" ];
  networking.hostName = "snowflakeos";
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
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
