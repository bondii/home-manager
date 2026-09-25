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
    nixvim
    stylix
    ;
  inherit (nixpkgs) lib;
  # nixGL still reads `final.system` in its overlay; nixpkgs keeps `system` as a
  # warning alias, so provide a non-warning compat attr here.
  # ToDo: Remove this once nixGL stops reading `final.system`.
  systemCompatOverlay = _final: prev: {
    system = prev.stdenv.hostPlatform.system;
  };
  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      systemCompatOverlay
      nixgl.overlay
    ];
  };
  baseModules = [
    ./../modules/core/options.nix
    ./../modules/core/base.nix
    ./../modules/programs/git.nix
    ./../modules/programs/zsh.nix
    ./../modules/programs/ssh.nix
    ./../modules/programs/fzf.nix
    ./../modules/programs/starship.nix
    ./../modules/programs/yamllint.nix
    ./../modules/features/dev.nix
    ./../modules/features/gui.nix
    ./../modules/programs/firefox.nix
    ./../modules/programs/vscode.nix
    ./../modules/features/stylix.nix
    stylix.homeModules.stylix
    nixvim.homeModules.nixvim
    ./../modules/programs/nvim.nix
    ./../modules/features/laptop.nix
  ];
  featureModule = {
    pontus = {
      inherit hostName;
      features = lib.mapAttrs (_: lib.mkDefault) features;
    };
  };
  userModule = {
    home = {
      username = user.name;
      inherit (user) homeDirectory stateVersion;
    };
  };
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules =
    baseModules
    ++ [
      featureModule
      userModule
    ]
    ++ extraModules;
  extraSpecialArgs = extraSpecialArgs // {
    # Compatibility only: consumers must use config.pontus.features for the
    # resolved values, which also include extraModules overrides.
    inherit
      inputs
      features
      hostName
      user
      ;
  };
}
