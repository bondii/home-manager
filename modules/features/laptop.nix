{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;
  autorandrHotplug = pkgs.writeShellApplication {
    name = "autorandr-hotplug";
    runtimeInputs = [ pkgs.autorandr ];
    text = "autorandr --change";
  };
in
lib.mkIf cfg.laptop (
  lib.mkMerge [
    {
      home.packages = with pkgs; [
        yubikey-manager
        libfido2
      ];
    }
    (lib.mkIf cfg.gui {
      home.packages = with pkgs; [
        arandr
        xrandr
        xplugd
        libnotify
        yubioath-flutter
      ];
      systemd.user.services.xplugd = {
        Unit = {
          Description = "xplugd: autorandr on display hotplug";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.xplugd}/bin/xplugd -n ${autorandrHotplug}/bin/autorandr-hotplug";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
      programs.autorandr = {
        enable = true;
        hooks.postswitch.notify = ''${pkgs.libnotify}/bin/notify-send "Skärmprofil" "$AUTORANDR_CURRENT_PROFILE"'';
      };
    })
  ]
)
