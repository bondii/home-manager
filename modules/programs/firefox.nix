{
  config,
  lib,
  ...
}: let
  cfg = config.pontus.features;
  desktopId = "firefox.desktop";
in {
  config = lib.mkIf cfg.gui {
    programs.firefox.enable = true;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = desktopId;
        "x-scheme-handler/http" = desktopId;
        "x-scheme-handler/https" = desktopId;
        "x-scheme-handler/about" = desktopId;
        "x-scheme-handler/unknown" = desktopId;
      };
    };
  };
}
