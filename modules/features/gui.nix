{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.pontus.features;
  enableGui = cfg.gui;

  wrap = name: bin:
    pkgs.writeShellScriptBin name ''
      exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${bin} "$@"
    '';

  lockPixel = pkgs.writeShellScriptBin "lock-pixel" ''
    set -euo pipefail
    down=40
    up=$((10000 / down))
    tmpbg="$(mktemp -p /run/user/$UID --suffix=.png)"

    ${pkgs.maim}/bin/maim -u | ${pkgs.imagemagick}/bin/magick convert - -sample "$down%" -sample "$up%" PNG24:"$tmpbg"

    /usr/bin/i3lock -n -i "$tmpbg"

    rm -f "$tmpbg"
  '';

  emojiPicker = pkgs.writeShellScriptBin "emoji-picker" ''
    set -euo pipefail

    ${pkgs.rofimoji}/bin/rofimoji --selector rofi --action type "$@"
  '';

  lockCommandDefault = "${lockPixel}/bin/lock-pixel";
in {
  options.pontus.gui = {
    i3 = {
      enable = lib.mkEnableOption "i3 window manager integration" // {default = true;};
    };
    lockCommand = lib.mkOption {
      type = lib.types.str;
      default = lockCommandDefault;
      description = "Command executed to lock the session; shared between the locker service and window manager bindings.";
    };
  };

  imports = [./gui/i3.nix];

  config = lib.mkIf enableGui {
    home.packages = with pkgs;
      [
        (wrap "kitty-gl" "${pkgs.kitty}/bin/kitty")
        (wrap "imv-gl" "${pkgs.imv}/bin/imv")
        (wrap "picom-gl" "${pkgs.picom}/bin/picom")
        pkgs.nixgl.nixGLMesa

        maim
        imagemagick
        lockPixel
        emojiPicker

        xterm
        brightnessctl

        feh
        imv
        zathura
        blueman
        networkmanagerapplet
        libnotify
        rofimoji
        xdotool
        xss-lock
        xfce.xfce4-clipman-plugin
        redshift
        libreoffice
        gimp
      ]
      ++ lib.optionals cfg.fonts [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ];

    programs.kitty = {
      enable = true;
      settings = {
        confirm_os_window_close = 0;
        enable_audio_bell = "no";
        scrollback_lines = 10000;
        term = "xterm-kitty";
        dynamic_background_opacity = "yes";
      };
      keybindings = {
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+n" = "new_os_window_with_cwd";
      };
    };

    programs.rofi = {
      enable = true;
      terminal = "kitty-gl";
      extraConfig = {
        modi = "drun,run,ssh";
        show-icons = true;
      };
    };

    services.dunst = {
      enable = true;
    };

    services.picom = {
      enable = true;
      settings = {
        backend = "glx";
        vsync = true;
        detect-client-leader = true;

        opacity-rule = [
          "100:class_g = 'i3lock'"
          "100:class_g = 'XSecureLock'"
          "80:class_g = 'Rofi' && focused"
        ];

        detect-rounded-corners = true;
        corner-radius = 12;
        round-borders = 1;
        rounded-corners-exclude = [
          "window_type = 'dock'"
          "window_type = 'desktop'"
          "class_g = 'mpv'"
          "class_g = 'feh'"
          "name = 'Picture-in-Picture'"
        ];

        shadow = true;
        shadow-radius = 16;
        shadow-opacity = 0.35;
        frame-opacity = 0.90;
        inactive-opacity = 0.9;
        wintypes = {
          dock = {shadow = false;};
          dnd = {shadow = false;};
          tooltip = {shadow = false;};
          menu = {shadow = false;};
          dropdown_menu = {shadow = false;};
          popup_menu = {shadow = false;};
        };
      };
    };
    systemd.user.services.picom.Service.ExecStart =
      lib.mkForce "${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.picom}/bin/picom --config ${config.xdg.configHome}/picom/picom.conf";

    services.screen-locker = {
      enable = true;
      lockCmd = config.pontus.gui.lockCommand;
      inactiveInterval = 10;
      xss-lock.extraOptions = ["--transfer-sleep-lock"];
    };
    systemd.user.services.xss-lock = {
      Unit = {
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Environment = [
          "DISPLAY=:0"
          "XAUTHORITY=%h/.Xauthority"
        ];
        #Restart = "on-failure";
      };
    };

    services.redshift = {
      enable = true;
      settings.redshift = {
        temp-day = lib.mkForce 6500;
        temp-night = lib.mkForce 2000;
        brightness-day = lib.mkForce 1.0;
        brightness-night = lib.mkForce 0.9;
        transition = 1;
        dawn-time = "06:59-07:00";
        dusk-time = "18:30-20:00";
      };
    };
  };
}
