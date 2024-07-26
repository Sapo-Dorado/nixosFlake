{ pkgs, user, ... }: {
  imports = [ ./docker.nix ./packages.nix ./timezone.nix ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

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

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

}
