{ pkgs, lib, system, home-manager, user, homeDirectory, neovim, ... }:
{
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      (import ./desktop/configuration.nix {
        inherit pkgs user;
      })
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = {
          imports = [
            (import ../home.nix {
              inherit pkgs user homeDirectory neovim;
            })
          ];
        };
      }
    ];
  };
}
