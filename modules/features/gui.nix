{ config, lib, pkgs, ... }:
let
  cfg = config.pontus.features;
  wrap = name: bin: pkgs.writeShellScriptBin name ''
    exec ${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${bin} "$@"
  '';
  lockPixel = pkgs.writeShellScriptBin "lock-pixel" ''
    set -euo pipefail
    down=16
    up=$((10000 / down))
    tmpbg="$(mktemp -p /run/user/$UID --suffix=.png)"

    ${pkgs.maim}/bin/maim -u | ${pkgs.imagemagick}/bin/magick convert - -sample "$down%" -sample "$up%" PNG24:"$tmpbg"

    /usr/bin/i3lock -n -i "$tmpbg"

    rm -f "$tmpbg"
  '';
  enableModule = cfg.gui;
in
lib.mkIf enableModule {
  home.packages = with pkgs; [
    (wrap "kitty-gl"   "${pkgs.kitty}/bin/kitty")
    (wrap "imv-gl"     "${pkgs.imv}/bin/imv")
    (wrap "picom-gl"   "${pkgs.picom}/bin/picom")
    pkgs.nixgl.nixGLMesa

    maim
    imagemagick
    lockPixel

    xterm
    brightnessctl

    feh
    imv
    zathura
    blueman
    networkmanagerapplet
    libnotify
    xss-lock
    xfce.xfce4-clipman-plugin
    redshift
  ] ++ lib.optionals cfg.fonts [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11.0;
    };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      scrollback_lines = 10000;
      term = "xterm-kitty";
      background_opacity = "0.9";
      dynamic_background_opacity = "yes";
    };
  };

  programs.rofi = {
    enable = true;
    terminal = "kitty-gl";
    theme = "Arc-Dark";
    extraConfig = {
      modi = "drun,run,ssh";
      show-icons = true;
    };
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrainsMono Nerd Font 10";
        frame_color = "#5e81ac";
        separator_color = "frame";
        padding = 8;
        horizontal_padding = 8;
        icon_position = "left";
      };
      urgency_low     = { background = "#2e3440"; foreground = "#d8dee9"; timeout = 3; };
      urgency_normal  = { background = "#2b303b"; foreground = "#eceff4"; timeout = 6; };
      urgency_critical= { background = "#bf616a"; foreground = "#2e3440"; frame_color = "#bf616a"; timeout = 0; };
    };
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
      ];

      detect-rounded-corners = true;
      corner-radius = 12;
      round-borders = 1;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "class_g = 'Rofi'"
        "class_g = 'rofi'"
        "class_g = 'mpv'"
        "class_g = 'feh'"
        "name = 'Picture-in-Picture'"
      ];

      shadow = true;
      shadow-radius = 16;
      shadow-opacity = 0.30;
      frame-opacity = 0.90;
      inactive-opacity = 0.9;
      wintypes = {
        dock = { shadow = false; };
        dnd = { shadow = false; };
        tooltip = { shadow = false; };
        menu = { shadow = false; };
        dropdown_menu = { shadow = false; };
        popup_menu = { shadow = false; };
      };
    };
  };
  systemd.user.services.picom.Service.ExecStart =
    lib.mkForce "${pkgs.nixgl.nixGLMesa}/bin/nixGLMesa ${pkgs.picom}/bin/picom --config ${config.xdg.configHome}/picom/picom.conf";

  services.screen-locker = {
    enable = true;
    lockCmd = "${lockPixel}/bin/lock-pixel";
    inactiveInterval = 10;
    xss-lock.extraOptions = [ "--transfer-sleep-lock" ];
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

  programs.i3status-rust = {
    enable = true;
    bars.default = {
      settings = {
        theme.theme = "gruvbox-dark";
        icons.icons = "material-nf";
        trayOutput = "primary";
        trayPadding = 4;
      };
      blocks = [
        { block = "cpu"; interval = 1; }
        { block = "memory"; format = " $icon $mem_used_percents "; format_alt = " $icon $swap_used_percents "; }
        {
          block = "battery";
          format = " $icon $percentage ";
          charging_format = " $icon $percentage ";
          full_format = " $icon 100% ";
        }
        { block = "sound"; }
        { block = "time"; interval = 60; format = " $timestamp.datetime(f:'%d/%m %R') "; }
      ];
    };
  };

  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      config = {
        modifier = "Mod1";
        terminal = "kitty-gl";
        fonts = { names = [ "JetBrainsMono Nerd Font" ]; size = 10.0; };

        window = {
          border = 1;
          hideEdgeBorders = "smart";
          titlebar = false;
          commands = [
            { criteria = { title = "alsamixer";  }; command = "floating enable, border pixel 1"; }
            { criteria = { class = "Pavucontrol"; }; command = "floating enable"; }
          ];
        };

        floating.modifier = "Mod1";

        bars = [{
          position = "bottom";
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
        }];

        startup = [
          { command = "nm-applet"; always = true; notification = false; }
          { command = "blueman-applet"; always = true; notification = false; }
          { command = "xfce4-clipman"; always = true; notification = false; }
          { command = "feh --no-fehbg --bg-fill $HOME/pictures/wallpapers/default.jpg"; always = true; }
          { command = "setxkbmap -layout se,us -option grp:caps_toggle"; always = true; notification = false; }
          { command = ''i3-msg 'rename workspace "9" to ""'';  always = false; }
          { command = ''i3-msg 'rename workspace "10" to ""''; always = false; }
        ];

        workspaceAutoBackAndForth = true;

        gaps = {
          inner = 5;
          outer = -2;
          smartGaps = true;
          smartBorders = "on";
        };

        colors = {
          focused = {
            border      = "#90648B";
            background  = "#660066";
            text        = "#80FFF9";
            indicator   = "#90648B";
            childBorder = "#90648B";
          };
          urgent = {
            border      = "#D94F70";
            background  = "#D94F70";
            text        = "#80FFF9";
            indicator   = "#CB4B16";
            childBorder = "#CB4B16";
          };
        };

        assigns = {
          "" = [{ class = "Spotify"; title = "Spotify Premium"; }];
        };

        keybindings =
          let M = "Mod1";
          in {
            "${M}+Return" = "exec --no-startup-id kitty-gl";
            "${M}+Shift+Return" = "exec --no-startup-id ${pkgs.xterm}/bin/xterm";
            "${M}+d"      = "exec rofi -show drun -show-icons -modi run";
            "${M}+Shift+q" = "kill";

            "${M}+Shift+c" = "reload";
            "${M}+Shift+r" = "restart";
            "${M}+Shift+e" = ''exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"'';
            "${M}+x" = "exec ${lockPixel}/bin/lock-pixel";

            "${M}+h" = "focus left";
            "${M}+j" = "focus down";
            "${M}+k" = "focus up";
            "${M}+l" = "focus right";
            "${M}+Left" = "focus left";
            "${M}+Down" = "focus down";
            "${M}+Up" = "focus up";
            "${M}+Right" = "focus right";

            "${M}+Shift+h" = "move left";
            "${M}+Shift+j" = "move down";
            "${M}+Shift+k" = "move up";
            "${M}+Shift+l" = "move right";
            "${M}+Shift+Left" = "move left";
            "${M}+Shift+Down" = "move down";
            "${M}+Shift+Up" = "move up";
            "${M}+Shift+Right" = "move right";

            "${M}+g" = "split h";
            "${M}+v" = "split v";
            "${M}+f" = "fullscreen toggle";
            "${M}+s" = "layout stacking";
            "${M}+w" = "layout tabbed";
            "${M}+e" = "layout toggle split";

            "${M}+Shift+space" = "floating toggle";
            "${M}+space"       = "focus mode_toggle";
            "${M}+a"           = "focus parent";

            "${M}+1"="workspace number 1";
            "${M}+2"="workspace number 2";
            "${M}+3"="workspace number 3";
            "${M}+4"="workspace number 4";
            "${M}+5"="workspace number 5";
            "${M}+6"="workspace number 6";
            "${M}+7"="workspace number 7";
            "${M}+8"="workspace number 8";
            "${M}+9"="workspace ";
            "${M}+0"="workspace ";
            "${M}+Ctrl+Right" = "workspace next";
            "${M}+Ctrl+Left"  = "workspace prev";
            "${M}+Shift+b"    = "move container to workspace back_and_forth; workspace back_and_forth";

            "${M}+Shift+1"="move container to workspace number 1";
            "${M}+Shift+2"="move container to workspace number 2";
            "${M}+Shift+3"="move container to workspace number 3";
            "${M}+Shift+4"="move container to workspace number 4";
            "${M}+Shift+5"="move container to workspace number 5";
            "${M}+Shift+6"="move container to workspace number 6";
            "${M}+Shift+7"="move container to workspace number 7";
            "${M}+Shift+8"="move container to workspace number 8";
            "${M}+Shift+9"="move container to workspace ";
            "${M}+Shift+0"="move container to workspace ";

            "${M}+Ctrl+1"="move container to workspace 1; workspace number 1";
            "${M}+Ctrl+2"="move container to workspace 2; workspace number 2";
            "${M}+Ctrl+3"="move container to workspace 3; workspace number 3";
            "${M}+Ctrl+4"="move container to workspace 4; workspace number 4";
            "${M}+Ctrl+5"="move container to workspace number 5";
            "${M}+Ctrl+6"="move container to workspace number 6";
            "${M}+Ctrl+7"="move container to workspace number 7";
            "${M}+Ctrl+8"="move container to workspace number 8";
            "${M}+Ctrl+9"="move container to workspace ; workspace ";
            "${M}+Ctrl+0"="move container to workspace ; workspace ";

            "${M}+r" = ''mode "resize"'';

            "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
            "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
            "XF86AudioMute"        = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioMicMute"     = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

            "XF86MonBrightnessUp"   = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
            "XF86MonBrightnessDown" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
          };
      };

      extraConfig = ''
        default_border pixel 2
        default_floating_border normal
        tiling_drag modifier

        mode "resize" {
            bindsym h resize shrink width 5 px or 5 ppt
            bindsym j resize grow height 5 px or 5 ppt
            bindsym k resize shrink height 5 px or 5 ppt
            bindsym l resize grow width 5 px or 5 ppt

            bindsym Left  resize shrink width 1 px or 1 ppt
            bindsym Down  resize grow height 1 px or 1 ppt
            bindsym Up    resize shrink height 1 px or 1 ppt
            bindsym Right resize grow width 1 px or 1 ppt

            bindsym Return mode "default"
            bindsym Escape mode "default"
            bindsym Mod1+r mode "default"
        }
      '';
    };
  };
}
