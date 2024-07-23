{ pkgs, ... }@inputs: {
  home.packages = with pkgs; [ ffmpegthumbnailer unar jq poppler ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
    settings = {
      open = {
        prepend_rules = [{
          name = "*/";
          use = [ "nvim" "open" ];
        }];
      };
      opener = {
        nvim = [{
          run = ''cd "$@" && nvim .'';
          block = true;
          desc = "nvim";
        }];
      };

    };
  };

}
