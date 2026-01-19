{ features, lib, ... }:
let
  enableGui = features.gui or false;
in
{
  config = lib.mkIf enableGui {
    services.xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      displayManager.defaultSession = "none+i3";
      windowManager.i3.enable = true;
      xkb = {
        layout = "us,se";
        options = "grp:caps_toggle";
      };
    };
  };
}
