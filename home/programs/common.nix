{ pkgs, ... }: {

  home.packages = with pkgs; [ fd ripgrep fzf just ];
}
