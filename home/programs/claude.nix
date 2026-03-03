{ nixpkgs-unstable, system, ... }: {
  nixpkgs.config.allowUnfree = true;
  home.packages = [ nixpkgs-unstable.legacyPackages.${system}.claude-code ];
}
