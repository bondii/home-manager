{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.pontus.features;

  gcp_python = pkgs.python312.withPackages (ps: [
    ps.keyring
    ps.keyrings-google-artifactregistry-auth
    ps.google-auth
    ps.pip
    ps.setuptools
    ps.wheel
  ]);
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
      google-cloud-sdk
      google-cloud-sql-proxy
      gcp_python
      mqtt-explorer

      # Use this for installing python packages from GCP Artifact Registry
      (pkgs.writeShellScriptBin "poetry-gar" ''
        export POETRY_HTTP_BASIC_GCP_ARTIFACT_REGISTRY_USERNAME=oauth2accesstoken
        export POETRY_HTTP_BASIC_GCP_ARTIFACT_REGISTRY_PASSWORD="$(${pkgs.google-cloud-sdk}/bin/gcloud auth application-default print-access-token)"
        exec ${pkgs.poetry}/bin/poetry "$@"
      '')
    ];

    home = {
      sessionPath = [
        "${gcp_python}/bin"
        #"$HOME/.npm-packages/bin"
      ];
      sessionVariables = {
        PYTHON_KEYRING_BACKEND = "keyrings.google_artifactregistry_auth.GoogleArtifactRegistryKeyring";
        #NPM_CONFIG_PREFIX = "$HOME/.npm-packages";
      };
      #  activation.createNpmPrefix = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #    mkdir -p "$HOME/.npm-packages/bin""
      #  '';
    };

    programs.poetry = {
      enable = true;
      package = pkgs.poetry;
      settings.virtualenvs = {
        inProject = true;
        create = true;
        preferActivePython = true;
        options.system-site-packages = true;
      };
    };

    #xdg.configFile."cloud-sql-proxy/config.toml".text = ''
    #  instance-connection-name = "${pgdb-instance-dev}"
    #  auto-iam-authn = true       # aktivera automatisk IAM DB-inloggning
    #  address = "127.0.0.1"
    #  port = ${toString pgdb-port-dev}
    #  structured-logs = true
    #  private-ip = true         # om instansen bara har Private IP *och* din maskin når VPC:en
    #'';

    #systemd.user.services.cloud-sql-proxy = {
    #  Unit = {
    #    Description = "Cloud SQL Auth Proxy (PostgreSQL)";
    #    After = ["network-online.target"];
    #    Wants = ["network-online.target"];
    #  };
    #  Service = {
    #    # Använd konfigfilen ovan:
    #    ExecStart = "${pkgs.google-cloud-sql-proxy}/bin/cloud-sql-proxy --config-file ${config.xdg.configHome}/cloud-sql-proxy/config.toml";
    #    Restart = "always";
    #    RestartSec = 2;
    #    Environment = [
    #      "CSQL_PROXY_STRUCTURED_LOGS=true"
    #    ];
    #  };
    #  Install.WantedBy = ["default.target"];
    #};
  }
