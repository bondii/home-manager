{ inputs }:
{
  system,
  hostName,
  user,
  features ? { },
  extraModules ? [ ],
  extraSpecialArgs ? { },
}:
let
  inherit (inputs) nixpkgs home-manager;
  lib = nixpkgs.lib;
  homeModules = import ./homeModules.nix { inherit inputs features; };
in
lib.nixosSystem {
  inherit system;
  specialArgs = extraSpecialArgs // {
    inherit
      inputs
      features
      hostName
      user
      ;
  };
  modules =
    [
      ./../nixos/modules/base.nix
      ./../nixos/modules/gui.nix
      home-manager.nixosModules.home-manager
      ({ pkgs, ... }: {
        networking.hostName = hostName;

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit
              inputs
              features
              hostName
              user
              ;
          };
          users.${user.name} = {
            imports =
              homeModules
              ++ [
                {
                  home = {
                    username = user.name;
                    homeDirectory = user.homeDirectory;
                    stateVersion = user.stateVersion;
                  };
                }
              ];
          };
        };

        users.users.${user.name} = {
          isNormalUser = true;
          description = user.name;
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          shell = pkgs.zsh;
        };
      })
    ]
    ++ extraModules;
}
