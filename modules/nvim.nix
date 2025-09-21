{ config, pkgs, lib, ... }:

let
  # Optional: nixGL wrapper if you run GL-demanding Nix-apps
  # nixGL = pkgs.nixgl;  # add if/when you want to wrap GUI-apps
in
{
  programs.nixvim = {
    enable = true;

    # Base settings ≈ lua/pontus/options.lua
    globals.mapleader = " ";
    opts = {
      number = true; relativenumber = true;
      mouse = "a"; clipboard = "unnamedplus";
      termguicolors = true; signcolumn = "yes";
      splitbelow = true; splitright = true;
      updatetime = 250; timeoutlen = 300;
      expandtab = true; shiftwidth = 2; tabstop = 2; smartindent = true;
    };

    # Keymaps ≈ lua/pontus/keymaps.lua
    keymaps = [
      # Make Space "neutral" in Normal/Visual
      { mode = [ "n" "v" ]; key = "<Space>"; action = "<Nop>"; options.silent = true; }

      { mode = "n"; key = "<leader>ff"; action = "<cmd>Telescope find_files<CR>"; options.desc = "Find files"; }
      { mode = "n"; key = "<leader>fg"; action = "<cmd>Telescope live_grep<CR>"; options.desc = "Live grep"; }
      { mode = "n"; key = "<leader>fb"; action = "<cmd>Telescope buffers<CR>";   options.desc = "Buffers"; }
      { mode = "n"; key = "<leader>fh"; action = "<cmd>Telescope help_tags<CR>"; options.desc = "Help tags"; }
      { mode = "n"; key = "<leader>e";  action = "<cmd>Neotree toggle<CR>";      options.desc = "Neo-tree"; }

      # "j+k" as Escape in Insert
      { mode = "i"; key = "jk"; action = "<Esc>"; options.silent = true; }
    ];

    # Plugins motsvarande kickstart/custom:
    plugins = {
      web-devicons.enable = true;

      # Fuzzy finder
      telescope.enable = true;
      telescope.extensions.fzf-native.enable = true;

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          ensure_installed = [
            "bash" "c" "cpp" "lua" "python" "rust" "go"
            "javascript" "typescript" "tsx"
            "json" "yaml" "toml" "nix" "markdown" "regex"
          ];
        };
      };

      # Git
      gitsigns.enable = true;
      gitsigns.settings.current_line_blame = true;

      # Pairs / indent guides
      nvim-autopairs.enable = true;
      indent-blankline.enable = true;

      # File tree, lint, debug
      neo-tree.enable = true;
      lint.enable = true;
      dap.enable = true;

      # Completion (cmp + paths + snippets)
      cmp.enable = true;
      "cmp-nvim-lsp".enable = true;
      "cmp-path".enable = true;
      "cmp-buffer".enable = true;
      luasnip.enable = true;

      # LSP
      lsp = {
        enable = true;
        servers = {
          lua_ls.enable = true;
          bashls.enable = true;
          pyright.enable = true;
          ts_ls.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          gopls.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;
        };
      };
    };

    extraConfigLuaPre = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
    '';

    extraConfigLua = ''
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        tsx        = { "eslint_d" },
        lua        = { "luacheck" },
        python     = { "ruff" },
        nix        = { "deadnix" },
        sh         = { "shellcheck" },
        go         = { "golangci_lint" },
        markdown   = { "markdownlint" },
        -- ['*'] = { 'typos' },      -- global linter exempel
        -- ['_'] = { 'fallback' },   -- fallback-filtyp
      }

      -- Run linters automatically at reasonable events
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function() require("lint").try_lint() end,
      })
    '';
  };

  # LSP/tools in user-profil
  home.packages = with pkgs; [
    ripgrep fd git gcc nodejs
    lua-language-server
    rust-analyzer gopls

    typescript-language-server
    typescript

    pyright  # LSP Python
  ];
}

