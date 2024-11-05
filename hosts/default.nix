{ pkgs, lib, home-manager, user, homeDirectory, neovim, ... }: {
  nixos = lib.nixosSystem {
    inherit (pkgs) system;
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
              { _module.args = { inherit user homeDirectory neovim; }; }
            ];
          };
        };
      }
    ];
  };
}
