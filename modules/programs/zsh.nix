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

      gcp_mcp_add() {
        local name="$1" url="$2"
        local token
        token=$(gcloud auth application-default print-access-token)
        claude mcp remove --scope user "$name" 2>/dev/null
        claude mcp add-json --scope user "$name" \
          "$(printf '{"type":"http","url":"%s","headers":{"Authorization":"Bearer %s","x-goog-user-project":"ship2shore-dev"}}' "$url" "$token")"
      }
    ''
    + lib.optionalString cfg.nixvim ''
      nva() {
        local -a files=()
        local file
        while IFS= read -r -d $'\0' file; do
          files+=("$file")
        done < <({
          git diff -z --name-only --cached --diff-filter=ACMRTUXB
          git diff -z --name-only --diff-filter=ACMRTUXB
          git ls-files -z -o --exclude-standard
        } | sort -zu)
        (( $#files )) || return 0
        nvim -- "''${files[@]}"
      }

      nvu() {
        local -a files=()
        local file
        while IFS= read -r -d $'\0' file; do
          files+=("$file")
        done < <(git diff -z --name-only --diff-filter=ACMRTUXB)
        (( $#files )) || return 0
        nvim -- "''${files[@]}"
      }

      nvs() {
        local -a files=()
        local file
        while IFS= read -r -d $'\0' file; do
          files+=("$file")
        done < <(git diff -z --cached --name-only --diff-filter=ACMRTUXB)
        (( $#files )) || return 0
        nvim -- "''${files[@]}"
      }
    '';
  };

  programs.zsh.shellAliases = {
    gs = "git status";
    gl = "git lg";
    ga = "git add -p .";
    gd = "git diff";

    devenv = "nix run github:cachix/devenv/latest --";
  }
  // lib.optionalAttrs cfg.nixvim {
    nv = "nvim";
    vim = "nvim";
    vdiff = "nvim -d";
  }
  // lib.optionalAttrs cfg.gui {
    xclip = "${pkgs.xclip}/bin/xclip -selection clipboard";
  };
}
