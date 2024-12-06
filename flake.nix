{
  description = "Personal NixOS/Home-Manager Configuration";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim.url = "github:Sapo-Dorado/nixvim-config";
  };

  outputs = { nixpkgs, home-manager, neovim, ... }:
    let
      user = "nicholas";
      homeDirectory = "/home/${user}";
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations = import ./hosts {
        inherit (nixpkgs) lib;
        inherit pkgs user homeDirectory home-manager neovim;
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

      # For AWS
      homeConfigurations."${user}-linux" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit neovim;
            user = "ubuntu";
            homeDirectory = "/home/ubuntu";
          };
          modules = [ ./home {home.packages = [pkgs.lemonade]; }];
        };
    };
}
