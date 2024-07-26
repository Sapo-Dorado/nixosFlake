{ pkgs, ... }: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    cargo

    # Apps
    brave
    wezterm

    # For neovim
    xclip
  ];
}
