{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapohub-config, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      sapohub-config.nixosModules.default
      {
        services.sapohub.deploy = {
          flakeAttr = "nixos";
          # This flake — not SapoHub-Config, which is just an imported
          # dependency here — is the outermost thing with a real
          # nixosConfigurations.nixos, so it's what sapohub-deploy must
          # clone/pull/rebuild. Without this override, deploy.repoUrl
          # silently inherits SapoHub-Config's own self-referential
          # default (its own repo URL, meant for ITS standalone `test`
          # host) — sapohub-deploy would then clone/rebuild the wrong
          # repo, which doesn't even define nixosConfigurations.nixos.
          repoUrl = "https://github.com/Sapo-Dorado/nixosFlake";
          # sapohub-config's own flake.lock pin on SapoHub-2.0 doesn't
          # get updated just because THIS flake's autoUpdateInputs runs —
          # nix's lockfile model keeps transitive pins as override
          # entries in the CONSUMING flake's own flake.lock (this one),
          # never by reaching into sapohub-config's separate repo. This
          # dotted path bumps that override directly. Same reasoning for
          # personal-modules: it's an input of sapohub-config, not of this
          # flake directly, so it needs its own dotted-path entry to ever
          # get bumped by a plain redeploy.
          # personal-modules temporarily dropped here — bootstrapping the
          # currently-installed sapohub-deploy's own auth fix for private
          # flake inputs first (see SapoHub-2.0 commit 6b989d1). Re-add
          # once a deploy has installed that fix, or this input update
          # will 404 unauthenticated against the private repo again.
          updateInputNames = [ "sapohub-config/sapohub" ];
        };
        services.sapohub.tailscale.enable = true;
        services.sapohub.nginx.https = true;
        # Previously inherited as a default from SapoHub-Config's own
        # nixosModules.default — moved here explicitly now that that
        # module no longer sets it (see SapoHub-Config's own history):
        # self-identity settings like this one shouldn't live in a
        # module meant to be imported by other configs.
        services.sapohub.assistant.browser.enable = true;
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
