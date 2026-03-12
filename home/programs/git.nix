{
  # Dotfiles
  programs.git = {
    enable = true;
    userName = "Nicholas Brown";
    userEmail = "sapodorado@proton.me";
    ignores = [ ".DS_Store" "*.pyc" "*.swp" ".env" ".venv" ];
    extraConfig = {
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };
}
