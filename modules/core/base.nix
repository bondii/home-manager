{ config, lib, pkgs, ... }:
let
  cfg = config.pontus.features;
in {
  config = lib.mkMerge [
    {
      programs.home-manager.enable = true;
      nixpkgs.config.allowUnfree = true;
      xdg.enable = true;

      home.sessionPath = [ "${config.home.homeDirectory}/.nix-profile/bin" ];
      home.sessionVariables = {
        XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share";
      };

      services.ssh-agent.enable = true;
    }

    (lib.mkIf cfg.nixvim {
      home.activation.createNvimUndoDir = lib.mkAfter ''
        mkdir -p "${config.xdg.cacheHome}/nvim/undo"
      '';
      home.sessionVariables.SUDO_EDITOR = "${config.home.homeDirectory}/.nix-profile/bin/nvim";
    })

    (lib.mkIf cfg.fonts {
      fonts.fontconfig.enable = true;
    })
  ];
}
