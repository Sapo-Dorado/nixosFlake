{ pkgs, lib, system, home-manager, user, homeDirectory, neovim, ... }: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      (import ./desktop/configuration.nix { inherit pkgs user; })
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [
              ../home
              { _module.args = { inherit user homeDirectory neovim; }; }
            ];
          };
        };
      }
    ];
  };
}
