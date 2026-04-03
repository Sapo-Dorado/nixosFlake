{ pkgs, user, ... }: {
  imports = [ ./docker.nix ./packages.nix ./timezone.nix ];

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Enable the X11 windowing system.
  services = {
    displayManager.sddm.enable = true;

    # Auto-login on boot so SkillRunner Chrome skills have a graphical session.
    # SDDM's Relogin defaults to false, so this only triggers on boot —
    # manually logging out will show the normal login screen, not auto-login again.
    displayManager.autoLogin = {
      enable = true;
      user = user;
    };

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

  # Lock screen immediately after auto-login so the session is active
  # (for SkillRunner Chrome skills) but the screen stays locked.
  systemd.user.services.lock-on-login = {
    description = "Lock screen after auto-login";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
      ExecStart = "${pkgs.systemd}/bin/loginctl lock-session";
    };
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

}
