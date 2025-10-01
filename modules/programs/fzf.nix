{pkgs, ...}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    fd
    ripgrep
    fzf
    bat

    # nf ("nvim file"): Fuzzy find file; open in Neovim
    (pkgs.writeShellScriptBin "nf" ''
      set -euo pipefail
      file="$(
        fd --type f --hidden --exclude .git \
        | fzf --preview 'bat --style=numbers --color=always --line-range=:200 {}'
      )" || exit 0
      exec nvim "$file"
    '')

    # ng ("nvim grep"): Fuzzy search file content with preview; open in Neovim
    (pkgs.writeShellScriptBin "ng" ''
      #!/usr/bin/env bash
      # Interactive content search -> open in Neovim at match
      set -euo pipefail
      dir="''${1:-.}"

      # fzf runs with an empty list first; on each keystroke (change),
      # we reload results from ripgrep using the current query {q}.
      # We show file:line:col:text and preview the match with context.
      selection="$(
        FZF_DEFAULT_OPTS="--height=80% --layout=reverse --border" \
        fzf --ansi --disabled --query "" \
          --prompt="rg> " \
           --bind "change:reload:rg --vimgrep -F --smart-case --hidden --glob '!.git' --no-messages --color=never -- {q} ''${dir} | cut -d: -f1-3 || true" \
           --delimiter=":" \
           --with-nth=1,2,3 \
           --nth=1,2,3 \
          --preview "bash -c 'q=\$1; file=\$2; [ -z \"\$q\" ] || [ ! -f \"\$file\" ] && exit 0; rg -F --no-heading --smart-case --color=always -n -C 5 -- \"\$q\" -- \"\$file\" || true' preview {q} {1}" \
          --preview-window 'up,60%,border-bottom,wrap' \
          --pointer="➤" --marker="✓"
      )" || exit 0

      # Selection format: file:line:col:matchtext
      file="$(printf %s "''${selection}" | cut -d: -f1)"
      line="$(printf %s "''${selection}" | cut -d: -f2)"
      col="$(printf  %s "''${selection}" | cut -d: -f3)"

      [ -n "''${file}" ] || exit 0

      # Jump to line:col in Neovim
      exec nvim "+call cursor(''${line},''${col})" -- "''${file}"
    '')

    # nfg ("nvim file grep"): Fuzzy search file content; open file picker of results; open in Neovim
    (pkgs.writeShellScriptBin "nfg" ''
      set -euo pipefail
      printf "grep: "
      IFS= read -r q
      [ -z "$q" ] && exit 0
      file="$(
        rg -l --no-messages -- "$q" \
        | fzf --preview "rg --pretty --context 5 -- '$q' {}"
      )" || exit 0
      exec nvim "$file"
    '')
  ];
}
