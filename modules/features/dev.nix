{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pontus.features;

  postgresqlMajor = lib.versions.major pkgs.postgresql.version;
  homeDir = config.home.homeDirectory;
  pgadminPackage = pkgs.pgadmin4-desktopmode;
  # Ensure pgAdmin sees ~/.pgadmin/config_local.py.
  pgadminWrapped = pkgs.symlinkJoin {
    name = "pgadmin4-wrapped";
    paths = [ pgadminPackage ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/pgadmin4" \
        --prefix PYTHONPATH : ${homeDir}/.pgadmin
    '';
  };
in
lib.mkIf cfg.dev {
  home.packages =
    with pkgs;
    [
      ripgrep
      fd
      lsof
      netcat-openbsd
      #gcc
      nodejs
      lua-language-server
      rust-analyzer
      gopls
      typescript-language-server
      typescript
      pyright
      vscode-langservers-extracted
      yaml-language-server
      bash-language-server
      eslint_d
      ruff
      deadnix
      shellcheck
      golangci-lint
      markdownlint-cli
      yamllint
      lua54Packages.luacheck
      hunspell
      hunspellDicts.sv_SE
      hunspellDicts.en-us
      enchant

      # Needed for e.g. numpy
      #stdenv.cc.cc.lib
      #glibc
      #zlib
      krb5

      #postgresql
      #libpq
      #openssl
      # END rnd dev deps

      (google-cloud-sdk.withExtraComponents [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
      google-cloud-sql-proxy
      kubectl
      (python314.withPackages (ps: with ps; [ pypdf ]))
      kubernetes-helm
      uv
      redis

    ]
    ++ lib.optionals cfg.gui [
      mqtt-explorer
      pgadminWrapped
      google-chrome
      rustdesk
    ];

  home = {
    sessionPath = [
      "$HOME/.npm-packages/bin"
    ];
    sessionVariables = {
      NPM_CONFIG_PREFIX = "$HOME/.npm-packages";
      USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
    };
    activation.createNpmPrefix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.npm-packages/bin"
    '';

    file.".pgadmin/config_local.py" = lib.mkIf cfg.gui {
      text = ''
        MASTER_PASSWORD_REQUIRED = True
        UPGRADE_CHECK_ENABLED = False
        DEFAULT_BINARY_PATHS = {
          "pg": "${pkgs.postgresql}/bin",
          "pg-${postgresqlMajor}": "${pkgs.postgresql}/bin",
        }
        FIXED_BINARY_PATHS = {
          "pg": "${pkgs.postgresql}/bin",
          "pg-${postgresqlMajor}": "${pkgs.postgresql}/bin",
        }
      '';
    };

    file = {
      ".config/ENVRC_EXAMPLE" = {
        text = ''
          #! /bin/bash .envrc
          export DEVENV_IN_DIRENV_SHELL=true

          watch_file flake.nix
          watch_file flake.lock
          if ! use flake . --no-pure-eval; then
            echo "devenv could not be built. The devenv environment was not loaded. Make the necessary changes to devenv.nix and hit enter to try again." >&2
          fi
        '';
      };
    };
  };

}
