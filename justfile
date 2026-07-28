macInstall:
  home-manager switch --flake .#nicholas

linuxInstall:
  home-manager switch --flake .#nicholas-linux

remoteDeploy ip *args:
  ./scripts/remote-deploy.sh {{ip}} {{args}}

configureShell:
  echo /Users/nicholas/.nix-profile/bin/bash | sudo tee -a /etc/shells
  chsh -s /Users/nicholas/.nix-profile/bin/bash

initialSetup: configureShell macInstall
