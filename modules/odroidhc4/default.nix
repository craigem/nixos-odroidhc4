{ pkgs, config, lib, modulesPath, ... }:
with lib; {
  imports = [ ../uboot/hardkernel-uboot.nix ];
  # The linux kernel used is compiled from the Hardkernel fork of
  # torvalds/linux
  boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_hardkernel;

  boot.initrd.availableKernelModules = mkForce [ ];

  # Remove zfs from supported filesystems as it fails due to not being able to
  # build the kernel module
  boot.supportedFilesystems =
    lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];

  # We do know the hardware we are planning to deploy to
  hardware.enableRedistributableFirmware = mkForce false;

  nixpkgs.overlays = [
    (import ../../overlays/kernel/overlay.nix)
    (import ../../overlays/uboot/overlay.nix)
  ];

  # Bootloader (use Hardkernel fork of Das U-Boot)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = false;
  boot.loader.hardkernel-uboot.enable = true;

  # SSH
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Add public SSH key to root user's authorized_keys file
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDtjE0YstRzlh+Zhlj03th9DYOkMqJ5xHUcderBq151K craige@mcwhirter.io"
  ];

  # DNS
  services.resolved.enable = true;
  services.resolved.dnssec = "false";

  # set a default root password
  users.users.root.initialPassword = "toor";

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
