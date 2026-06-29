{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;
in
{
  config = lib.mkMerge [
    {
      nixpkgs.config.allowUnfree = true;
      xdg.enable = true;
      systemd.user.systemctlPath = "/usr/bin/systemctl";

      home = {
        sessionPath = [ "${config.home.homeDirectory}/.nix-profile/bin" ];
        sessionVariables = {
          XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/usr/local/share:/usr/share";
        };

        packages = with pkgs; [
          nixfmt # Nix formatter
          statix
          deadnix
          manix # Quick lookup of Nix/HM options

          pavucontrol
          btop
          htop
          tree
          ncdu
          lsof

          spotify
        ];
      };

      services.ssh-agent.enable = true;

      # Home Manager 26.05 warns about this default even when Hyprland is not enabled.
      wayland.windowManager.hyprland.configType = "hyprlang";

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
      fonts.fontconfig = {
        enable = true;
        defaultFonts.monospace = [
          "JetBrainsMono Nerd Font"
          "Unifont"
        ];
      };
    })
  ];
}
