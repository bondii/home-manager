{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;
  currentTheme = pkgs.base16-schemes + "/share/themes/horizon-terminal-dark.yaml";
  #currentTheme = pkgs.base16-schemes + "/share/themes/catppuccin-mocha.yaml";

  stylixFonts = {
    serif = {
      package = pkgs.noto-fonts;
      name = "Noto Serif";
    };
    sansSerif = {
      package = pkgs.noto-fonts;
      name = "Noto Sans";
    };
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font";
    };
    emoji = {
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
    sizes = {
      desktop = 10;
      applications = 11;
      terminal = 11;
      popups = 10;
    };
  };
in
lib.mkMerge [
  (lib.mkIf cfg.stylix {
    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = currentTheme;
      polarity = "dark";

      opacity = {
        applications = 1.0;
        terminal = 0.9;
        popups = 0.9;
      };
      cursor = {
        package = pkgs.lyra-cursors;
        name = "LyraB-cursors";
        size = 28;
      };
      targets = lib.mkMerge [
        (lib.mkIf cfg.gui {
          gtk.enable = true;
          qt.enable = true;
          firefox.enable = lib.mkDefault false;
        })
        (lib.mkIf cfg.fonts {
          fontconfig.enable = true;
        })
        (lib.mkIf cfg.dev {
          fzf.enable = true;
        })
      ];
    };
  })

  (lib.mkIf (cfg.stylix && cfg.fonts) {
    stylix = {
      fonts = stylixFonts;
    };
  })
]
