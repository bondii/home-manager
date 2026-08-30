{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;
in
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
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
      size = 100000;
      save = 100000;
      share = true;
    };

    defaultKeymap = "viins";
    localVariables.KEYTIMEOUT = "15";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      stty -ixon  # Disable flow control for e.g. Ctrl+S
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

      # jk to leave Insert
      bindkey -M viins 'jk' vi-cmd-mode

      # Autosuggestions: Accept with Ctrl+Space
      bindkey '^ ' autosuggest-accept

      nva() {
        local -a files
        files=("''${(@f)$( {
          git diff --name-only --cached --diff-filter=ACMRTUXB
          git diff --name-only --diff-filter=ACMRTUXB
          git ls-files -o --exclude-standard
        } | sort -u)}")
        (( $#files )) && nvim -- "''${files[@]}"
      }

      nvu() {
        local -a files
        files=("''${(@f)$(git diff --name-only --diff-filter=ACMRTUXB)}")
        (( $#files )) && nvim -- "''${files[@]}"
      }

      nvs() {
        local -a files
        files=("''${(@f)$(git diff --cached --name-only --diff-filter=ACMRTUXB)}")
        (( $#files )) && nvim -- "''${files[@]}"
      }
    '';
  };

  programs.zsh.shellAliases = lib.mkIf cfg.nixvim {
    nv = "nvim";
    vim = "nvim";
    vdiff = "nvim -d";
    gs = "git status";
    gl = "git lg";
    ga = "git add -p .";
    gd = "git diff";

    # How do I break this out?
    xclip = "${pkgs.xclip}/bin/xclip -selection clipboard";

    devenv = "nix run github:cachix/devenv/latest --";
  };
}
