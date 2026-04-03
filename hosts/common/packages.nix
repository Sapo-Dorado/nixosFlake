{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    cargo

    # Apps
    brave
    google-chrome
    obsidian
    wezterm

    # For neovim
    xclip
  ];
}
