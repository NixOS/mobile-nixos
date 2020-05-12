{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-potter";
  mobile.device.info = rec {
    format_version = "0";
    name = "Moto G5 Plus";
    manufacturer = "Motorola";
    date = "";
    modules_initfs = "";
    arch = "aarch64";
    keyboard = false;
    external_storage = true;
    screen_width = "1080";
    screen_height = "1920";
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";
    flash_method = "fastboot";
    kernel_cmdline = lib.concatStringsSep " " [
      "androidboot.console=ttyHSL0"
      "androidboot.hardware=qcom"
      "user_debug=30"
      "msm_rtb.filter=0x237"
      "ehci-hcd.park=3"
      "androidboot.bootdevice=7824900.sdhci"
      "lpm_levels.sleep_disabled=1"
      "vmalloc=350M"
      "buildvariant=userdebug"
    ];
    generate_bootimg = true;
    bootimg_qcdt = true;
    flash_offset_base = "0x80000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "2048";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    dtb = "${kernel}/dtbs/motorola-potter.img";
  };
  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.usb = {
    mode = "android_usb";
    # 18d1:4ee7 Google Inc. XT1685
    idVendor = "18D1"; idProduct = "4EE7";
  };
  mobile.system.type = "android";
}
