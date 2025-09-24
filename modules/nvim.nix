{ config, pkgs, lib, ... }:

let
  haveNerd = true;
in
{
  imports = [
    ./vim-shared.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    #enableLuaLoader = true;

    # Bas
    globals = { mapleader = " "; have_nerd_font = haveNerd; };
    # List all options by  :h option-list
    opts = {
      number = true;
      relativenumber = true;
      mouse = "a";
      showmode = false;
      clipboard = "unnamedplus";
      breakindent = true;
      undofile = true;
      ignorecase = true;
      smartcase = true;
      signcolumn = "yes";
      updatetime = 250;
      timeoutlen = 300;
      splitright = true;
      splitbelow = true;
      list = true;
      listchars = "tab:» ,trail:·,nbsp:␣";
      inccommand = "split";
      cursorline = true;
      scrolloff = 5;
      confirm = true;
      termguicolors = true;
      expandtab = true; shiftwidth = 2; tabstop = 2; smartindent = true;
      viewoptions = "folds,cursor,curdir";
    };

    # Autocmds
    autoCmd = [
      {
        event = [ "TextYankPost" ];
        desc = "Highlight when yanking text";
        #group = "highlight-yank";
        callback.__raw = "function() vim.hl.on_yank() end";
      }

      {
        event = [ "BufReadPost" ];
        desc = "Return to last cursor position";
        callback.__raw = ''
          function(args)
            -- Don't jump in special buffer types (commit, rebase, etc.)
            local ft = vim.bo[args.buf].filetype
            if ft == "gitcommit" or ft == "gitrebase" then return end
            if vim.opt.diff:get() then return end

            local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
            local lcount = vim.api.nvim_buf_line_count(args.buf)
            local lnum, col = mark[1], mark[2]
            if lnum > 0 and lnum <= lcount then
              pcall(vim.api.nvim_win_set_cursor, 0, { lnum, col })
            end
          end
        '';
      }

      # Create dirs automatically b4 save
      #{
      #  event = [ "BufWritePre" ];
      #  pattern = [ "*" ];
      #  command = ''
      #    lua <<'LUA'
      #    local dir = vim.fn.expand("%:p:h")
      #    if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
      #      vim.fn.mkdir(dir, "p")
      #    end
      #    LUA
      #  '';
      #}
    ];

    # Keymaps
    keymaps = [
      # Normal: Ctrl-S saves (silent, only if changed with :update)
      { mode = "n"; key = "<C-s>"; action = ":update<CR>"; options.silent = true; }

      # Insert: Ctrl-S saves and stays in Insert
      { mode = "i"; key = "<C-s>"; action = "<C-o>:update<CR>"; options.silent = true; }

      # Visual/Select: Ctrl-S saves
      { mode = "v"; key = "<C-s>"; action = "<C-c>:update<CR>"; options.silent = true; }
      { mode = "x"; key = "<C-s>"; action = "<C-c>:update<CR>"; options.silent = true; }
      { mode = "s"; key = "<C-s>"; action = "<C-c>:update<CR>"; options.silent = true; }

      # Leader save bindings
      { mode = "n"; key = "<leader>w"; action = ":update<CR>"; options.silent = true; }
      { mode = "n"; key = "<leader>W"; action = ":wall<CR>";  options.silent = true; }

      { mode = [ "n" "v" ]; key = "<Space>"; action = "<Nop>"; options.silent = true; }
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; options.desc = "Clear search highlight"; }
      { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\\\><C-n>"; options.desc = "Exit terminal"; }
      { mode = "n"; key = "<C-h>"; action = "<C-w><C-h>"; options.desc = "Win left"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w><C-l>"; options.desc = "Win right"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w><C-j>"; options.desc = "Win down"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w><C-k>"; options.desc = "Win up"; }
      #{ mode = "i"; key = "jk"; action = "<Esc>"; options.silent = true; }

      # Telescope binds
      { mode = "n"; key = "<leader>sh"; action.__raw = "require('telescope.builtin').help_tags"; options.desc = "[S]earch [H]elp"; }
      { mode = "n"; key = "<leader>sk"; action.__raw = "require('telescope.builtin').keymaps"; options.desc = "[S]earch [K]eymaps"; }
      { mode = "n"; key = "<leader>sf"; action.__raw = "require('telescope.builtin').find_files"; options.desc = "[S]earch [F]iles"; }
      { mode = "n"; key = "<leader>ss"; action.__raw = "require('telescope.builtin').builtin"; options.desc = "[S]elect Telescope"; }
      { mode = "n"; key = "<leader>sw"; action.__raw = "require('telescope.builtin').grep_string"; options.desc = "[S]earch current [W]ord"; }
      { mode = "n"; key = "<leader>sg"; action.__raw = "require('telescope.builtin').live_grep"; options.desc = "[S]earch by [G]rep"; }
      { mode = "n"; key = "<leader>sd"; action.__raw = "require('telescope.builtin').diagnostics"; options.desc = "[S]earch [D]iagnostics"; }
      { mode = "n"; key = "<leader>sr"; action.__raw = "require('telescope.builtin').resume"; options.desc = "[S]earch [R]esume"; }
      { mode = "n"; key = "<leader>s."; action.__raw = "require('telescope.builtin').oldfiles"; options.desc = "Recent files"; }
      {
        mode = "n"; key = "<leader>/";
        action.__raw = ''
          function()
            require('telescope.builtin').current_buffer_fuzzy_find(
              require('telescope.themes').get_dropdown({ winblend = 10, previewer = false })
            )
          end
        '';
        options.desc = "Fuzzy search in buffer";
      }
      {
        mode = "n"; key = "<leader>s/";
        action.__raw = ''
          function()
            require('telescope.builtin').live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
          end
        '';
        options.desc = "[S]earch [/] in open files";
      }
      {
        mode = "n"; key = "<leader>f";
        action.__raw = ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
        options.desc = "[F]ormat buffer";
      }

      { mode = "n"; key = "<leader>u>"; action = "<cmd>UndotreeToggle<CR>"; options.desc = "Undo tree"; }
      #{ mode = "n"; key = "<leader>u>"; action = "<cmd>Telescope undo<CR>"; options.desc = "Undo tree"; }
    ];

    # Tema
    colorschemes.tokyonight.enable = true;
    colorscheme = "tokyonight-night";

    plugins = {
      which-key = {
        enable = true;
        settings.delay = 0;
      };

      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
      };
      web-devicons.enable = haveNerd;

      treesitter = {
        enable = true;
        settings = {
          ensure_installed = [
            "bash" "c" "cpp" "lua" "python" "rust" "go"
            "javascript" "typescript" "tsx"
            "json" "yaml" "toml" "nix" "markdown" "regex" "diff" "vim" "vimdoc" "luadoc" "markdown_inline" "query"
          ];
          highlight.enable = true;
          highlight.additional_vim_regex_highlighting = [ "ruby" ];
          indent.enable = true;
          indent.disable = [ "ruby" ];
        };
      };

      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          signs = {
            add.text = "+";
            change.text = "~";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
        };
      };

      nvim-autopairs.enable = true;
      indent-blankline.enable = true;

      neo-tree.enable = true;
      lint.enable = true;
      dap.enable = true;

      undotree.enable = true;

      # Completion: blink.cmp
        #"blink-cmp" = {
        #  enable = true;
        #  settings = {
        #    appearance.nerd_font_variant = "mono";
        #    signature.enabled = true;
        #    snippets.preset = "luasnip";
        #    completion.documentation.auto_show = false;
        #    sources = {
        #      default = [ "lsp" "path" "snippets" ];
        #    };
        #    fuzzy.implementation = "lua";
        #  };
        #};

      # LSP (utan Mason)
      lsp = {
        enable = true;
        servers = {
          lua_ls = { enable = true; settings.Lua.completion.callSnippet = "Replace"; };
          bashls.enable = true;
          pyright.enable = true;
          ts_ls.enable = true;          # om din Nixvim-version kräver tsserver: byt till tsserver
          rust_analyzer = { enable = true; installCargo = true; installRustc = true; };
          gopls.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;
        };
        #diagnostics = {
        #  severity_sort = true;
        #  float = { border = "rounded"; source = "if_many"; };
        #  underline.severity = "ERROR";
        #  signs = lib.mkIf haveNerd {
        #    text = { ERROR = "󰅚 "; WARN = "󰀪 "; INFO = "󰋽 "; HINT = "󰌶 "; };
        #  };
        #  virtual_text = { source = "if_many"; spacing = 2; };
        #};
      };

      # formatter
      conform-nvim = {
        enable = true;
        settings = {
          notify_on_error = false;
          format_on_save = { lsp_format = "fallback"; timeout_ms = 500; };
          formatters_by_ft = { lua = [ "stylua" ]; };
        };
      };
    };

    #extraPlugins = [ pkgs.vimPlugins.vimplugin-telescope-undo-nvim ];

    extraConfigVim = "source ${config.xdg.configHome}/vim/shared-maps.vim";

    # nvim-lint-mappning + auto-run
    extraConfigLua = ''
      local lint = require("lint")
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        tsx        = { "eslint_d" },
        jsx        = { "eslint_d" },
        lua        = { "luacheck" },
        python     = { "ruff" },
        nix        = { "deadnix" },
        sh         = { "shellcheck" },
        bash       = { "shellcheck" },
        zsh        = { "shellcheck" },
        go         = { "golangci_lint" },
        markdown   = { "markdownlint" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function() require("lint").try_lint() end,
      })

      vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
      --require("telescope").load_extension("undo")
    '';
  };

  home.packages = with pkgs; [
    ripgrep fd git gcc nodejs
    lua-language-server rust-analyzer gopls
    typescript-language-server typescript pyright
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
    nodePackages.bash-language-server
    nodePackages.eslint_d ruff deadnix shellcheck golangci-lint markdownlint-cli
    lua54Packages.luacheck
  ];
}

