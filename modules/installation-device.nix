# Provide a basic configuration for installation devices like CDs.
{ config, pkgs, lib, ... }:

with lib;

{
  config = {

    # Enable in installer, even if the minimal profile disables it.
    documentation.enable = mkForce true;

    # Show the manual.
    documentation.nixos.enable = mkForce true;

    # Use less privileged nixos user
    users.users.nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "video" ];
      # Allow the graphical user to login without password
      initialHashedPassword = "";
    };

    # Allow the user to log in as root without a password.
    users.users.root.initialHashedPassword = "";

    # Allow passwordless sudo from nixos user
    security.sudo = {
      enable = mkDefault true;
      wheelNeedsPassword = mkForce false;
    };

    # We run sshd by default. Login via root is only possible after adding a
    # password via "passwd" or by adding a ssh key to /home/nixos/.ssh/authorized_keys.
    # The latter one is particular useful if keys are manually added to
    # installation device for head-less systems i.e. arm boards by manually
    # mounting the storage in a different system.
    services.openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    # Enable wpa_supplicant, but don't start it by default.
    networking.wireless.enable = mkDefault true;
    systemd.services.wpa_supplicant.wantedBy = mkOverride 50 [ ];

    # Tell the Nix evaluator to garbage collect more aggressively.
    # This is desirable in memory-constrained environments that don't
    # (yet) have swap set up.
    environment.variables.GC_INITIAL_HEAP_SIZE = "1M";

    # Make the installer more likely to succeed in low memory
    # environments.  The kernel's overcommit heustistics bite us
    # fairly often, preventing processes such as nix-worker or
    # download-using-manifests.pl from forking even if there is
    # plenty of free memory.
    boot.kernel.sysctl."vm.overcommit_memory" = "1";

    # To speed up installation a little bit, include the complete
    # stdenv in the Nix store on the CD.
    system.extraDependencies = with pkgs;
      [
        stdenvNoCC # for runCommand
        jq # for closureInfo
      ];

    # Show all debug messages from the kernel but don't log refused packets
    # because we have the firewall enabled. This makes installs from the
    # console less cumbersome if the machine has a public IP.
    networking.firewall.logRefusedConnections = mkDefault false;

    # Prevent installation media from evacuating persistent storage, as their
    # var directory is not persistent and it would thus result in deletion of
    # those entries.
    environment.etc."systemd/pstore.conf".text = ''
      [PStore]
      Unlink=no
    '';
  };
}
