{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapo-hub, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      sapo-hub.nixosModules.default
      {
        services.sapo-hub = {
          enable = true;
          host = "nixos.tailee43b7.ts.net";
          scheme = "http";
          secretsFile = "/etc/sapo_hub/secrets";
          sshKeyFile = "/etc/sapo_hub/id_ed25519";
        };

        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;

          virtualHosts."nixos.tailee43b7.ts.net" = {
            locations."/" = {
              proxyPass = "http://127.0.0.1:4000";
              proxyWebsockets = true;
            };
          };
        };

        services.tailscale.enable = true;

        networking.firewall = {
          allowedTCPPorts = [ 80 ];
          trustedInterfaces = [ "tailscale0" ];
        };
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
