{ pkgs, neovim, user, homeDirectory, ... }:

{
  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "${user}";
    inherit homeDirectory;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = [ neovim.packages.${pkgs.system}.default pkgs.ripgrep ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = { ".wezterm.lua".source = ./dotfiles/wezterm.lua; };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    # either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/nicholas/etc/profile.d/hm-session-vars.sh
    #
    sessionVariables = {
      # EDITOR = "emacs";
    };
  };

  # Dotfiles
  programs.git = {
    enable = true;
    userName = "Nicholas Brown";
    userEmail = "nobrown@sbcglobal.net";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
