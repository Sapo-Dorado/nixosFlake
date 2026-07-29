# General-purpose NixOS profile for remote/headless boxes provisioned via
# nixos-anywhere (see scripts/remote-deploy.sh at the repo root). Root-only
# by design — no separate normal user, matching how these boxes are
# actually driven (SSH straight in as root; home-manager below is applied
# to /root's own home, wired up in hosts/default.nix).
#
# Reuses the genuinely-shared pieces of hosts/common (docker, general dev
# packages, timezone/locale) but deliberately skips hosts/common/core.nix
# (creates the "nicholas" desktop account — not wanted here) and anything
# desktop-only (hosts/desktop/desktop.nix: X11/SDDM/Plasma/audio/printing).
{ lib, ... }:
let
  hardwareConfigPath =
    if builtins.pathExists ./hardware-configuration.nix
    then ./hardware-configuration.nix
    else ./hardware-configuration.example.nix;

  bootModeFile =
    if builtins.pathExists ./boot-mode.nix
    then ./boot-mode.nix
    else ./boot-mode.example.nix;
  inherit (import bootModeFile) remoteBootMode;

  diskDeviceFile =
    if builtins.pathExists ./disk-device.nix
    then ./disk-device.nix
    else ./disk-device.example.nix;
  inherit (import diskDeviceFile) remoteDiskDevice;
in
{
  imports = [
    ../common/docker.nix
    ../common/packages.nix
    ../common/timezone.nix
    ./disk-config.nix
    hardwareConfigPath
  ];

  # GRUB, UEFI or legacy/BIOS depending on boot-mode.nix — see
  # disk-config.nix's header comment. efiInstallAsRemovable writes the
  # fallback /EFI/BOOT/BOOTX64.EFI path instead of registering an NVRAM
  # boot entry, since VPS/cloud UEFI firmware support for NVRAM writes
  # from the guest is inconsistent.
  boot.loader.efi.efiSysMountPoint = lib.mkIf (remoteBootMode == "uefi") "/boot/efi";

  boot.loader.grub =
    {
      enable = true;
      default = 0;
      configurationLimit = 5;
    }
    // (
      if remoteBootMode == "uefi"
      then {
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
      }
      else {
        efiSupport = false;
        device = remoteDiskDevice;
      }
    );

  networking = {
    hostName = "remote";
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 22 ];
    firewall.allowedUDPPortRanges = [{ from = 60000; to = 61000; }];
  };

  # Mosh (mobile shell — resilient remote terminal over UDP), same as desktop.
  programs.mosh.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Key-only root SSH access — this is the one thing that must be baked in
  # before a wipe-and-reinstall, since it's how you get back in afterward.
  # CHANGE ME if you rotate keys; scripts/remote-deploy.sh doesn't seed one
  # separately.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW8DZZYK2k5aOg8f/dfscXLG9bOLLzTU/6h8uWP5Rrw"
  ];

  system.stateVersion = "24.11";
}
