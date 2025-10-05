{
  config,
  lib,
  pkgs,
  ...
}: let
  features = config.pontus.features;
  guiCfg = config.pontus.gui;
  enableI3 = (features.gui or false) && (guiCfg.i3.enable or false);
  lockCommand = config.pontus.gui.lockCommand;
in
  lib.mkIf enableI3 {
    programs.i3status-rust = {
      enable = true;
      bars.default = {
        settings = {
          #config.lib.stylix.i3status-rust.bar
          #// {
          #  icons.icons = "material-nf";
          #  trayOutput = "primary";
          #  trayPadding = 4;
          #};
          theme.theme = "gruvbox-dark";
          icons.icons = "material-nf";
          trayOutput = "primary";
          trayPadding = 4;
        };
        blocks = [
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "memory";
            format = " $icon $mem_used_percents ";
            format_alt = " $icon $swap_used_percents ";
          }
          {
            block = "battery";
            format = " $icon $percentage ";
            charging_format = " $icon $percentage ";
            full_format = " $icon 100% ";
          }
          {block = "sound";}
          {
            block = "time";
            interval = 60;
            format = " $timestamp.datetime(f:'%d/%m %R') ";
          }
        ];
      };
    };

    xsession = {
      enable = true;
      initExtra = ''
        ${pkgs.xorg.setxkbmap}/bin/setxkbmap -layout se,us -option grp:caps_toggle
      '';
      windowManager.i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        config = {
          modifier = "Mod1";
          terminal = "kitty-gl";

          window = {
            border = 1;
            hideEdgeBorders = "smart";
            titlebar = false;
            commands = [
              {
                criteria = {title = "alsamixer";};
                command = "floating enable, border pixel 1";
              }
              {
                criteria = {class = "Pavucontrol";};
                command = "floating enable";
              }
            ];
          };

          floating.modifier = "Mod1";

          bars = [
            #(
            {
              position = "bottom";
              statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";
            }
            #// config.stylix.targets.i3.exportedBarConfig)
          ];

          startup = [
            {
              command = "nm-applet";
              always = true;
              notification = false;
            }
            {
              command = "blueman-applet";
              always = true;
              notification = false;
            }
            {
              command = "xfce4-clipman";
              always = false;
              notification = false;
            }
            {
              command = "feh --no-fehbg --bg-fill $HOME/pictures/wallpapers/default.jpg";
              always = true;
            }
            {
              command = ''i3-msg 'rename workspace "9" to ""'';
              always = false;
            }
            {
              command = ''i3-msg 'rename workspace "10" to ""'';
              always = false;
            }
          ];

          workspaceAutoBackAndForth = true;

          gaps = {
            inner = 10;
            outer = -11;
            smartGaps = true;
            smartBorders = "on";
          };

          assigns = {
            "" = [
              {
                class = "Spotify";
                title = "Spotify Premium";
              }
            ];
          };

          keybindings = let
            M = "Mod1";
          in {
            "${M}+Return" = "exec --no-startup-id kitty-gl";
            "${M}+Shift+Return" = "exec --no-startup-id ${pkgs.xterm}/bin/xterm";
            "${M}+d" = "exec rofi -show drun -show-icons -modi run";
            "${M}+Shift+q" = "kill";

            "${M}+Shift+c" = "reload";
            "${M}+Shift+r" = "restart";
            "${M}+Shift+e" = ''exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"'';
            "${M}+x" = "exec ${lockCommand}";

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
            "${M}+space" = "focus mode_toggle";
            "${M}+a" = "focus parent";

            "${M}+1" = "workspace number 1";
            "${M}+2" = "workspace number 2";
            "${M}+3" = "workspace number 3";
            "${M}+4" = "workspace number 4";
            "${M}+5" = "workspace number 5";
            "${M}+6" = "workspace number 6";
            "${M}+7" = "workspace number 7";
            "${M}+8" = "workspace number 8";
            "${M}+9" = "workspace ";
            "${M}+0" = "workspace ";
            "${M}+Ctrl+Right" = "workspace next";
            "${M}+Ctrl+Left" = "workspace prev";
            "${M}+Shift+b" = "move container to workspace back_and_forth; workspace back_and_forth";

            "${M}+Shift+1" = "move container to workspace number 1";
            "${M}+Shift+2" = "move container to workspace number 2";
            "${M}+Shift+3" = "move container to workspace number 3";
            "${M}+Shift+4" = "move container to workspace number 4";
            "${M}+Shift+5" = "move container to workspace number 5";
            "${M}+Shift+6" = "move container to workspace number 6";
            "${M}+Shift+7" = "move container to workspace number 7";
            "${M}+Shift+8" = "move container to workspace number 8";
            "${M}+Shift+9" = "move container to workspace ";
            "${M}+Shift+0" = "move container to workspace ";

            "${M}+Ctrl+1" = "move container to workspace 1; workspace number 1";
            "${M}+Ctrl+2" = "move container to workspace 2; workspace number 2";
            "${M}+Ctrl+3" = "move container to workspace 3; workspace number 3";
            "${M}+Ctrl+4" = "move container to workspace 4; workspace number 4";
            "${M}+Ctrl+5" = "move container to workspace number 5";
            "${M}+Ctrl+6" = "move container to workspace number 6";
            "${M}+Ctrl+7" = "move container to workspace number 7";
            "${M}+Ctrl+8" = "move container to workspace number 8";
            "${M}+Ctrl+9" = "move container to workspace ; workspace ";
            "${M}+Ctrl+0" = "move container to workspace ; workspace ";

            "${M}+r" = ''mode "resize"'';

            "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +2%";
            "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -2%";
            "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

            "XF86MonBrightnessUp" = "exec --no-startup-id ${pkgs.brightnessctl}/bin/brightnessctl set +10%";
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
