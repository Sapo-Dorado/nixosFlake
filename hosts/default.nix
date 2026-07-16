{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapohub-config, ...
}: {
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      ./desktop/configuration.nix
      sapohub-config.nixosModules.default
      # Machine-owned, written by `sapohub-deploy --sync-prefs` into
      # .sapohub/sapohub-prefs.nix at THIS repo's own root — this flake is
      # deploy.repoUrl/flakePath's target (see below), not SapoHub-Config,
      # so this is the copy that's actually kept in sync. No stub needs to
      # exist up front; pathExists just skips it until the first sync.
    ] ++ lib.optional (builtins.pathExists ../.sapohub/sapohub-prefs.nix) ../.sapohub/sapohub-prefs.nix ++ [
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
          # get bumped by a plain redeploy. (Bootstrapped in two steps —
          # see SapoHub-2.0 commit 6b989d1 for the auth fix this needed
          # before a private input could be added here safely.) The bare
          # "sapohub-config" entry bumps THAT repo's own commit too — left
          # out once before, which meant a fix landed in SapoHub-Config
          # could sit unused indefinitely since a plain redeploy never
          # pulled a newer pin for it.
          updateInputNames = [ "sapohub-config" "sapohub-config/sapohub" "sapohub-config/personal-modules" ];
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
