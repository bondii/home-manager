{
  pkgs,
  locker ? "/usr/bin/i3lock",
}:

pkgs.writeShellApplication {
  name = "lock-pixel";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.maim
    pkgs.imagemagick
  ];
  text = ''
    export LOCK_PIXEL_LOCKER=${pkgs.lib.escapeShellArg locker}
    ${builtins.readFile ./lock-pixel.sh}
  '';
}
