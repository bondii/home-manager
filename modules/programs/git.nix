{
  config,
  lib,
  pkgs,
  ...
}:
let
  gitIgnorePath = "${config.xdg.configHome}/git/ignore";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "opac-wt" ''
      #!/usr/bin/env bash
      set -euo pipefail

      usage() {
        printf "usage: %s <new-branch-name>\n" "''${0##*/}" >&2
      }

      if [ "''${1:-}" = "--help" ] || [ "''${1:-}" = "-h" ]; then
        usage
        exit 0
      fi

      if [ "$#" -ne 1 ]; then
        usage
        exit 2
      fi

      branch="$1"
      srcDir="$(pwd -P)"
      repoName="$(basename -- "$srcDir")"
      destDir="$HOME/opac/wt/$repoName/$branch"

      mkdir -p -- "$(dirname -- "$destDir")"
      git worktree add -b "$branch" "$destDir"

      for f in .env .envrc AGENTS.md; do
        if [ -e "$srcDir/$f" ]; then
          cp -p -- "$srcDir/$f" "$destDir/"
        fi
      done
    '')
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      user = {
        name = "Pontus Eriksson";
        email = "pontus_eriksson@live.com";
      };
      core = {
        compression = 9;
        whitespace = "error";
        preloadIndex = true;
        excludesFile = gitIgnorePath;
      };
      advice = {
        addEmptyPathspec = false;
        pushNonFastForward = false;
        statusHints = false;
      };
      status = {
        branch = true;
        showStash = true;
        showUntrackedFiles = true;
      };
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      pull = {
        default = "current";
        autoSetupRemote = true;
        rebase = true;
      };
      rebase = {
        autoStash = true;
        missingCommitsCheck = "warn";
      };
      diff = {
        context = 3;
        algorithm = "histogram";
        colorMoved = "zebra";
        colorMovedWS = "allow-indentation-change";
        indentHeuristic = true;
        renames = true;
        interHunkContext = 10;
      };
      merge.conflictStyle = "zdiff3";
      pager = {
        diff = "delta";
        log = "delta";
        reflog = "delta";
        show = "delta";
        branch = false;
      };
      interactive.singleKey = true;
      rerere.enabled = true;
      branch.sort = "committerdate";
      alias = {
        lg = "log --all --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";

        # Git på Svenska
        ryck = "pull";
        knuff = "push";
        gren = "branch";
        bifall = "commit -v";
        ympa = "rebase";
        klona = "clone";
        kolla = "checkout";
        kika = "fetch";
        vask = "restore";
        whoops = "commit --amend --no-edit";
        visa = "show";
        foga = "merge --ff-only";

        dra = "pull";
        sammanfoga = "merge";
        lagra = "stash";
        klandra = "blame";
        mark = "tag";
        markera = "tag";
        byt = "switch";
        kapa = "branch -D";

        flex = ''!f() { git diff --numstat "$1" | awk '{added += $1; removed += $2} END {print "Added lines:", added, "| Removed lines:", removed}'; }; f'';
      };
    };

    includes = [
      {
        condition = "gitdir:~/opac/";
        contents.user.email = "pontus.eriksson@opac.se";
      }
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "side-by-side line-numbers decorations";
      navigate = true;
    };
  };

  xdg.configFile."git/ignore".text = ''
    # Global ignore patterns applied across repositories.
    .codex/
    .specify/
    AGENTS.md
    .agents/
  '';
}
