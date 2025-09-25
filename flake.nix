{
  description = "Pontus Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixgl, nixvim, ... }:
    let
      mkHome = import ./lib/mkHome.nix inputs;
      hostConfigs = import ./hosts/default.nix { inherit inputs mkHome; };
    in {
      lib.mkHome = mkHome;
      homeConfigurations = hostConfigs;
    };
}
