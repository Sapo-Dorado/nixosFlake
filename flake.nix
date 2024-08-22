{
  description = "Personal NixOS/Home-Manager Configuration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim.url = "github:Sapo-Dorado/nixvim-config";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, neovim, ... }:
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
          nixpkgs-unstable;
      };

      # For Mac
      homeConfigurations.${user} = let mac-system = "aarch64-darwin";
      in home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = mac-system;
          config.allowUnfree = true;
        };

        extraSpecialArgs = {
          inherit neovim user nixpkgs-unstable;
          system = mac-system;
          homeDirectory = "/Users/${user}";
        };
        modules = [ ./home ];
      };
    };
}
