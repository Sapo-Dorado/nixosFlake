#!/usr/bin/env bash
set -euo pipefail

# Provision a remote/headless box from scratch via nixos-anywhere, using
# this flake's nixosConfigurations.remote (hosts/remote/configuration.nix
# — general dev setup: docker, common packages, mosh/ssh, home-manager for
# root). Modeled on SapoHub 2.0's own scripts/bootstrap.sh, but simpler:
# one reusable "remote" host (not one nixosConfigurations attr per
# hostname) and the generated hardware-configuration.nix/disk-device.nix/
# boot-mode.nix are deliberately NEVER committed — see the "Hardware
# config" note below.
#
# The target machine needs to already be reachable over SSH as root and
# booted into SOME NixOS-based environment (the official installer ISO, or
# an existing install you're willing to wipe) — nixos-anywhere does the
# rest: partitions the disk (disko), builds the closure, and switches the
# target over to it, rebooting once along the way.
#
# Usage:
#   ./scripts/remote-deploy.sh <ip> [options]
#
# Options:
#   --disk <device>       Target disk device to partition, e.g. /dev/sda,
#                          /dev/vda, /dev/nvme0n1 (default: /dev/sda —
#                          check with `ssh root@<ip> lsblk` if unsure).
#   --boot-mode <mode>     "uefi" or "legacy" (default: uefi). Some
#                          hypervisors only expose BIOS/legacy boot to the
#                          guest — if the box fails to boot after a UEFI
#                          install (or vice versa), retry with the other.
#   --ssh-user <user>      SSH user on the target (default: root).
#
# Hardware config: nixos-anywhere generates this machine's
# hardware-configuration.nix locally (via --generate-hardware-config) and
# makes it visible to the flake evaluation itself, with `git add
# --intent-to-add` — that's a nixos-anywhere-internal step, not something
# this script does. This script does the equivalent by hand for
# disk-device.nix (which IT writes, before nixos-anywhere ever runs) so
# disko can see the real disk device during the same build.
#
# Unlike bootstrap.sh in SapoHub 2.0, neither generated file gets
# committed here — both are gitignored, and this script unstages
# (`git reset`) them again once nixos-anywhere finishes, success or not,
# so nothing sits staged for an unrelated future commit to sweep up.
# They're real facts about whatever's live at <ip> right now, not
# something worth keeping in history; hosts/remote/*.example.nix are the
# committed fallbacks that keep the flake evaluable without them.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET_IP=""
DISK_DEVICE="/dev/sda"
BOOT_MODE="uefi"
SSH_USER="root"

usage() {
  echo "usage: $0 <ip> [--disk <device>] [--boot-mode uefi|legacy] [--ssh-user <user>]" >&2
  exit 1
}

[ $# -ge 1 ] || usage
TARGET_IP="$1"; shift

while [ $# -gt 0 ]; do
  case "$1" in
    --disk) DISK_DEVICE="$2"; shift 2 ;;
    --boot-mode) BOOT_MODE="$2"; shift 2 ;;
    --ssh-user) SSH_USER="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
done

case "$BOOT_MODE" in
  uefi|legacy) ;;
  *) echo "invalid --boot-mode: ${BOOT_MODE} (must be uefi or legacy)" >&2; exit 1 ;;
esac

echo "== remote-deploy =="
echo "target:       ${SSH_USER}@${TARGET_IP}"
echo "flake attr:   remote"
echo "disk device:  ${DISK_DEVICE}"
echo "boot mode:    ${BOOT_MODE}"
echo ""

HW_DIR="$REPO_ROOT/hosts/remote"
GENERATED_HW_CONFIG="$HW_DIR/hardware-configuration.nix"
GENERATED_DISK_DEVICE="$HW_DIR/disk-device.nix"
GENERATED_BOOT_MODE="$HW_DIR/boot-mode.nix"

cleanup_git_index() {
  # Unstage regardless of how we exit — see "Hardware config" above.
  git -C "$REPO_ROOT" reset -- "$GENERATED_DISK_DEVICE" "$GENERATED_HW_CONFIG" "$GENERATED_BOOT_MODE" >/dev/null 2>&1 || true
}
trap cleanup_git_index EXIT

cat > "$GENERATED_DISK_DEVICE" <<NIXEOF
{
  remoteDiskDevice = "${DISK_DEVICE}";
}
NIXEOF
echo "wrote $(basename "$GENERATED_DISK_DEVICE") (${DISK_DEVICE})"

cat > "$GENERATED_BOOT_MODE" <<NIXEOF
{
  remoteBootMode = "${BOOT_MODE}";
}
NIXEOF
echo "wrote $(basename "$GENERATED_BOOT_MODE") (${BOOT_MODE})"

# Make them visible to the flake evaluation without staging real content
# for a future commit — same trick nixos-anywhere itself uses internally
# for the hardware-config file below.
git -C "$REPO_ROOT" add --intent-to-add -f "$GENERATED_DISK_DEVICE" "$GENERATED_BOOT_MODE"

echo ""
echo "starting nixos-anywhere (this partitions ${DISK_DEVICE} on ${TARGET_IP} — DESTRUCTIVE, double-check the IP and disk device now)..."
echo "if you haven't already, sanity-check the target's disk device: ssh ${SSH_USER}@${TARGET_IP} lsblk"
echo ""
read -r -p "Type the target IP again to confirm (${TARGET_IP}): " CONFIRM_IP
if [ "$CONFIRM_IP" != "$TARGET_IP" ]; then
  echo "confirmation didn't match — aborting, nothing was touched." >&2
  exit 1
fi

nix run github:nix-community/nixos-anywhere -- \
  --flake "${REPO_ROOT}#remote" \
  --generate-hardware-config nixos-generate-config "$GENERATED_HW_CONFIG" \
  "${SSH_USER}@${TARGET_IP}"

echo ""
echo "waiting for the target to come back up after install..."
# Fresh final NixOS system generates its own host key, different from the
# kexec/installer environment's — drop the old entry so the reconnect
# below gets a clean accept-new instead of failing every retry.
ssh-keygen -R "$TARGET_IP" >/dev/null 2>&1 || true
RECONNECTED=""
for _ in $(seq 1 30); do
  if ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "${SSH_USER}@${TARGET_IP}" true 2>/dev/null; then
    RECONNECTED="1"
    break
  fi
  sleep 5
done

echo ""
echo "== remote-deploy complete =="
if [ -n "$RECONNECTED" ]; then
  echo "reconnected to ${SSH_USER}@${TARGET_IP} — the box is back up."
else
  echo "NOTE: couldn't reconnect within 150s — it may still be coming up; retry ssh by hand." >&2
fi
echo "hardware-configuration.nix / disk-device.nix are left on local disk (gitignored, unstaged) — keep them around, future rebuilds of THIS box still need them; they'll just be overwritten if you ever re-run this script against it."
echo "Future redeploys of this same box (no reinstall): ssh ${SSH_USER}@${TARGET_IP}, then \`nixos-rebuild switch --flake ${REPO_ROOT}#remote --target-host ${SSH_USER}@${TARGET_IP}\` from here."
