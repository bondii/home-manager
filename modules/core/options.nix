{ lib, config, hostName ? null, features ? {}, ... }:
let
  defaultHost = if hostName == null then "default" else hostName;
  inherit (lib) mkDefault mkEnableOption;
in {
  options.pontus = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = defaultHost;
      description = "Identifier for the current host configuration.";
    };

    features = {
      gui = mkEnableOption "graphical applications and desktop services" // { default = features.gui or true; };
      dev = mkEnableOption "language servers and development tooling" // { default = features.dev or true; };
      nixvim = mkEnableOption "NixVim configuration" // { default = features.nixvim or true; };
      vscode = mkEnableOption "VS Code / Cursor configuration" // { default = features.vscode or true; };
      fonts = mkEnableOption "additional font packages" // { default = features.fonts or true; };
    };
  };

  config.pontus.hostName = mkDefault defaultHost;
}
