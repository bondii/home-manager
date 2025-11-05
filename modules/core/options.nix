{
  lib,
  config,
  hostName ? null,
  features ? { },
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
      stylix = mkEnableOption "Stylix theming integration" // {
        default = features.stylix or true;
      };
      gui = mkEnableOption "graphical applications and desktop services" // {
        default = features.gui or true;
      };
      dev = mkEnableOption "language servers and development tooling" // {
        default = features.dev or true;
      };
      nixvim = mkEnableOption "NixVim configuration" // {
        default = features.nixvim or true;
      };
      laptop = mkEnableOption "laptop specific configuration" // {
        default = features.laptop or false;
      };
      fonts = mkEnableOption "additional font packages" // {
        default = features.fonts or true;
      };
      vscode = mkEnableOption "VS Code / Cursor configuration" // {
        default = features.vscode or true;
      };
    };
  };

  config.pontus.hostName = mkDefault defaultHost;
}
