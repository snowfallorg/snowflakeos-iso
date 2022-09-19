{ pkgs, lib, config, inputs, system, ... }:
let
  os-installer-autostart = pkgs.makeAutostartItem { name = "com.github.p3732.OS-Installer"; package = inputs.os-installer.packages.${system}.os-installer; };
in
{
  environment.systemPackages = with pkgs; [
    libsForQt5.kpmcore
    calamares-nixos
    os-installer-autostart
    inputs.calamares-snowflakeos-extensions.packages.${system}.calamares-snowflakeos-extensions
    inputs.os-installer.packages.${system}.os-installer
    libsForQt5.full
  ];

  snowflakeos.gnome.enable = true;

  services.xserver.desktopManager.gnome = {
    # Add Firefox and other tools useful for installation to the launcher
    favoriteAppsOverride = ''
      [org.gnome.shell]
      favorite-apps=[ 'firefox.desktop', 'nixos-manual.desktop', 'org.gnome.Console.desktop', 'org.gnome.Nautilus.desktop', 'gparted.desktop' ]
    '';

    # Override GNOME defaults to disable GNOME tour and disable suspend
    extraGSettingsOverrides = ''
      [org.gnome.shell]
      welcome-dialog-last-shown-version='9999999999'
      [org.gnome.desktop.session]
      idle-delay=0
      [org.gnome.settings-daemon.plugins.power]
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-type='nothing'
    '';

    extraGSettingsOverridePackages = [ pkgs.gnome.gnome-settings-daemon ];
  };

  services.xserver.displayManager = {
    gdm = {
      enable = true;
      # autoSuspend makes the machine automatically suspend after inactivity.
      # It's possible someone could/try to ssh'd into the machine and obviously
      # have issues because it's inactive.
      # See:
      # * https://github.com/NixOS/nixpkgs/pull/63790
      # * https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22
      autoSuspend = false;
    };
    autoLogin = {
      enable = true;
      user = "snowflake";
    };
  };
}
