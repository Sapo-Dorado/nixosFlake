# Desktop-only pieces split out of hosts/common so that config could stay
# genuinely shared between the desktop host and headless remote boxes
# (hosts/remote) — GUI/display-manager/audio/printing stuff has no
# business on a box provisioned via nixos-anywhere.
{ pkgs, user, ... }: {
  users.users.${user}.extraGroups = [ "networkmanager" ];

  # Enable the X11 windowing system.
  services = {
    displayManager.sddm.enable = true;

    xserver = {
      enable = true;
      # Enable the KDE Plasma Desktop Environment.
      desktopManager.plasma5.enable = true;

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
        options = "ctrl:nocaps";
      };
    };
    printing.enable = true;
  };

  # Disable KWallet so Chrome/Brave don't trigger unlock popups
  environment.etc."xdg/kwalletrc".text = ''
    [Wallet]
    Enabled=false
    First Use=false
  '';

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    brave
    google-chrome
    obsidian
    wezterm

    # For neovim
    xclip
  ];
}
