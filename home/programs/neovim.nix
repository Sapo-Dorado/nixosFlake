{ pkgs, neovim, ... }: {
  home.packages = [ neovim.packages.${pkgs.system}.default ];
}
