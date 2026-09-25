{
  lib,
  hostName ? null,
  ...
}:
let
  defaultHost = if hostName == null then "default" else hostName;
  inherit (lib) mkDefault mkEnableOption;
in
{
  options.pontus = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = defaultHost;
      description = "Identifier for the current host configuration.";
    };

    features = {
      stylix = mkEnableOption "Stylix theming integration";
      gui = mkEnableOption "graphical applications and desktop services";
      dev = mkEnableOption "language servers and development tooling";
      nixvim = mkEnableOption "NixVim configuration";
      laptop = mkEnableOption "laptop specific configuration";
      fonts = mkEnableOption "additional font packages";
      vscode = mkEnableOption "VS Code / Cursor configuration";
    };
  };

  config.pontus.hostName = mkDefault defaultHost;
}
