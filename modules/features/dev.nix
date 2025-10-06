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

    # programs.poetry = {
    #   enable = true;
    #   package = pkgs.poetry;
    #   settings.virtualenvs = {
    #     inProject = true;
    #     create = true;
    #     preferActivePython = true;
    #     options.system-site-packages = true;
    #   };
    # };
  }
