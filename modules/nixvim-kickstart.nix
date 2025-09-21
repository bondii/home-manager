{ config, pkgs, ... }:

let
  # Verktyg som Telescope mår bra av, + språkserver & formatter
  extraBins = with pkgs; [
    ripgrep fd
    lua-language-server
    stylua
  ];
in {
  programs.nixvim = {
    enable = true;

    # Håll konfen ren – använd bara Nixgenererad runtimepath
    impureRtp = false;                                           # :contentReference[oaicite:8]{index=8}
    extraPackages = extraBins;

    # (Frivilligt) slå på Lua loader utan påhittad option
    extraConfigLuaPre = ''
      if vim.loader ~= nil then vim.loader.enable() end
    '';

    # === Optionen ur din init.lua ===
    opts = {
      number = true;
      mouse = "a";
      showmode = false;

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
      scrolloff = 10;
      confirm = true;
      clipboard = "unnamedplus";
    };

    # === Autocommands (fixar highlight-yank) ===
    autoGroups."kickstart-highlight-yank".clear = true;          # skapar gruppen
    autoCmd = [
      {
        event = "TextYankPost";
        desc = "Highlight when yanking (copy)";
        group = "kickstart-highlight-yank";
        callback.__raw = "function() vim.hl.on_yank() end";      # :contentReference[oaicite:9]{index=9}
      }
    ];

    # === Keymaps (lägg desc under options.desc) ===                 # :contentReference[oaicite:10]{index=10}
    keymaps = [
      # generellt
      { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; options.desc = "Clear search highlight"; }
      { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\><C-n>";    options.desc = "Exit terminal mode"; }

      # fönsternavigation
      { mode = "n"; key = "<C-h>"; action = "<C-w><C-h>"; options.desc = "Move focus left"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w><C-l>"; options.desc = "Move focus right"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w><C-j>"; options.desc = "Move focus down"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w><C-k>"; options.desc = "Move focus up"; }

      # diagnostics
      {
        mode = "n";
        key = "<leader>q";
        action.__raw = "vim.diagnostic.setloclist";
        options.desc = "Open diagnostic Quickfix list";
      }

      # format via conform.nvim (ersätter din lua-nyckelbindning)
      {
        mode = [ "n" "x" "o" ];
        key = "<leader>f";
        action.__raw = ''
          function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end
        '';
        options.desc = "[F]ormat buffer";
      }

      # Telescope (matchar Kickstarts bindningar)
      { mode = "n"; key = "<leader>sh"; action.__raw = "require('telescope.builtin').help_tags";         options.desc = "[S]earch [H]elp"; }
      { mode = "n"; key = "<leader>sk"; action.__raw = "require('telescope.builtin').keymaps";           options.desc = "[S]earch [K]eymaps"; }
      { mode = "n"; key = "<leader>sf"; action.__raw = "require('telescope.builtin').find_files";        options.desc = "[S]earch [F]iles"; }
      { mode = "n"; key = "<leader>ss"; action.__raw = "require('telescope.builtin').builtin";           options.desc = "[S]elect Telescope"; }
      { mode = "n"; key = "<leader>sw"; action.__raw = "require('telescope.builtin').grep_string";       options.desc = "[S]earch current [W]ord"; }
      { mode = "n"; key = "<leader>sg"; action.__raw = "require('telescope.builtin').live_grep";         options.desc = "[S]earch by [G]rep"; }
      { mode = "n"; key = "<leader>sd"; action.__raw = "require('telescope.builtin').diagnostics";       options.desc = "[S]earch [D]iagnostics"; }
      { mode = "n"; key = "<leader>sr"; action.__raw = "require('telescope.builtin').resume";            options.desc = "[S]earch [R]esume"; }
      { mode = "n"; key = "<leader>s."; action.__raw = "require('telescope.builtin').oldfiles";          options.desc = "[S]earch recent files"; }
      { mode = "n"; key = "<leader><leader>"; action.__raw = "require('telescope.builtin').buffers";     options.desc = "Find buffers"; }
      {
        mode = "n"; key = "<leader>/";
        action.__raw = ''
          function()
            require('telescope.builtin').current_buffer_fuzzy_find(
              require('telescope.themes').get_dropdown({ winblend = 10, previewer = false })
            )
          end
        '';
        options.desc = "[/] Fuzzy search in buffer";
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
        mode = "n"; key = "<leader>sn";
        action.__raw = ''
          function()
            require('telescope.builtin').find_files({ cwd = vim.fn.stdpath("config") })
          end
        '';
        options.desc = "[S]earch [N]eovim files";
      }
    ];

    # === Färgschema Tokyonight ===
    colorschemes.tokyonight.enable = true;                       # modul för temat
    colorscheme = "tokyonight-night";                            # välj variant (night)  :contentReference[oaicite:11]{index=11}

    # === Plugins ===
    plugins = {
      which-key.enable = true;

      # Telescope + extensions
      telescope = {
        enable = true;
        extensions = {
          fzf-native = { enable = true; };                       # aktivera C-accelererad sorterare  :contentReference[oaicite:12]{index=12}
          ui-select = {
            enable = true;
            settings = { __raw = "require('telescope.themes').get_dropdown()"; };
          };
        };
      };

      # Gitsigns (matchar dina tecken)
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        ensureInstalled = [ "bash" "c" "diff" "html" "lua" "luadoc" "markdown" "markdown_inline" "query" "vim" "vimdoc" ];
        settings = {
          highlight.enable = true;
          highlight.additional_vim_regex_highlighting = [ "ruby" ];
          indent.enable = true;
          indent.disable = [ "ruby" ];
        };
      };

      # LSP (utan Mason – vi levererar binärer via Nix)
      lsp = {
        enable = true;
        servers.lua-ls = {
          enable = true;
          settings.Lua.completion.callSnippet = "Replace";
        };
      };

      # Formatters: conform.nvim
      conform-nvim = {
        enable = true;
        # Din Kickstart-logik: format_on_save med fallback
        settings = {
          notify_on_error = false;
          format_on_save = {
            # disable_filetypes = { c = true; cpp = true; };
            lsp_format = "fallback";
            timeout_ms = 500;
          };
          formatters_by_ft = { lua = [ "stylua" ]; };
        };
      };

      # which-key: minimalt för att matcha Kickstarts känsla
      # (Delay och icons görs i pluginet själv; lämna default eller justera här vid behov)
      # plugins.which-key.settings.delay = 0;  # finns i pluginet  :contentReference[oaicite:13]{index=13}

      # blink.cmp – rätt plats för providers (under sources)
      "blink-cmp" = {
        enable = true;
        settings = {
          appearance.nerd_font_variant = "mono";
          signature.enabled = true;
          snippets.preset = "luasnip";
          completion.documentation.auto_show = false;

          # Viktigt: providers under sources (annars får du ditt fel)
          sources = {
            default = [ "lsp" "path" "snippets" "lazydev" ];
            providers.lazydev = {
              module = "lazydev.integrations.blink";
              score_offset = 100;
            };
          };

          fuzzy.implementation = "lua";
        };
      };
    };

    # === Telescope/diagnostic & annat som är enklast i Lua ===
    extraConfigLuaPost = ''
      -- Diagnostic-utseende (globalt)
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = (vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN]  = "󰀪 ",
            [vim.diagnostic.severity.INFO]  = "󰋽 ",
            [vim.diagnostic.severity.HINT]  = "󰌶 ",
          },
        }) or {},
        virtual_text = {
          source = "if_many",
          spacing = 2,
          format = function(d)
            return d.message
          end,
        },
      })
    '';
  };

  # (valfritt) Sätt which-key-gruppnamn om du vill se grupper i pop-up
  # programs.nixvim.plugins.which-key.settings.spec = [
  #   { "<leader>s"; group = "[S]earch"; }
  #   { "<leader>t"; group = "[T]oggle"; }
  #   { "<leader>h"; group = "Git [H]unk"; mode = [ "n" "v" ]; }
  # ];

}

