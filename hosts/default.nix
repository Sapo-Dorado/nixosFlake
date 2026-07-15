{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapohub-config, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      sapohub-config.nixosModules.default
      {
        services.sapohub.deploy.flakeAttr = "nixos";
        services.sapohub.tailscale.enable = true;
        services.sapohub.nginx.https = true;
      }
      { _module.args = { inherit user homeDirectory; }; }
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [
              skillrunner.homeManagerModules.default
              ../home
              {
                _module.args = {
                  inherit user system homeDirectory neovim nixpkgs-unstable skillrunner;
                };
              }
            ];
          };
        };
      }
    ];
  };
}
