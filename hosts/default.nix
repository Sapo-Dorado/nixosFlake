{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      { _module.args = { inherit user homeDirectory; }; }
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [
              ../home
              {
                _module.args = {
                  inherit user system homeDirectory neovim nixpkgs-unstable;
                };
              }
            ];
          };
        };
      }
    ];
  };
}
