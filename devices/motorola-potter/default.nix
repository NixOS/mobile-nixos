{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-potter";
  mobile.device.identity = {
    name = "Moto G5 Plus";
    manufacturer = "Motorola";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 2;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      # These are modules because postmarketos builds them as
      # modules.  Excepting that you only need one of the two
      # panel modules (hardware-dependent) it might make more
      # sense to build them monolithically. Unless you want to
      # run your phone headlessly ...
      "rmi_i2c"                 # touchscreen driver
      "qcom-pon"                # power and volume down keys
      "panel-boe-bs052fhm-a00-6c01"
      "panel-tianma-tl052vdxp02"
      "msm"                     # DRM module

    ];
  };
  boot.initrd.kernelModules = [ "rmi_core" ]; # does this do anything?
  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "potter";
  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  # The boot partition on this phone is 16MB, so use `xz` compression
  # as smaller than gzip

  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.usb = {
    mode = "gadgetfs";
    idVendor = "18D1";  # Google
    idProduct = "4EE7"; # something not "D001", to distinguish nixos from fastboot/lk2nd

    gadgetfs.functions = {
      rndis = "rndis.usb0";
      adb = "ffs.adb";
    };
  };

  mobile.system.type = "android";

  mobile.quirks.qualcomm = {
    wcnss-wlan.enable = true;
  };
}
