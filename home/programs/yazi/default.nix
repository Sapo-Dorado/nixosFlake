{ pkgs, lib, ... }@inputs: {
  home.packages = with pkgs; [ ffmpegthumbnailer unar jq poppler ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    settings = { theme = lib.importTOML ./themes/mocha.toml; };
  };

}
