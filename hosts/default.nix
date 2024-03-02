{ pkgs, lib, system, home-manager, user, ...}:
{
  nixos = lib.nixosSystem {
    inherit system;
    modules = [
      (import ./desktop/configuration.nix {
        inherit user pkgs;
      })
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = {
  	  imports = [ (import ./desktop/home.nix {
	    inherit user pkgs;
	  }) ];
        };
      }
    ];
  };
}
