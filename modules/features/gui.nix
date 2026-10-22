{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;
  enableGui = cfg.gui;

  wrappedImv = config.lib.nixGL.wrap pkgs.imv;
  forward =
    name: bin:
    pkgs.writeShellScriptBin name ''
      exec ${bin} "$@"
    '';

  lockPixel = import ../../lib/lockPixel.nix { inherit pkgs; };

  emojiPicker = pkgs.writeShellScriptBin "emoji-picker" ''
    set -euo pipefail

    ${pkgs.rofimoji}/bin/rofimoji --selector rofi --action type "$@"
  '';

  feh = pkgs.writeShellScriptBin "feh" ''
    set -euo pipefail

    for arg in "$@"; do
      case "$arg" in
        --bg-*|--zoom)
          exec ${pkgs.feh}/bin/feh "$@"
          ;;
      esac
    done

    # feh only honours --zoom in fullscreen mode or with a fixed geometry
    # (see feh(1)), so --fullscreen is required for the fit-to-screen zoom
    # to actually take effect - otherwise a tiling WM's own window sizing
    # silently overrides it.
    exec ${pkgs.feh}/bin/feh --fullscreen --zoom max "$@"
  '';

  lockCommandDefault = "${lockPixel}/bin/lock-pixel";
  screenshotDir = "$HOME/pictures/screenshots";
  screenshotRegion = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail
      dir="${screenshotDir}"
      mkdir -p "$dir"
      file="$dir/screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"
      ${pkgs.maim}/bin/maim -s "$file"
      ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
    '';
  };

  screenshotFull = pkgs.writeShellApplication {
    name = "screenshot-full";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail
      dir="${screenshotDir}"
      mkdir -p "$dir"
      file="$dir/screenshot-$(date '+%Y-%m-%d_%H-%M-%S').png"
      ${pkgs.maim}/bin/maim "$file"
      ${pkgs.xclip}/bin/xclip -selection clipboard -t image/png < "$file"
      ${pkgs.libnotify}/bin/notify-send "Screenshot saved" "$file"
    '';
  };
in
{
  options.pontus.gui = {
    i3 = {
      enable = lib.mkEnableOption "i3 window manager integration" // {
        default = true;
      };
    };
    lockCommand = lib.mkOption {
      type = lib.types.str;
      default = lockCommandDefault;
      description = "Command executed to lock the session; shared between the locker service and window manager bindings.";
    };
  };

  imports = [ ./gui/i3.nix ];

  config = lib.mkIf enableGui {
    targets.genericLinux.nixGL = {
      packages = pkgs.nixgl;
      defaultWrapper = "mesa";
    };
    home.packages =
      with pkgs;
      [
        (forward "kitty-gl" "${config.programs.kitty.package}/bin/kitty")
        (forward "imv-gl" "${wrappedImv}/bin/imv")
        (forward "picom-gl" "${config.services.picom.package}/bin/picom")
        pkgs.nixgl.nixGLMesa

        maim
        pavucontrol
        spotify
        imagemagick
        lockPixel
        emojiPicker

        xterm
        brightnessctl

        feh
        geeqie
        wrappedImv
        zathura
        blueman
        networkmanagerapplet
        libnotify
        rofimoji
        xdotool
        xss-lock
        xfce4-clipman-plugin
        redshift
        libreoffice
        gimp
        xclip
        screenshotRegion
        screenshotFull
        qbittorrent
        vlc
        darktable
      ]
      ++ lib.optionals cfg.fonts [
        nerd-fonts.jetbrains-mono
        unifont
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

    programs.kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;
      settings = {
        confirm_os_window_close = 0;
        enable_audio_bell = "no";
        scrollback_lines = 10000;
        term = "xterm-kitty";
        dynamic_background_opacity = "yes";
        cursor_trail = 1;
        cursor_trail_start_threshold = 2;
        cursor_trail_decay = "0.1 0.2";
      };
      keybindings = {
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+n" = "new_os_window_with_cwd";
        "ctrl+shift+d" = "detach_tab new";
      };
    };

    programs.rofi = {
      enable = true;
      terminal = "kitty";
      extraConfig = {
        modi = "drun,run,ssh";
        show-icons = true;
      };
    };

    services = {
      dunst = {
        enable = true;
      };

      picom = {
        enable = true;
        package = config.lib.nixGL.wrap pkgs.picom;
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
            dock = {
              shadow = false;
            };
            dnd = {
              shadow = false;
            };
            tooltip = {
              shadow = false;
            };
            menu = {
              shadow = false;
            };
            dropdown_menu = {
              shadow = false;
            };
            popup_menu = {
              shadow = false;
            };
          };
        };
      };
      screen-locker = {
        enable = true;
        lockCmd = config.pontus.gui.lockCommand;
        # Disable automatic idle locking; keep manual and suspend locking
        # xautolock.enable = false;
        # inactiveInterval = 0;
        inactiveInterval = 10;
        xss-lock.extraOptions = [ "--transfer-sleep-lock" ];
      };
      redshift = {
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
    systemd.user.services.xss-lock = {
      Unit = {
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Environment = [
          "DISPLAY=:0"
          "XAUTHORITY=%h/.Xauthority"
        ];
        #Restart = "on-failure";
      };
    };

  };
}
