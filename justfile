macInstall:
  rm -f ~/.config/nvim/lazy-lock.json
  home-manager switch -f ./home.nix
  rm ~/.config/nvim/lazy-lock.json
