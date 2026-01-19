{
  description = "Pontus Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix/release-25.11";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";

    #nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim";
    #nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      stylix,
      nixgl,
      nixvim,
      ...
    }:
    let
      mkHome = import ./lib/mkHome.nix { inherit inputs; };
      mkNixos = import ./lib/mkNixos.nix { inherit inputs; };
      homeHostConfigs = import ./hosts/default.nix { inherit inputs mkHome; };
      nixosHostConfigs = import ./nixos/hosts/default.nix { inherit inputs mkNixos; };
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      lib.mkHome = mkHome;
      lib.mkNixos = mkNixos;
      homeConfigurations = homeHostConfigs;
      nixosConfigurations = nixosHostConfigs;

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          nixpkgsPath = inputs.nixpkgs.outPath;
          nixosConfig = ./nixos/hosts/nixos-shell.nix;
        in
        {
          nixos-shell = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "nixos-shell" ''
                exec ${pkgs.nixos-shell}/bin/nixos-shell \
                  -I nixpkgs=${nixpkgsPath} \
                  -I nixos-config=${toString nixosConfig} \
                  "$@"
              ''
            );
          };
        }
      );
    };
}
