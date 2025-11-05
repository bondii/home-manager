{
  inputs,
  mkHome,
}:
let
  user = {
    name = "pontus";
    homeDirectory = "/home/pontus";
    stateVersion = "25.05";
  };
  system = "x86_64-linux";
in
let
  archDesktop = mkHome {
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
  };

  sshMinimal = mkHome {
    inherit system user;
    hostName = "ssh-minimal";
    features = {
      stylix = true;
      gui = false;
      dev = true;
      nixvim = true;
      laptop = false;
      fonts = false;
      vscode = false;
    };
  };
in
{
  "pontus" = archDesktop;
  "pontus@arch-desktop" = archDesktop;
  "pontus@ssh-minimal" = sshMinimal;
}
