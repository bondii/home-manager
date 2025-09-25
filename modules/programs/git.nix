{ lib, pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    userName = "Pontus Eriksson";
    userEmail = "pontus_eriksson@live.com";

    extraConfig = {
      push = { default = "current"; autoSetupRemote = true; };
      pull = { default = "current"; autoSetupRemote = true; };
      pager.branch = false;
      rerere.enabled = true;
      branch.sort = "committerdate";
    };

    aliases = {
      lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";

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

    includes = [
      {
        condition = "gitdir:~/opac/";
        contents.user.email = "pontus.eriksson@opac.se";
      }
    ];
  };
}
