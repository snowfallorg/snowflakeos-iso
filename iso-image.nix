{ pkgs, lib, config, ... }:

with lib;

let

  osfullname = "SnowflakeOS";
  osname = "snowflakeos";

  grubPkgs = if config.boot.loader.grub.forcei686 then pkgs.pkgsi686Linux else pkgs;
  # Name used by UEFI for architectures.
  targetArch =
    if pkgs.stdenv.isi686 || config.boot.loader.grub.forcei686 then
      "ia32"
    else if pkgs.stdenv.isx86_64 then
      "x64"
    else if pkgs.stdenv.isAarch32 then
      "arm"
    else if pkgs.stdenv.isAarch64 then
      "aa64"
    else
      throw "Unsupported architecture";
  refindBinary = if targetArch == "x64" || targetArch == "aa64" then "refind_${targetArch}.efi" else null;
  # Setup instructions for rEFInd.
  refind =
    if refindBinary != null then
      ''
      # Adds rEFInd to the ISO.
      cp -v ${pkgs.refind}/share/refind/${refindBinary} $out/EFI/boot/
      ''
    else
      "# No refind for ${targetArch}"
  ;
  grubMenuCfg = ''
    #
    # Menu configuration
    #

    # Search using a "marker file"
    search --set=root --file /EFI/nixos-installer-image

    insmod gfxterm
    insmod png
    set gfxpayload=keep
    set gfxmode=${concatStringsSep "," [
      #"3840x2160"
      #"2560x1440"
      "1920x1080"
      "1366x768"
      "1280x720"
      "1024x768"
      "800x600"
      "auto"
    ]}

    # Fonts can be loaded?
    # (This font is assumed to always be provided as a fallback by NixOS)
    if loadfont (\$root)/EFI/boot/unicode.pf2; then
      set with_fonts=true
    fi
    if [ "\$textmode" != "true" -a "\$with_fonts" == "true" ]; then
      # Use graphical term, it can be either with background image or a theme.
      # input is "console", while output is "gfxterm".
      # This enables "serial" input and output only when possible.
      # Otherwise the failure mode is to not even enable gfxterm.
      if test "\$with_serial" == "yes"; then
        terminal_output gfxterm serial
        terminal_input  console serial
      else
        terminal_output gfxterm
        terminal_input  console
      fi
    else
      # Sets colors for the non-graphical term.
      set menu_color_normal=cyan/blue
      set menu_color_highlight=white/blue
    fi

    ${ # When there is a theme configured, use it, otherwise use the background image.
    if config.isoImage.grubTheme != null then ''
      # Sets theme.
      set theme=(\$root)/EFI/boot/grub-theme/theme.txt
      # Load theme fonts
      $(find ${config.isoImage.grubTheme} -iname '*.pf2' -printf "loadfont (\$root)/EFI/boot/grub-theme/%P\n")
    '' else ''
      if background_image (\$root)/EFI/boot/efi-background.png; then
        # Black background means transparent background when there
        # is a background image set... This seems undocumented :(
        set color_normal=black/black
        set color_highlight=white/blue
      else
        # Falls back again to proper colors.
        set menu_color_normal=cyan/blue
        set menu_color_highlight=white/blue
      fi
    ''}
  '';


  menuBuilderGrub2 =
    defaults: options: concatStrings
      (
        map
          (option: ''
            menuentry '${defaults.name} ${
            # Name appended to menuentry defaults to params if no specific name given.
            option.name or (if option ? params then "(${option.params})" else "")
            }' ${if option ? class then " --class ${option.class}" else ""} {
              linux ${defaults.image} \''${isoboot} ${defaults.params} ${
                option.params or ""
              }
              initrd ${defaults.initrd}
            }
          '')
          options
      )
  ;

  buildMenuGrub2 = config:
    buildMenuAdditionalParamsGrub2 config ""
  ;

  buildMenuAdditionalParamsGrub2 = config: additional:
    let
      finalCfg = {
        name = "${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel}";
        params = "init=${config.system.build.toplevel}/init ${additional} ${toString config.boot.kernelParams}";
        image = "/boot/${config.system.boot.loader.kernelFile}";
        initrd = "/boot/initrd";
      };
    in
    menuBuilderGrub2
      finalCfg
      [
        { class = "installer"; }
        { class = "nomodeset"; params = "nomodeset"; }
        { class = "copytoram"; params = "copytoram"; }
        { class = "debug"; params = "debug"; }
      ]
  ;

  max = x: y: if x > y then x else y;

  syslinuxTimeout =
    if config.boot.loader.timeout == null then
      0
    else
      max (config.boot.loader.timeout * 10) 1;

  baseIsolinuxCfg = ''
    SERIAL 0 115200
    TIMEOUT ${builtins.toString syslinuxTimeout}
    UI vesamenu.c32
    MENU BACKGROUND /isolinux/background.png

    ${config.isoImage.syslinuxTheme}

    DEFAULT boot

    LABEL boot
    MENU LABEL ${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel}
    LINUX /boot/${config.system.boot.loader.kernelFile}
    APPEND init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
    INITRD /boot/${config.system.boot.loader.initrdFile}

    # A variant to boot with 'nomodeset'
    LABEL boot-nomodeset
    MENU LABEL ${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel} (nomodeset)
    LINUX /boot/${config.system.boot.loader.kernelFile}
    APPEND init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} nomodeset
    INITRD /boot/${config.system.boot.loader.initrdFile}

    # A variant to boot with 'copytoram'
    LABEL boot-copytoram
    MENU LABEL ${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel} (copytoram)
    LINUX /boot/${config.system.boot.loader.kernelFile}
    APPEND init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} copytoram
    INITRD /boot/${config.system.boot.loader.initrdFile}

    # A variant to boot with verbose logging to the console
    LABEL boot-debug
    MENU LABEL ${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel} (debug)
    LINUX /boot/${config.system.boot.loader.kernelFile}
    APPEND init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} loglevel=7
    INITRD /boot/${config.system.boot.loader.initrdFile}

    # A variant to boot with a serial console enabled
    LABEL boot-serial
    MENU LABEL ${osfullname} ${config.system.nixos.label}${config.isoImage.appendToMenuLabel} (serial console=ttyS0,115200n8)
    LINUX /boot/${config.system.boot.loader.kernelFile}
    APPEND init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams} console=ttyS0,115200n8
    INITRD /boot/${config.system.boot.loader.initrdFile}
  '';

  isolinuxMemtest86Entry = ''
    LABEL memtest
    MENU LABEL Memtest86+
    LINUX /boot/memtest.bin
    APPEND ${toString config.boot.loader.grub.memtest86.params}
  '';

  isolinuxCfg = concatStringsSep "\n"
    ([ baseIsolinuxCfg ] ++ optional config.boot.loader.grub.memtest86.enable isolinuxMemtest86Entry);


  efiDir = pkgs.runCommand "efi-directory"
    {
      nativeBuildInputs = [ pkgs.buildPackages.grub2_efi ];
      strictDeps = true;
    } ''
    mkdir -p $out/EFI/boot/

    # Add a marker so GRUB can find the filesystem.
    touch $out/EFI/nixos-installer-image

    # ALWAYS required modules.
    MODULES="fat iso9660 part_gpt part_msdos \
             normal boot linux configfile loopback chain halt \
             efifwsetup efi_gop \
             ls search search_label search_fs_uuid search_fs_file \
             gfxmenu gfxterm gfxterm_background gfxterm_menu test all_video loadenv \
             exfat ext2 ntfs btrfs hfsplus udf \
             videoinfo png \
             echo serial \
            "

    echo "Building GRUB with modules:"
    for mod in $MODULES; do
      echo " - $mod"
    done

    # Modules that may or may not be available per-platform.
    echo "Adding additional modules:"
    for mod in efi_uga; do
      if [ -f ${grubPkgs.grub2_efi}/lib/grub/${grubPkgs.grub2_efi.grubTarget}/$mod.mod ]; then
        echo " - $mod"
        MODULES+=" $mod"
      fi
    done

    # Make our own efi program, we can't rely on "grub-install" since it seems to
    # probe for devices, even with --skip-fs-probe.
    grub-mkimage --directory=${grubPkgs.grub2_efi}/lib/grub/${grubPkgs.grub2_efi.grubTarget} -o $out/EFI/boot/boot${targetArch}.efi -p /EFI/boot -O ${grubPkgs.grub2_efi.grubTarget} \
      $MODULES
    cp ${grubPkgs.grub2_efi}/share/grub/unicode.pf2 $out/EFI/boot/

    cat <<EOF > $out/EFI/boot/grub.cfg

    set with_fonts=false
    set textmode=false
    # If you want to use serial for "terminal_*" commands, you need to set one up:
    #   Example manual configuration:
    #    → serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    # This uses the defaults, and makes the serial terminal available.
    set with_serial=no
    if serial; then set with_serial=yes ;fi
    export with_serial
    clear
    set timeout=10

    # This message will only be viewable when "gfxterm" is not used.
    echo ""
    echo "Loading graphical boot menu..."
    echo ""
    echo "Press 't' to use the text boot menu on this console..."
    echo ""

    ${grubMenuCfg}

    hiddenentry 'Text mode' --hotkey 't' {
      loadfont (\$root)/EFI/boot/unicode.pf2
      set textmode=true
      terminal_output gfxterm console
    }
    hiddenentry 'GUI mode' --hotkey 'g' {
      $(find ${config.isoImage.grubTheme} -iname '*.pf2' -printf "loadfont (\$root)/EFI/boot/grub-theme/%P\n")
      set textmode=false
      terminal_output gfxterm
    }


    # If the parameter iso_path is set, append the findiso parameter to the kernel
    # line. We need this to allow the nixos iso to be booted from grub directly.
    if [ \''${iso_path} ] ; then
      set isoboot="findiso=\''${iso_path}"
    fi

    #
    # Menu entries
    #

    ${buildMenuGrub2 config}
    submenu "HiDPI, Quirks and Accessibility" --class hidpi --class submenu {
      ${grubMenuCfg}
      submenu "Suggests resolution @720p" --class hidpi-720p {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "video=1280x720@60"}
      }
      submenu "Suggests resolution @1080p" --class hidpi-1080p {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "video=1920x1080@60"}
      }

      # If we boot into a graphical environment where X is autoran
      # and always crashes, it makes the media unusable. Allow the user
      # to disable this.
      submenu "Disable display-manager" --class quirk-disable-displaymanager {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "systemd.mask=display-manager.service"}
      }

      # Some laptop and convertibles have the panel installed in an
      # inconvenient way, rotated away from the keyboard.
      # Those entries makes it easier to use the installer.
      submenu "" {return}
      submenu "Rotate framebuffer Clockwise" --class rotate-90cw {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "fbcon=rotate:1"}
      }
      submenu "Rotate framebuffer Upside-Down" --class rotate-180 {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "fbcon=rotate:2"}
      }
      submenu "Rotate framebuffer Counter-Clockwise" --class rotate-90ccw {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "fbcon=rotate:3"}
      }

      # As a proof of concept, mainly. (Not sure it has accessibility merits.)
      submenu "" {return}
      submenu "Use black on white" --class accessibility-blakconwhite {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "vt.default_red=0xFF,0xBC,0x4F,0xB4,0x56,0xBC,0x4F,0x00,0xA1,0xCF,0x84,0xCA,0x8D,0xB4,0x84,0x68 vt.default_grn=0xFF,0x55,0xBA,0xBA,0x4D,0x4D,0xB3,0x00,0xA0,0x8F,0xB3,0xCA,0x88,0x93,0xA4,0x68 vt.default_blu=0xFF,0x58,0x5F,0x58,0xC5,0xBD,0xC5,0x00,0xA8,0xBB,0xAB,0x97,0xBD,0xC7,0xC5,0x68"}
      }

      # Serial access is a must!
      submenu "" {return}
      submenu "Serial console=ttyS0,115200n8" --class serial {
        ${grubMenuCfg}
        ${buildMenuAdditionalParamsGrub2 config "console=ttyS0,115200n8"}
      }
    }

    ${optionalString (refindBinary != null) ''
    # GRUB apparently cannot do "chainloader" operations on "CD".
    if [ "\$root" != "cd0" ]; then
      menuentry 'rEFInd' --class refind {
        # Force root to be the FAT partition
        # Otherwise it breaks rEFInd's boot
        search --set=root --no-floppy --fs-uuid 1234-5678
        chainloader (\$root)/EFI/boot/${refindBinary}
      }
    fi
    ''}
    menuentry 'Firmware Setup' --class settings {
      fwsetup
      clear
      echo ""
      echo "If you see this message, your EFI system doesn't support this feature."
      echo ""
    }
    menuentry 'Shutdown' --class shutdown {
      halt
    }
    EOF

    ${refind}
  '';

  efiImg = pkgs.runCommand "efi-image_eltorito"
    {
      nativeBuildInputs = [ pkgs.buildPackages.mtools pkgs.buildPackages.libfaketime pkgs.buildPackages.dosfstools ];
      strictDeps = true;
    }
    # Be careful about determinism: du --apparent-size,
    #   dates (cp -p, touch, mcopy -m, faketime for label), IDs (mkfs.vfat -i)
    ''
      mkdir ./contents && cd ./contents
      mkdir -p ./EFI/boot
      cp -rp "${efiDir}"/EFI/boot/{grub.cfg,*.efi} ./EFI/boot

      # Rewrite dates for everything in the FS
      find . -exec touch --date=2000-01-01 {} +

      # Round up to the nearest multiple of 1MB, for more deterministic du output
      usage_size=$(( $(du -s --block-size=1M --apparent-size . | tr -cd '[:digit:]') * 1024 * 1024 ))
      # Make the image 110% as big as the files need to make up for FAT overhead
      image_size=$(( ($usage_size * 110) / 100 ))
      # Make the image fit blocks of 1M
      block_size=$((1024*1024))
      image_size=$(( ($image_size / $block_size + 1) * $block_size ))
      echo "Usage size: $usage_size"
      echo "Image size: $image_size"
      truncate --size=$image_size "$out"
      faketime "2000-01-01 00:00:00" mkfs.vfat -i 12345678 -n EFIBOOT "$out"

      # Force a fixed order in mcopy for better determinism, and avoid file globbing
      for d in $(find EFI -type d | sort); do
        faketime "2000-01-01 00:00:00" mmd -i "$out" "::/$d"
      done

      for f in $(find EFI -type f | sort); do
        mcopy -pvm -i "$out" "$f" "::/$f"
      done

      # Verify the FAT partition.
      fsck.vfat -vn "$out"
    ''; # */
in
{
  snowflakeos.osInfo.enable = true;
  isoImage.isoBaseName = "${osname}";
  isoImage.volumeID = "${osname}${optionalString (config.isoImage.edition != "") "-${config.isoImage.edition}"}-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.uname.processor}";
  isoImage.syslinuxTheme = ''
    MENU TITLE ${osfullname}
    MENU RESOLUTION 800 600
    MENU CLEAR
    MENU ROWS 6
    MENU CMDLINEROW -4
    MENU TIMEOUTROW -3
    MENU TABMSGROW  -2
    MENU HELPMSGROW -1
    MENU HELPMSGENDROW -1
    MENU MARGIN 0

    #                                FG:AARRGGBB  BG:AARRGGBB   shadow
    MENU COLOR BORDER       30;44      #00000000    #00000000   none
    MENU COLOR SCREEN       37;40      #FF000000    #00E2E8FF   none
    MENU COLOR TABMSG       31;40      #80000000    #00000000   none
    MENU COLOR TIMEOUT      1;37;40    #FF000000    #00000000   none
    MENU COLOR TIMEOUT_MSG  37;40      #FF000000    #00000000   none
    MENU COLOR CMDMARK      1;36;40    #FF000000    #00000000   none
    MENU COLOR CMDLINE      37;40      #FF000000    #00000000   none
    MENU COLOR TITLE        1;36;44    #00000000    #00000000   none
    MENU COLOR UNSEL        37;44      #FF000000    #00000000   none
    MENU COLOR SEL          7;37;40    #FFFFFFFF    #FF5277C3   std
  '';
  isoImage.contents =
    ([ ] ++ optionals pkgs.stdenv.hostPlatform.isx86 [
      {
        source = pkgs.substituteAll {
          name = "isolinux.cfg";
          src = pkgs.writeText "isolinux.cfg-in" isolinuxCfg;
          bootRoot = "/boot";
        };
        target = "/isolinux/isolinux.cfg";
      }
    ] ++ optionals config.isoImage.makeEfiBootable [
      {
        source = efiImg;
        target = "/boot/efi.img";
      }
      {
        source = "${efiDir}/EFI";
        target = "/EFI";
      }
    ]);
}
