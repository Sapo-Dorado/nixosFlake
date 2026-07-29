# Disko partition layout for nixos-anywhere-provisioned remote boxes.
# Supports both UEFI (ESP at /boot/efi) and legacy/BIOS (EF02 boot
# partition) GPT layouts, picked via boot-mode.nix — see
# scripts/remote-deploy.sh's --boot-mode option. Some hypervisors expose
# UEFI firmware to the guest, some don't; there's no single scheme that
# boots everywhere.
#
# remoteDiskDevice/remoteBootMode come from disk-device.nix/boot-mode.nix,
# written fresh by scripts/remote-deploy.sh on every run and gitignored —
# they're throwaway records of one specific deploy, not something to keep
# in history. The *.example.nix files are the committed fallbacks, used
# only so this flake evaluates (e.g. `nix flake check`) before the first
# real deploy.
{ ... }:
let
  diskDeviceFile =
    if builtins.pathExists ./disk-device.nix
    then ./disk-device.nix
    else ./disk-device.example.nix;
  inherit (import diskDeviceFile) remoteDiskDevice;

  bootModeFile =
    if builtins.pathExists ./boot-mode.nix
    then ./boot-mode.nix
    else ./boot-mode.example.nix;
  inherit (import bootModeFile) remoteBootMode;

  bootPartition =
    if remoteBootMode == "uefi"
    then {
      size = "512M";
      type = "EF00";
      content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot/efi"; };
    }
    else { size = "1M"; type = "EF02"; };
in
{
  disko.devices.disk.main = {
    device = remoteDiskDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = bootPartition;
        swap = { size = "2G"; content.type = "swap"; };
        root = {
          size = "100%";
          content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
        };
      };
    };
  };
}
