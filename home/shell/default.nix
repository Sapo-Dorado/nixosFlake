{ pkgs, ... }: {
  home.packages = with pkgs; [ bashInteractive eza dua ];
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      l = "eza";
      ld = "eza -lD";
      lf = "eza -lf --color=always | grep -v /";
      lh = "eza -dl .* --group-directories-first";
      ll = "eza -al --group-directories-first";
      lfs = "eza -alf --color=always --sort=size | grep -v /";
      lt = "eza -al --sort=modified";
    };

    shellOptions = [
      "histappend"
      "histverify"
      "checkwinsize"
      "globstar"
      "extglob"
      "checkjobs"
    ];

    historySize = 20000;
    historyFileSize = 200000;

    historyControl = [ "erasedups" "ignorespace" "ignoredups" ];
  };
}
