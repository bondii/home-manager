{ inputs }:
{
  system,
  user,
  hostName,
  features ? { },
  extraModules ? [ ],
  extraSpecialArgs ? { },
}:
let
  inherit (inputs)
    nixpkgs
    home-manager
    nixgl
    ;
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ nixgl.overlay ];
  };
  homeModules = import ./homeModules.nix { inherit inputs features; };
  featureModule = {
    pontus = {
      inherit hostName;
      features = features;
    };
  };
  userModule = {
    home = {
      username = user.name;
      homeDirectory = user.homeDirectory;
      stateVersion = user.stateVersion;
    };
  };
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules =
    homeModules
    ++ [
      featureModule
      userModule
    ]
    ++ extraModules;
  extraSpecialArgs = extraSpecialArgs // {
    inherit
      inputs
      features
      hostName
      user
      ;
  };
}
