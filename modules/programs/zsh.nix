{
  config,
  lib,
  ...
}: let
  cfg = config.pontus.features;
in {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = ''
      autoload -Uz compinit

      zstyle ':completion:*' completer _expand _complete _ignored _correct
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:]}={[:upper:]}' 'r:|[._-/]=* r:|=** l:|=*'
      zstyle ':completion:*' max-errors 2

      compinit
    '';

    history = {
      path = "${config.home.homeDirectory}/.histfile";
      size = 10000;
      save = 10000;
      share = true;
    };

    defaultKeymap = "viins";
    localVariables.KEYTIMEOUT = "15";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      stty -ixon  # Disable flow control for e.g. Ctrl+S

      # jk to leave Insert
      bindkey -M viins 'jk' vi-cmd-mode

      # Autosuggestions: Accept with Ctrl+Space
      bindkey '^ ' autosuggest-accept
    '';
  };

  programs.zsh.shellAliases = lib.mkIf cfg.nixvim {
    nv = "nvim";
    vim = "nvim";
    vdiff = "nvim -d";
    gs = "git status";
    gl = "git lg";
  };
}
