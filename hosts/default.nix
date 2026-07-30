{ lib, system, home-manager, user, homeDirectory, neovim, nixpkgs-unstable, skillrunner, sapohub-config, disko, ...
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
        services.sapohub.assistant.provider = "anthropic";
        # Two RTX 2070 Supers (8GB VRAM each) live on this box — see
        # hosts/desktop/configuration.nix for the driver side (videoDrivers
        # = [ "nvidia" ], hardware.nvidia.*). This just controls how
        # toolsPkgs.llama-cpp itself gets built; --n-gpu-layers below is
        # what actually asks each model to offload onto them.
        services.sapohub.assistant.localModels.cudaSupport = true;
        services.sapohub.assistant.localModels.models.gpt-oss-20b = {
          weightsPath = "/mnt/storage/models/gpt-oss-20b-MXFP4.gguf";
          source = "https://huggingface.co/ggml-org/gpt-oss-20b-GGUF/resolve/main/gpt-oss-20b-MXFP4.gguf";
          # contextSize left at the module default (65536) — native context
          # is 128k and weights are only ~13GB, ample RAM headroom on this
          # 64GB box for the default-sized KV cache.
          # 999 asks to offload every layer; llama.cpp clamps to however
          # many actually fit across the 16GB combined VRAM and leaves the
          # rest on CPU, so this doesn't need to be tuned precisely.
          extraArgs = [ "--jinja" "--n-gpu-layers" "999" ];
        };
        # Borderline candidate: 80B total / 3B active (lower active-param
        # count than gpt-oss-20b, so similar or better generation speed is
        # plausible) but a newer hybrid linear-attention architecture and a
        # much bigger RAM footprint (~48GB) — the two real unknowns this
        # entry exists to test empirically rather than trust projected.
        services.sapohub.assistant.localModels.models.qwen3-coder-next = {
          weightsPath = "/mnt/storage/models/Qwen3-Coder-Next-Q4_K_M.gguf";
          source = "https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF/resolve/main/Qwen3-Coder-Next-Q4_K_M.gguf";
          # Overridden below the module default (65536): native context is
          # 256k, but weights alone are already ~48GB on this box's 64GB —
          # kept conservative until KV cache usage at a larger size is
          # confirmed not to OOM (watch llama-server's own KV buffer size
          # log line on first load).
          contextSize = 32768;
          extraArgs = [ "--jinja" "--n-gpu-layers" "999" ];
        };
        # 30.5B total / 3.3B active — similar active-param count to
        # gpt-oss-20b (so similar speed expected), standard attention
        # architecture (not the hybrid design that hurt qwen3-coder-next's
        # real-world speed), coding-specialized. 18.6GB, comfortable fit.
        services.sapohub.assistant.localModels.models.qwen3-coder-30b-a3b = {
          weightsPath = "/mnt/storage/models/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
          source = "https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
          # contextSize left at the module default (65536) — native context
          # is 256k and weights are ~18.6GB, comfortable headroom on this
          # 64GB box for the default-sized KV cache.
          extraArgs = [ "--jinja" "--n-gpu-layers" "999" ];
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

  # General-purpose profile for remote/headless boxes provisioned via
  # nixos-anywhere — see hosts/remote/configuration.nix and
  # scripts/remote-deploy.sh. Root-only (no "nicholas" account), so
  # user/homeDirectory are overridden to root/"/root" for this evaluation
  # only — home-manager below applies the same ../home (shell, git,
  # neovim, direnv, skillrunner, ...) as the desktop host, just to root's
  # own home instead.
  remote = lib.nixosSystem {
    inherit system;
    modules = [
      disko.nixosModules.disko
      ./remote/configuration.nix
      { _module.args = { user = "root"; homeDirectory = "/root"; }; }
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.root = {
            imports = [
              skillrunner.homeManagerModules.default
              ../home
              {
                _module.args = {
                  user = "root";
                  homeDirectory = "/root";
                  inherit system neovim nixpkgs-unstable skillrunner;
                };
              }
            ];
          };
        };
      }
    ];
  };
}
