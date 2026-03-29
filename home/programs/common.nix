{ pkgs, ... }: {

  home.packages = with pkgs;
    [ fd ripgrep fzf just ]
    ++ (if pkgs.stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ]);
}
