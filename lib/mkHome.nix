{inputs}: {
  system,
  user,
  hostName,
  features ? {},
  extraModules ? [],
  extraSpecialArgs ? {},
}: let
  inherit (inputs) nixpkgs home-manager nixgl nixvim stylix;
  lib = nixpkgs.lib;
  pkgs = import nixpkgs {
    inherit system;
    overlays = [nixgl.overlay];
  };
  stylixEnabled = features.stylix or false;
  baseModules =
    [
      ./../modules/core/options.nix
      ./../modules/core/base.nix
      ./../modules/programs/git.nix
      ./../modules/programs/zsh.nix
      ./../modules/programs/ssh.nix
      ./../modules/programs/fzf.nix
      ./../modules/programs/starship.nix
      ./../modules/features/dev.nix
      ./../modules/features/gui.nix
      ./../modules/features/laptop.nix
      ./../modules/programs/vscode.nix
    ]
    ++ lib.optionals stylixEnabled [
      ./../modules/features/stylix.nix
      stylix.homeModules.stylix
    ]
    ++ lib.optionals (features.nixvim or true) [
      nixvim.homeModules.nixvim
      ./../modules/programs/nvim.nix
    ];
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
    modules = baseModules ++ [featureModule userModule] ++ extraModules;
    extraSpecialArgs = extraSpecialArgs // {inherit inputs features hostName user;};
  }
