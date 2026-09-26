{
  pkgs,
  hostConfigs,
  mkHome,
}:
let
  source = pkgs.lib.cleanSource ../.;
  featureChecks = import ./features.nix {
    inherit (pkgs) lib;
    inherit mkHome hostConfigs;
  };
  activation = hostConfigs."pontus@arch-desktop".config.home.activation;
  helper =
    name:
    pkgs.lib.findFirst (
      p: pkgs.lib.getName p == name
    ) (throw "Missing helper ${name}") hostConfigs."pontus@arch-desktop".config.home.packages;
  zshInit =
    pkgs.writeText "zsh-init.zsh"
      hostConfigs."pontus@arch-desktop".config.programs.zsh.initContent;
  customHooks = pkgs.writeText "custom-activation.json" (
    builtins.toJSON {
      inherit (activation) createNpmPrefix createNvimUndoDir;
    }
  );
in
{
  desktop = hostConfigs."pontus@arch-desktop".activationPackage;
  ssh = hostConfigs."pontus@ssh-minimal".activationPackage;
  helpers =
    pkgs.runCommand "check-helpers"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.zsh
          pkgs.coreutils
          hostConfigs."pontus@arch-desktop".config.programs.git.package
        ];
      }
      ''
        python ${./test_helpers.py} ${helper "sf"}/bin/sf ${helper "sg"}/bin/sg ${helper "sfg"}/bin/sfg ${helper "opac-wt"}/bin/opac-wt
        python ${./test_zsh_helpers.py} ${zshInit}
        touch "$out"
      '';
  features =
    assert featureChecks;
    pkgs.runCommand "check-features" { } ''touch "$out"'';
  activation = pkgs.runCommand "check-activation" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python ${./test_activation.py} ${customHooks} ${pkgs.bash}/bin/bash
    touch "$out"
  '';
  locking =
    pkgs.runCommand "check-locking"
      {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.bash
          pkgs.coreutils
          pkgs.shellcheck
        ];
      }
      ''
        cp -r ${source} source
        chmod -R u+w source
        cd source
        shellcheck lib/lock-pixel.sh
        python -W error::ResourceWarning -m unittest -v tests/test_lock.py
        touch "$out"
      '';
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
