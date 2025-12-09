{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    fd
    ripgrep
    fzf
    bat

    # sf ("nvim search file"): Fuzzy find file; open in Neovim
    (pkgs.writeShellScriptBin "sf" ''
      set -euo pipefail
      query="''${1:-}"
      if [ "$#" -gt 0 ]; then
        shift
      fi
      file="$(
        fd --type f --hidden --exclude .git "$@" \
        | fzf --query "''${query}" --preview 'bat --style=numbers --color=always --line-range=:200 {}'
      )" || exit 0
      exec nvim "$file"
    '')

    # sg ("nvim search grep"): Fuzzy search file content with preview; open in Neovim
    (pkgs.writeShellScriptBin "sg" ''
      #!/usr/bin/env bash
      # Interactive content search -> open in Neovim at match
      set -euo pipefail
      dir="."
      query=""

      if (($# > 0)) && [ -d "$1" ]; then
        dir="$1"
        shift
      fi

      query="''${*}"

      rgBase="rg --vimgrep -F --smart-case --hidden --glob '!.git' --no-messages --color=never --"
      reloadCmd="''${rgBase} {q} \"''${dir}\" || true"
      binds="change:reload:''${reloadCmd}"

      fzfDefaultCommand=""
      if [ -n "''${query}" ]; then
        escapedQuery="$(printf '%q' "''${query}")"
        fzfDefaultCommand="''${rgBase} ''${escapedQuery} \"''${dir}\" || true"
      fi

      # fzf runs with an empty list first; on each keystroke (change),
      # we reload results from ripgrep using the current query {q}.
      # We show right-aligned file:line:col + match text (with highlights) and preview the focused match with context.
      selection="$(
        if [ -n "''${fzfDefaultCommand}" ]; then
          FZF_DEFAULT_COMMAND="''${fzfDefaultCommand}"
        else
          unset FZF_DEFAULT_COMMAND
        fi
        FZF_DEFAULT_OPTS="--height=80% --layout=reverse --border" \
        fzf --ansi --disabled --query "''${query}" \
          --prompt="rg> " \
           --bind "''${binds}" \
           --delimiter=":" \
           --with-nth=1,2,3,4.. \
           --nth=1,2,3,4.. \
          --preview "bash -c 'q=\$1; file=\$2; rawLine=\$3; if [ -z \"\$q\" ] || [ ! -f \"\$file\" ]; then exit 0; fi; lineDigits=\$(printf \"%s\" \"\$rawLine\" | tr -cd \"0-9\"); [ -z \"\$lineDigits\" ] && exit 0; lineNr=\$((10#\$lineDigits)); context=5; start=\$((lineNr - context)); if (( start < 1 )); then start=1; fi; end=\$((lineNr + context)); bat --style=numbers --color=always --line-range \"\$start:\$end\" --highlight-line \"\$lineNr\" \"\$file\" | rg --passthru --color=always -F --smart-case -- \"\$q\" || true' preview {q} {1} {2}" \
          --preview-window 'up,60%,border-bottom,wrap' \
          --pointer="➤" --marker="✓"
      )" || exit 0

      # Selection format: file:line:col:matchtext
      file="$(printf %s "''${selection}" | cut -d: -f1)"
      line="$(printf %s "''${selection}" | cut -d: -f2 | sed 's/^[[:space:]]*//')"
      col="$(printf %s "''${selection}" | cut -d: -f3 | sed 's/^[[:space:]]*//')"

      [ -n "''${file}" ] || exit 0

      # Jump to line:col in Neovim
      exec nvim "+call cursor(''${line},''${col})" -- "''${file}"
    '')

    # sfg ("nvim search file grep"): Fuzzy search file content; open file picker of results; open in Neovim
    (pkgs.writeShellScriptBin "sfg" ''
      set -euo pipefail
      query="''${1:-}"
      if [ -n "''${query}" ]; then
        printf "grep: %s\n" "''${query}"
      else
        printf "grep: "
        IFS= read -r query
      fi
      [ -z "''${query}" ] && exit 0
      export QUERY="''${query}"
      file="$(
        rg -l --no-messages -- "$QUERY" \
        | fzf --preview 'rg --pretty --context 5 -- "$QUERY" {}'
      )" || exit 0
      exec nvim "$file"
    '')
  ];
}
