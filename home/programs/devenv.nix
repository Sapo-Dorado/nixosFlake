{ nixpkgs-unstable, system, ... }: {
  home.packages = [ nixpkgs-unstable.legacyPackages.${system}.devenv ];
}
