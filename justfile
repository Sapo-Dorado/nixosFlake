macInstall:
  home-manager switch --flake .#nicholas

linuxInstall:
  home-manager switch --flake .#nicholas-linux

configureShell:
  echo /Users/nicholas/.nix-profile/bin/bash | sudo tee -a /etc/shells
  chsh -s /Users/nicholas/.nix-profile/bin/bash

initialSetup: configureShell macInstall
