{
  description = "Personal NixOS/Home-Manager Configuration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim.url = "github:Sapo-Dorado/nixvim-config";
  };

  outputs = { nixpkgs, home-manager, neovim, ... }:
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
        inherit pkgs user homeDirectory system home-manager neovim;
      };

      # For Mac
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };

        extraSpecialArgs = {
          inherit neovim user;
          homeDirectory = "/Users/${user}";
        };
        modules = [ ./home ];
      };
    };
}
