{ pkgs, user, ... }: {
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
