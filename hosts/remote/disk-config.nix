# Disko partition layout for nixos-anywhere-provisioned remote boxes.
# BIOS/legacy GPT (works across most cloud-VPS hypervisors without
# depending on UEFI being exposed to the guest) — same layout SapoHub
# 2.0's own lib.mkFreshMachine uses for its fresh-machine path.
#
# remoteDiskDevice comes from disk-device.nix, written fresh by
# scripts/remote-deploy.sh on every run and gitignored — it's a throwaway
# record of which block device got wiped on one specific deploy, not
# something to keep in history. disk-device.example.nix is the committed
# fallback, used only so this flake evaluates (e.g. `nix flake check`)
# before the first real deploy.
{ ... }:
let
  diskDeviceFile =
    if builtins.pathExists ./disk-device.nix
    then ./disk-device.nix
    else ./disk-device.example.nix;
  inherit (import diskDeviceFile) remoteDiskDevice;
in
{
  disko.devices.disk.main = {
    device = remoteDiskDevice;
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        boot = { size = "1M"; type = "EF02"; };
        swap = { size = "2G"; content.type = "swap"; };
        root = {
          size = "100%";
          content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
        };
      };
    };
  };
}
