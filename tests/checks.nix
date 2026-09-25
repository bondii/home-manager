{ pkgs, hostConfigs }:
let
  source = pkgs.lib.cleanSource ../.;
in
{
  desktop = hostConfigs."pontus@arch-desktop".activationPackage;
  ssh = hostConfigs."pontus@ssh-minimal".activationPackage;
  formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
    cd ${source}
    find . -name '*.nix' -print0 | xargs -0 nixfmt --check
    touch "$out"
  '';
  lint =
    pkgs.runCommand "check-lint"
      {
        nativeBuildInputs = [
          pkgs.statix
          pkgs.deadnix
        ];
      }
      ''
        cd ${source}
        statix check .
        deadnix --fail .
        touch "$out"
      '';
}
