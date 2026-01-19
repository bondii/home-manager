{ lib, pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
  ];

  networking.networkmanager.enable = lib.mkDefault true;
  programs.zsh.enable = true;

  time.timeZone = lib.mkDefault "Europe/Stockholm";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";
}
