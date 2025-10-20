{
  config,
  lib,
  ...
}: let
  cfg = config.pontus.features;
in
  lib.mkIf cfg.dev {
    xdg.configFile."yamllint/config".text = lib.generators.toYAML {} {
      extends = "default";
      rules = {
        comments."min-spaces-from-content" = 1;
      };
    };
  }
