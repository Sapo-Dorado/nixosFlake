macInstall:
  home-manager switch --flake .#nicholas

configureShell:
  echo /Users/nicholas/.nix-profile/bin/bash | sudo tee -a /etc/shells
  chsh -s /Users/nicholas/.nix-profile/bin/bash

initialSetup: configureShell macInstall
