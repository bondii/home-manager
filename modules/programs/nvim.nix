{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pontus.features;
  haveNerd = cfg.fonts;
  core = import ./nvim/core.nix { inherit haveNerd; };
  keymaps = import ./nvim/keymaps.nix;
  plugins = import ./nvim/plugins.nix { inherit haveNerd; };
  lsp = import ./nvim/lsp.nix { inherit lib; };
  formatting = import ./nvim/formatting.nix;
in
{
  imports = [ ./vim-shared.nix ];

  config = lib.mkIf cfg.nixvim {
    home.packages = with pkgs; [
      terraform # Formatter (and CLI)
      terraform-ls
      tflint
      docker-language-server
      hadolint # Dockerfile linter
      dockfmt
      yamllint
      jq
      prettier
      shfmt
      stylua
      black
      ruff
    ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      # Nixvim builds its own nixpkgs instance (its `nixpkgs` input deliberately
      # does not follow ours - see flake.nix), so `nixpkgs.config.allowUnfree` in
      # modules/core/base.nix does not reach it. copilot-language-server is pulled
      # in by nixpkgs' vimPlugins.copilot-lua, used by plugins.copilot-lua below.
      nixpkgs.config.allowUnfree = true;

      #enableLuaLoader = true;

      inherit (core) globals opts autoCmd;
      inherit keymaps;

      # Tema
      colorschemes.tokyonight.enable = true;
      colorscheme = "tokyonight-night";

      plugins = plugins // {
        inherit lsp;
        conform-nvim = formatting;
      };

      extraPlugins = with pkgs.vimPlugins; [
        grug-far-nvim
        #vimplugin-telescope-undo-nvim
        markdown-preview-nvim
        vim-nix
      ];

      extraConfigVim = "source ${config.xdg.configHome}/vim/shared-maps.vim";

      # nvim-lint-mappning + auto-run
      extraConfigLua = builtins.readFile ./nvim/runtime.lua;
    };
  };
}
