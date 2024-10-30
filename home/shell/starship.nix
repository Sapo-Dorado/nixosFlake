{
  programs.starship = {
    enable = true;
    settings = {
      format = ''
        $username$hostname$directory$git_branch$git_commit$git_state$git_status$nix_shell$direnv$python$env_var$line_break$character
      '';
      directory = { truncation_length = 5; };
      python = { format = "[(via \\($virtualenv\\))]($style)"; };

    };
  };

}
