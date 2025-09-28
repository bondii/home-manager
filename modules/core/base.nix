{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.pontus.features;
in {
  config = lib.mkMerge [
    {
      nixpkgs.config.allowUnfree = true;
      xdg.enable = true;

      home = {
        sessionPath = ["${config.home.homeDirectory}/.nix-profile/bin"];
        sessionVariables = {
          XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share";
        };

        packages = with pkgs; [
          alejandra # or nixfmt
          statix
          deadnix
          manix # Quick lookup of Nix/HM options

          pavucontrol
          btop
          htop
        ];
      };

      services.ssh-agent.enable = true;

      programs = {
        home-manager.enable = true;
        # Automatic env in flake dirs
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
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
