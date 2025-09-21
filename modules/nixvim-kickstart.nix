{ pkgs, lib, ... }:
let
  haveNerdFont = true;
in {
  programs.nixvim = {
    enable = true;

    # ── Base options (vim.o / vim.opt)
    opts = {
      number = true;
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
      scrolloff = 10;
      confirm = true;
    };

    # En global som Kickstart använder för ikonuppsättningar
    globals.have_nerd_font = haveNerdFont;

    # ── Autocmds: highlight yank
    autoCmd = [
      {
        event = [ "TextYankPost" ];
        desc = "Highlight when yanking text";
        group = "kickstart-highlight-yank";
        callback.__raw = "function() vim.hl.on_yank() end";
      }
    ];  # autoCmd finns som modul i Nixvim. :contentReference[oaicite:0]{index=0}

    # ── Keymaps (inkl. terminal <Esc><Esc> och fönsterhjul)
    #keymaps = [
    #  { mode = "n"; key = "<Esc>"; action = "<cmd>nohlsearch<CR>"; desc = "Clear search highlight"; }
    #  { mode = "t"; key = "<Esc><Esc>"; action = "<C-\\\\><C-n>"; desc = "Exit terminal mode"; }
    #  { mode = "n"; key = "<C-h>"; action = "<C-w><C-h>"; desc = "Focus left window"; }
    #  { mode = "n"; key = "<C-l>"; action = "<C-w><C-l>"; desc = "Focus right window"; }
    #  { mode = "n"; key = "<C-j>"; action = "<C-w><C-j>"; desc = "Focus down window"; }
    #  { mode = "n"; key = "<C-k>"; action = "<C-w><C-k>"; desc = "Focus up window"; }
    #  # Telescope binds (matchar Kickstart)
    #  { mode = "n"; key = "<leader>sh"; action.__raw = "require('telescope.builtin').help_tags"; desc = "[S]earch [H]elp"; }
    #  { mode = "n"; key = "<leader>sk"; action.__raw = "require('telescope.builtin').keymaps"; desc = "[S]earch [K]eymaps"; }
    #  { mode = "n"; key = "<leader>sf"; action.__raw = "require('telescope.builtin').find_files"; desc = "[S]earch [F]iles"; }
    #  { mode = "n"; key = "<leader>ss"; action.__raw = "require('telescope.builtin').builtin"; desc = "[S]elect Telescope"; }
    #  { mode = "n"; key = "<leader>sw"; action.__raw = "require('telescope.builtin').grep_string"; desc = "[S]earch current [W]ord"; }
    #  { mode = "n"; key = "<leader>sg"; action.__raw = "require('telescope.builtin').live_grep"; desc = "[S]earch by [G]rep"; }
    #  { mode = "n"; key = "<leader>sd"; action.__raw = "require('telescope.builtin').diagnostics"; desc = "[S]earch [D]iagnostics"; }
    #  { mode = "n"; key = "<leader>sr"; action.__raw = "require('telescope.builtin').resume"; desc = "[S]earch [R]esume"; }
    #  { mode = "n"; key = "<leader>s."; action.__raw = "require('telescope.builtin').oldfiles"; desc = "[S]earch Recent Files"; }
    #  { mode = "n"; key = "<leader><leader>"; action.__raw = "require('telescope.builtin').buffers"; desc = "Find buffers"; }
    #  { mode = "n"; key = "<leader>/"; action.__raw =
    #      "function() require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown{ winblend=10, previewer=false }) end";
    #    desc = "Fuzzy in current buffer"; }
    #  { mode = "n"; key = "<leader>s/"; action.__raw =
    #      "function() require('telescope.builtin').live_grep{ grep_open_files=true, prompt_title='Live Grep in Open Files' } end";
    #    desc = "[S]earch [/] in open files"; }
    #  { mode = "n"; key = "<leader>sn"; action.__raw = "function() require('telescope.builtin').find_files{ cwd = vim.fn.stdpath('config') } end"; desc = "Search Neovim files"; }
    #];
    # keymaps-modulen & options beskrivs här. :contentReference[oaicite:1]{index=1}

    # ── Plugins
    plugins = {
      # Colorscheme: Tokyonight (utan kursiv i comments) + ladda 'night'
      #tokyonight = {
      #  enable = true;
      #  settings.styles.comments.italic = false;
      #  luaConfigPost = ''vim.cmd.colorscheme("tokyonight-night")'';
      #}; # Tokyonight finns som färdig modul. :contentReference[oaicite:2]{index=2}

      # which-key (delay=0 och ikonlogik som i Kickstart)
      which-key = {
        enable = true;
        settings = {
          delay = 0;
          # Ikoner & keys har egna undersektioner i modulen
        };
      }; # which-key-modulen & dess settings. :contentReference[oaicite:3]{index=3}

      # Telescope + fzf-native + ui-select + devicons
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
          ui-select.enable = true;
        };
      }; # fzf-native & ui-select är first-class i Nixvim. :contentReference[oaicite:4]{index=4}
      web-devicons.enable = haveNerdFont; # ikoner (krävs av flera UI-plugins). :contentReference[oaicite:5]{index=5}

      # Gitsigns med samma tecken som Kickstart
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
      }; # gitsigns stöds av Nixvim. :contentReference[oaicite:6]{index=6}

      # Treesitter
      treesitter = {
        enable = true;
        
        settings = {
          ensure_installed = [ "bash" "c" "diff" "html" "lua" "luadoc" "markdown" "markdown_inline" "query" "vim" "vimdoc" ];
          highlight.enable = true;
          highlight.additional_vim_regex_highlighting = [ "ruby" ];
          indent.enable = true;
          indent.disable = [ "ruby" ];
        };
      };

      # Statusline + textobj/surround via mini.nvim
      mini = {
        enable = true;
        modules = {
          ai = { n_lines = 500; };
          surround = { };
          statusline = { use_icons = haveNerdFont; };
        };
      }; # mini.* ingår i Nixvim plugin-trädet.

      # TODO-comments
      todo-comments.enable = true; # modul finns. :contentReference[oaicite:7]{index=7}

      # Formatter: conform.nvim (mappar <leader>f och on-save-policy)
      #conform-nvim = {
      #  enable = true;
      #  settings = {
      #    notify_on_error = false;
      #    format_on_save = {
      #      lsp_fallback = true;
      #      timeout_ms = 500;
      #    };
      #    formatters_by_ft.lua = [ "stylua" ];
      #  };
      #  keymaps = [{
      #    mode = [ "" ]; key = "<leader>f";
      #    action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end";
      #    options.desc = "[F]ormat buffer";
      #  }];
      #}; # conform-modulen och options. :contentReference[oaicite:8]{index=8}

      # LSP-HUD: fidget.nvim
      fidget.enable = true; # modul finns. :contentReference[oaicite:9]{index=9}

      # Completion: blink.cmp (Kickstart använder den)
      blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "default";
          appearance.nerd_font_variant = "mono";
          completion.documentation = { auto_show = false; auto_show_delay_ms = 500; };
          signature.enabled = true;
          sources.default = [ "lsp" "path" "snippets" "lazydev" ];
          providers.lazydev = { module = "lazydev.integrations.blink"; score_offset = 100; };
          snippets.preset = "luasnip";
          fuzzy.implementation = "lua";
        };
      }; # blink-cmp finns som Nixvim-plugin med inställningar. :contentReference[oaicite:10]{index=10}

      # Lua utvecklar-quality (lazydev)
      lazydev.enable = true;

      # LSP (utan Mason): vi låter Nix leverera servers
      lsp = {
        enable = true;
        # Kickstart hade mest lua_ls, men lägg gärna till fler här när du vill
        servers.lua_ls.enable = true;

        # Diagnostics-tuning ungefär som i Kickstart
        #diagnostics = {
        #  virtual_text = { source = "if_many"; spacing = 2; };
        #  underline.severity = "ERROR";
        #  float = { border = "rounded"; source = "if_many"; };
        #  severity_sort = true;
        #  signs = lib.mkIf haveNerdFont {
        #    text = {
        #      ERROR = "󰅚 ";
        #      WARN  = "󰀪 ";
        #      INFO  = "󰋽 ";
        #      HINT  = "󰌶 ";
        #    };
        #  };
        #};
      };
    };

    # Praktiska kommandon i Nixvim
    enableMan = true;                # :h funkar
    #enableLuaLoader = true;  # Supposed to give faste startup, but doesn't exist?
  };

  # ── Verktyg & språkservrar från Nix (ersätter Mason)
  home.packages = with pkgs; [
    lua-language-server
    stylua
    ripgrep fd git
  ];
}

