{
  description = "Pontus Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix/release-26.05";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";

    #nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    nixvim.url = "github:nix-community/nixvim";
    #nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # Pinned to the release whose Claude Code plugin hooks match this binary.
    worktrunk.url = "github:max-sixty/worktrunk/v0.81.0";
  };

  outputs =
    inputs:
    let
      mkHome = import ./lib/mkHome.nix { inherit inputs; };
      hostConfigs = import ./hosts/default.nix { inherit inputs mkHome; };
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      lib.mkHome = mkHome;
      homeConfigurations = hostConfigs;
      formatter.${system} = pkgs.nixfmt;
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt
          statix
          deadnix
          shellcheck
          python3
        ];
      };
      checks.${system} = import ./tests/checks.nix { inherit pkgs hostConfigs mkHome; };
    };
}
