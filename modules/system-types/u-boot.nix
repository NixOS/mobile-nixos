{ config, pkgs, lib, modules, baseModules, ... }:

let
  inherit (pkgs) hostPlatform buildPackages imageBuilder runCommandNoCC;
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.mobile.quirks.u-boot;
  inherit (cfg) soc;
  inherit (config) system;
  inherit (device_info) kernel dtb kernel_cmdline;
  deviceName = config.mobile.device.name;
  device_info = config.mobile.device.info;
  kernel_file = if device_info ? kernel_file then device_info.kernel_file else "${kernel}/${kernel.file}";

  # In the future, this pattern should be extracted.
  # We're basically subclassing the main config, just like nesting does in
  # NixOS (<nixpkgs/modules/system/activation/top-level.nix>)
  # Here we're only adding the `is_recovery` option.
  # In the future, we may want to move the recovery configuration to a file.
  recovery = (import ../../lib/eval-config.nix {
    inherit baseModules;
    modules = modules ++ [{
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    }];
  }).config;

  enabled = config.mobile.system.type == "u-boot";

  bootcmd = pkgs.writeText "${deviceName}-boot.cmd" ''
    echo ****************
    echo * Mobile NixOS *
    echo ****************
    echo
    echo Built for ${deviceName}
    echo

    setenv bootargs ${kernel_cmdline}

    if load ''${devtype} ''${devnum}:''${bootpart} ''${kernel_addr_r} /mobile-nixos/boot/kernel; then
      setenv boot_type boot
    else
      load ''${devtype} ''${devnum}:''${bootpart} ''${kernel_addr_r} /mobile-nixos/recovery/kernel
      setenv boot_type recovery
      setenv bootargs ''${bootargs} is_recovery
    fi

    if load ''${devtype} ''${devnum}:''${bootpart} ''${fdt_addr_r} /mobile-nixos/''${boot_type}/dtbs/''${fdtfile}; then
      fdt addr ''${fdt_addr_r}
      fdt resize
    fi

    load ''${devtype} ''${devnum}:''${bootpart} ''${ramdisk_addr_r} /mobile-nixos/''${boot_type}/stage-1
    setenv ramdisk_size ''${filesize}

    echo bootargs: ''${bootargs}
    echo booti ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};

    booti ''${kernel_addr_r} ''${ramdisk_addr_r}:''${ramdisk_size} ''${fdt_addr_r};
  '';

  # FIXME: don't assume `arm64`.
  bootscr = runCommandNoCC "${deviceName}-boot.scr" {
    nativeBuildInputs = [
      buildPackages.ubootTools
    ];
  } ''
    mkimage -C none -A arm64 -T script -d ${bootcmd} $out
  '';

  withoutBootloader = imageBuilder.diskImage.makeMBR {
    name = "mobile-nixos";
    diskID = "01234567";

    # This has to follow the same order as defined in the u-boot bootloaders...
    # This is not ideal... an alternative solution should be figured out.
    partitions = [
      (imageBuilder.gap (imageBuilder.size.MiB 30)) # TODO: Allow the SoC to set this value.

      (imageBuilder.fileSystem.makeExt4 {
        name = "mobile-nixos-boot";
        partitionID = "ED3902B6-920A-4971-BC07-966D4E021683";
        # Let's give us a *bunch* of space to play around.
        # And let's not forget we have the kernel and stage-1 twice.
        size = imageBuilder.size.MiB 128;
        bootable = true;
        populateCommands = ''
          mkdir -vp mobile-nixos/{boot,recovery}
          (
          cd mobile-nixos/boot
          cp -v ${config.system.build.initrd} stage-1
          cp -v ${kernel_file} kernel
          cp -vr ${kernel}/dtbs dtbs
          )
          (
          cd mobile-nixos/recovery
          cp -v ${recovery.system.build.initrd} stage-1
          cp -v ${kernel_file} kernel
          cp -vr ${kernel}/dtbs dtbs
          )
          cp -v ${bootscr} ./boot.scr
        '';
      })

      config.system.build.rootfs
    ];
  };

  burnCommands = family: (
    let
      commands = {
        allwinner = ''
          dd if=${cfg.package}/u-boot-sunxi-with-spl.bin of=$out bs=1024 seek=8 conv=notrunc
        '';
        rockchip = ''
          dd if=${cfg.package}/idbloader.img of=$out bs=512 seek=64 conv=notrunc
          dd if=${cfg.package}/u-boot.itb    of=$out bs=512 seek=16384 conv=notrunc
        '';
      };
    in
    if commands ? "${family}"
    then commands.${family}
    else throw "No u-boot burn commands for SoC family '${family}'"
  );

  withBootloader = runCommandNoCC "${deviceName}_full-disk-image.img" {} ''
    cp -v ${withoutBootloader}/mobile-nixos.img $out
    chmod +w $out
    echo ":: Burning bootloader"
    (
    PS4=" $ "
    set -x
    ${burnCommands soc.family}
    )
    echo ":: Burned"
  '';
in
{
  options.mobile = {
    quirks.u-boot = {
      soc.family = mkOption {
        type = types.enum [ "allwinner" "rockchip" ];
        internal = true;
        description = ''
          The (internal to this project) family name for the bootloader.
          This is used to build upon assumptions like the location on the
          backing storage that u-boot will be "burned" at.
        '';
      };
      package = mkOption {
        type = types.package;
        description = ''
          Which package handles u-boot for this system.
        '';
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "u-boot" ]; }
    (mkIf enabled {
      nixpkgs.overlays = [(final: super: {
        device = {
          u-boot = cfg.package;
        };
      })];
      system.build = {
        disk-image = withBootloader;
      };
    })
  ];
}
