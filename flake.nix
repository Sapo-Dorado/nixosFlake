{
  description = "Personal NixOS/Home-Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim.url = "github:Sapo-Dorado/nixvim-config";
    skillrunner = {
      url = "github:Sapo-Dorado/Scheduler";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, neovim, skillrunner, ... }:
    let
      user = "nicholas";
      homeDirectory = "/home/${user}";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = import ./hosts {
        inherit (nixpkgs) lib;
        inherit pkgs user homeDirectory system home-manager neovim
          nixpkgs-unstable skillrunner;
      };

      # For Mac
      homeConfigurations.${user} = let mac-system = "aarch64-darwin";
      in home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = mac-system;
          config.allowUnfree = true;
        };

        extraSpecialArgs = {
          inherit neovim user nixpkgs-unstable skillrunner;
          system = mac-system;
          homeDirectory = "/Users/${user}";
        };
        modules = [ skillrunner.homeManagerModules.default ./home ];
      };

      homeConfigurations."${user}-hetzner" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };

        extraSpecialArgs = {
          inherit neovim nixpkgs-unstable skillrunner;
          user = "root";
          system = "x86_64-linux";
          homeDirectory = "/root";
        };
        modules = [ skillrunner.homeManagerModules.default ./home ];
      };
    };
}
