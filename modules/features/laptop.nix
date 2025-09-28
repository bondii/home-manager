{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.pontus.features;

  internalDisplay = "00ffffffffffff0030aeb7410000000000220104a5221678230dd09f5c589527235358000000010101010101010101010101010101016140800471b03c403020360058d71000001a000000fd00283c4c4c10010a2020202020200000000f00d10a28d10a28280a0409e5370d000000fc004e5631363057554d2d4e34450a01a67020790200810015741a00000301283c0000000000003c000000008d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001090";
  cuhdHemma = "00ffffffffffff00410c04c21219000017210104b54627783be5c5ac5047a726135054230800d1c0b30095008180814081c0010101014dd000a0f0703e8030203500b9882100001a000000ff0041553032333233303036343138000000fc0050484c2033323845310a202020000000fd00303ca0a03c010a202020202020016e020320f14b0103051404131f12021190230907078301000067030c0010000078565e00a0a0a0295030203500b9882100001e023a801871382d40582c4500b9882100001e011d007251d01e206e285500b9882100001e8c0ad08a20e02d10103e9600b988210000184d6c80a070703e8030203a00b9882100001a000000000034";

  cuhdHemmaConfig = {
    enable = true;
    primary = true;
    mode = "3840x2160";
    rate = "60.00";
    position = "0x0";
    rotate = "normal";
  };
in
  lib.mkIf cfg.laptop {
    home.packages = with pkgs; [
      autorandr
      arandr
      xorg.xrandr
      xplugd
      libnotify
    ];

    systemd.user.services.xplugd = {
      Unit = {
        Description = "xplugd: autorandr on display hotplug";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.xplugd}/bin/xplugd -r -c '${pkgs.bash}/bin/bash -lc \"${pkgs.autorandr}/bin/autorandr --change --default mobile\"'";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    programs.autorandr = {
      enable = true;
      hooks.postswitch.notify = ''${pkgs.libnotify}/bin/notify-send "Skärmprofil" "$AUTORANDR_CURRENT_PROFILE"''; # Fill 'profiles' after reading EDID with xrandr & autorandr

      profiles = {
        mobile = {
          fingerprint.eDP-1 = internalDisplay;
          config.eDP-1 = {
            enable = true;
            primary = true;
            mode = "1920x1200";
            rate = "60.00";
            position = "0x0";
            rotate = "normal";
          };
          config.DP-9.enable = false;
        };

        cuhd9s = {
          fingerprint.DP-9 = cuhdHemma;
          config.DP-9 = cuhdHemmaConfig;
          config.eDP-1.enable = false;
        };
        cuhd9b = {
          fingerprint = {
            eDP-1 = internalDisplay;
            DP-9 = cuhdHemma;
          };
          config.DP-9 = cuhdHemmaConfig;
          config.eDP-1.enable = false;
        };
        cuhd10s = {
          fingerprint.DP-10 = cuhdHemma;
          config.DP-10 = cuhdHemmaConfig;
        };
        cuhd10d = {
          fingerprint = {
            eDP-1 = internalDisplay;
            DP-10 = cuhdHemma;
          };
          config.DP-10 = cuhdHemmaConfig;
          config.eDP-1.enable = false;
        };
      };
    };

    xsession.windowManager.i3 = {
      enable = true;
      config.startup = [
        {
          command = "${pkgs.autorandr}/bin/autorandr --change --default mobile";
          always = true;
        }
      ];
    };
  }
