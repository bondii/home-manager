{ inputs, mkHome }:
let
  user = {
    name = "pontus";
    homeDirectory = "/home/pontus";
    stateVersion = "25.05";
  };
  system = "x86_64-linux";
in let
  archDesktop = mkHome {
    inherit system user;
    hostName = "arch-desktop";
    features = {
      gui = true;
      dev = true;
      nixvim = true;
      vscode = true;
      fonts = true;
    };
  };

  sshMinimal = mkHome {
    inherit system user;
    hostName = "ssh-minimal";
    features = {
      gui = false;
      dev = true;
      nixvim = true;
      vscode = false;
      fonts = false;
    };
  };
in {
  "pontus" = archDesktop;
  "pontus@arch-desktop" = archDesktop;
  "pontus@ssh-minimal" = sshMinimal;
}
