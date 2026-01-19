{
  inputs,
  mkNixos,
}:
let
  user = {
    name = "pontus";
    homeDirectory = "/home/pontus";
    stateVersion = "25.05";
  };
  system = "x86_64-linux";
in
{
  "arch-desktop" = mkNixos {
    inherit system user;
    hostName = "arch-desktop";
    features = {
      stylix = true;
      gui = true;
      dev = true;
      nixvim = true;
      laptop = true;
      fonts = true;
      vscode = true;
    };
    extraModules = [
      ./arch-desktop
    ];
  };

  "nixos-shell" = mkNixos {
    inherit system user;
    hostName = "nixos-shell";
    features = {
      stylix = false;
      gui = false;
      dev = true;
      nixvim = true;
      laptop = false;
      fonts = false;
      vscode = false;
    };
    extraModules = [
      ./nixos-shell.nix
    ];
  };
}
