{ pkgs, lib, ... }@inputs: {
  home = {
    packages = with pkgs; [ yazi ffmpegthumbnailer unar jq poppler ];
    file = { ".config/yazi/yazi.toml".source = ./config/yazi.toml; };
  };

}
