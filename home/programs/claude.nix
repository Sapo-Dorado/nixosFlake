{ nixpkgs-unstable, system, ... }:
let
  pkgs-unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in {
  home.packages = [ pkgs-unstable.claude-code ];
}
