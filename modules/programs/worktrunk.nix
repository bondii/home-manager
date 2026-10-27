{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.pontus.features;
  worktrunk = inputs.worktrunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
lib.mkIf cfg.dev {
  home.packages = [ worktrunk ];

  # Worktrees live under ~/opac/wt/<repo>/<branch>. New worktrees get the
  # developer's own .env and .envrc.local from the main checkout; the committed
  # .envrc arrives with the checkout and direnv trusts ~/opac already.
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "${config.home.homeDirectory}/opac/wt/{{ repo }}/{{ branch | sanitize }}"

    [pre-start]
    local-env = """
    for f in .env .envrc.local; do
      if [ -f "{{ primary_worktree_path }}/$f" ]; then
        cp -n "{{ primary_worktree_path }}/$f" "$f"
      fi
    done
    """
  '';

  programs.zsh.initContent = ''
    eval "$(${worktrunk}/bin/wt config shell init zsh)"
  '';
}
