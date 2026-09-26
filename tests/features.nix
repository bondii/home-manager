{
  lib,
  mkHome,
  hostConfigs,
}:
let
  mk =
    args:
    mkHome (
      {
        system = "x86_64-linux";
        hostName = "test";
        user = {
          name = "test";
          homeDirectory = "/tmp/hm-feature-test";
          stateVersion = "25.05";
        };
      }
      // args
    );
  empty = (mk { }).config;
  on =
    (mk {
      features = {
        nixvim = false;
      };
      extraModules = [ { pontus.features.nixvim = true; } ];
    }).config;
  off =
    (mk {
      features = {
        nixvim = true;
      };
      extraModules = [ { pontus.features.nixvim = false; } ];
    }).config;
  laptop = (mk { features.laptop = true; }).config;
  editorOff =
    (mk {
      features = {
        gui = true;
        vscode = true;
      };
    }).config;
  desktop = hostConfigs."pontus@arch-desktop".config;
  ssh = hostConfigs."pontus@ssh-minimal".config;
  names = c: map lib.getName c.home.packages;
  contains =
    needle: value:
    lib.hasInfix (builtins.unsafeDiscardStringContext needle) (
      if builtins.isList value then lib.concatStringsSep "\n" value else value
    );
  absent = c: packages: lib.all (name: !(builtins.elem name (names c))) packages;
  noEditor =
    c:
    !c.programs.nixvim.enable
    && !(c.programs.zsh.shellAliases ? nv)
    && !(c.xdg.configFile ? "vim/shared-maps.vim")
    && absent c [
      "sf"
      "sg"
      "sfg"
    ];
in
assert lib.all (value: !value) (builtins.attrValues empty.pontus.features);
assert builtins.length (builtins.attrNames empty.pontus.features) == 7;
assert noEditor empty && noEditor off;
assert on.programs.nixvim.enable && on.programs.zsh.shellAliases ? nv;
assert lib.all (value: value) (builtins.attrValues desktop.pontus.features);
assert ssh.pontus.features.dev && ssh.programs.nixvim.enable && !ssh.pontus.features.gui;
assert absent ssh [
  "spotify"
  "pavucontrol"
  "google-chrome"
  "pgadmin4-wrapped"
  "mqtt-explorer"
  "rustdesk"
];
assert !(ssh.home.file ? ".pgadmin/config_local.py");
assert
  !ssh.services.picom.enable && !ssh.services.screen-locker.enable && !ssh.programs.kitty.enable;
assert
  !ssh.stylix.targets.gtk.enable
  && !ssh.stylix.targets.qt.enable
  && !ssh.stylix.targets.fontconfig.enable;
assert !laptop.programs.autorandr.enable && !(laptop.systemd.user.services ? xplugd);
assert builtins.elem "yubikey-manager" (names laptop) && builtins.elem "libfido2" (names laptop);
assert editorOff.programs.vscode.enable;
assert editorOff.programs.vscode.profiles.default.extensions == [ ];
assert !(editorOff.programs.vscode.profiles.default.userSettings ? "vscode-neovim.useCtrlKeys");
assert
  !(
    builtins.fromJSON editorOff.xdg.configFile."Cursor/User/settings.json".text
      ? "vscode-neovim.useCtrlKeys"
  );
assert
  desktop.systemd.user.services.cloud-sql-proxy-dev == ssh.systemd.user.services.cloud-sql-proxy-dev;
assert
  desktop.systemd.user.services.cloud-sql-proxy-prod
  == ssh.systemd.user.services.cloud-sql-proxy-prod;
assert !((desktop.systemd.user.services.cloud-sql-proxy-prod.Install or { }) ? WantedBy);
assert desktop.targets.genericLinux.nixGL.defaultWrapper == "mesa";
assert desktop.programs.rofi.terminal == "kitty";
assert desktop.xsession.windowManager.i3.config.terminal == "kitty";
assert contains "${desktop.services.picom.package}/bin/picom"
  desktop.systemd.user.services.picom.Service.ExecStart;
assert contains desktop.pontus.gui.lockCommand
  desktop.xsession.windowManager.i3.config.keybindings."Mod1+x";
assert contains desktop.pontus.gui.lockCommand
  desktop.systemd.user.services.xss-lock.Service.ExecStart;
assert contains "--transfer-sleep-lock" desktop.systemd.user.services.xss-lock.Service.ExecStart;
true
