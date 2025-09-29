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
      # END rnd dev deps

      docker
      terraform
      google-cloud-sdk
      gcp_python
      python312Packages.keyrings-google-artifactregistry-auth
      python313Packages.keyrings-google-artifactregistry-auth
    ];

    home = {
      sessionPath = [
        "${gcp_python}/bin"
        #"$HOME/.npm-packages/bin"
      ];
      sessionVariables = {
        PYTHON_KEYRING_BACKEND = "keyrings.google_artifactregistry_auth.GoogleArtifactRegistryKeyring";
        #LD_LIBRARY_PATH = "${pkgs.glibc}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib${"\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"}";
        #NPM_CONFIG_PREFIX = "$HOME/.npm-packages";
      };
      #  activation.createNpmPrefix = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #    mkdir -p "$HOME/.npm-packages/bin""
      #  '';
    };

    xdg.configFile."pypoetry/config.toml".text = ''
      [virtualenvs]
      in-project = true
      create = true
      prefer-active-python = true

      [virtualenvs.options]
      system-site-packages = true
    '';

    programs.poetry = {
      enable = true;
      package = pkgs.poetry;
    };
  }
