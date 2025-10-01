{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.pontus.features;
in
  lib.mkIf cfg.dev {
    home.packages = with pkgs; [
      ripgrep
      fd
      gcc
      nodejs
      lua-language-server
      rust-analyzer
      gopls
      typescript-language-server
      typescript
      pyright
      nodePackages.vscode-langservers-extracted
      nodePackages.yaml-language-server
      nodePackages.bash-language-server
      nodePackages.eslint_d
      ruff
      deadnix
      shellcheck
      golangci-lint
      markdownlint-cli
      lua54Packages.luacheck

      # Needed for e.g. numpy
      stdenv.cc.cc.lib
      glibc
      zlib
      krb5

      postgresql
      libpq
      openssl
      # END rnd dev deps

      docker
      terraform
      (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])
      google-cloud-sql-proxy
      mqtt-explorer
      kubectl
      python313
      kubernetes-helm

      devenv
    ];

    home = {
      sessionPath = [
        #"$HOME/.npm-packages/bin"
      ];
      sessionVariables = {
        #NPM_CONFIG_PREFIX = "$HOME/.npm-packages";
        USE_GKE_GCLOUD_AUTH_PLUGIN = "True";
      };
      #  activation.createNpmPrefix = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #    mkdir -p "$HOME/.npm-packages/bin""
      #  '';

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

    systemd.user.services = let
      mkCloudSqlProxy = {
        name,
        instance,
        port,
      }: {
        Unit = {
          Description = "Cloud SQL Auth Proxy (${name})";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Service = {
          ExecStart =
            "${pkgs.google-cloud-sql-proxy}/bin/cloud-sql-proxy "
            + "--address 127.0.0.1 "
            + "--port ${toString port} "
            + "--auto-iam-authn "
            #+ "--private-ip "
            + instance;
          Restart = "on-failure";
          RestartSec = 2;
          Environment = ["CSQL_PROXY_STRUCTURED_LOGS=true"];
        };
      };
    in {
      "cloud-sql-proxy-dev" = mkCloudSqlProxy {
        name = "dev";
        instance = "ship2shore-dev:europe-north1:maritime-instance";
        port = 1234;
      };
      "cloud-sql-proxy-prod" = mkCloudSqlProxy {
        name = "prod";
        instance = "ship2shore-prod:europe-north1:maritime-instance";
        port = 4321;
      };
    };
  }
