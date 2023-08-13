{ pkgs, config, lib, inputs, system, ... }:
{
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "1";
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

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = lib.mkForce false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Backport mutter patch which fix flickering in scenarios where the dri
  # driver is unavailable.
  #
  #   https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/3117
  #
  nixpkgs.overlays = [
    (self: super: {
      gnome = super.gnome.overrideScope' (gself: gsuper: {
        mutter = gsuper.mutter.overrideAttrs (old: rec {
           patches = (old.patches or [ ]) ++ [
            (super.fetchpatch {
              url = "https://gitlab.gnome.org/GNOME/mutter/-/commit/626498348b96e7ebdb2ab90fb7d2b3446578333a.patch";
              hash = "sha256-KLx0qbPwbooHEIMt0r2g/CjyWb2M5Mv3gNdA3YM6qJA";
            })
          ];
        });
      });
    })
  ];
}
