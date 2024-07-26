{
  # Dotfiles
  programs.git = {
    enable = true;
    userName = "Nicholas Brown";
    userEmail = "nobrown@sbcglobal.net";
    ignores = [ ".DS_Store" "*.pyc" "*.swp" ];
    extraConfig = {
      url."ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };
}
