# Fallback hardware config, used only so this flake evaluates (e.g. `nix
# flake check`) before the first real deploy. DO NOT DEPLOY WITH THIS FILE
# — it's a generic virtio/qemu-guest placeholder, not real hardware.
#
# scripts/remote-deploy.sh generates the real hardware-configuration.nix
# automatically via nixos-anywhere's --generate-hardware-config (which
# SSHes into the target, runs nixos-generate-config THERE, and copies the
# result back here) before every real install. That file is gitignored —
# never commit it, it's specific to whatever box happened to be at the
# deployed IP.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Filesystem mounts are managed by disko — see disk-config.nix.

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
