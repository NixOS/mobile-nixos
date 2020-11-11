{ config, lib, pkgs, ... }:

{
  imports = [
    ./modem.nix
  ];

  nixpkgs.overlays = [
    (import ./overlay)
  ];

  mobile.device.name = "pine64-pinephone";
  mobile.device.identity = {
    name = "PinePhone";
    manufacturer = "Pine64";
  };

  mobile.hardware = {
    soc = "allwinner-a64";
    ram = 1024 * 2;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  boot.kernelParams = [
    # Serial console on ttyS0, using the serial headphone adapter.
    "console=ttyS0,115200"
    "vt.global_cursor_default=0"
    "earlycon=uart,mmio32,0x01c28000"
    "panic=10"
    "consoleblank=0"
  ];

  mobile.system.type = "u-boot";

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.quirks.u-boot.package = pkgs.callPackage ./u-boot {};
  mobile.quirks.u-boot.additionalCommands = ''
    # Yellow LED.
    gpio set 115   # R
    gpio set 114   # G
    gpio clear 116 # B
  '';
}
