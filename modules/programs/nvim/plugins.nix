{ haveNerd }:
{
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
    highlight = {
      enable = true;
      enableVimSyntax = [ "ruby" ];
    };
    indent = {
      enable = true;
      disable = [ "ruby" ];
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

  neo-tree = {
    enable = true;
    settings = {
      close_if_last_window = true;
      filesystem = {
        bind_to_cwd = false;
        follow_current_file = {
          enabled = true;
        };
        use_libuv_file_watcher = true;
      };
      window = {
        width = 32;
        mappings = {
          "<space>" = "none";
        };
      };
    };
  };

  lint.enable = true;
  dap.enable = true;

  undotree = {
    enable = true;
    settings = {
      DiffAutoOpen = true;
      SetFocusWhenToggle = true;
    };
  };

  luasnip.enable = true;
  friendly-snippets.enable = true;

  # Completion: blink.cmp
  "blink-cmp" = {
    enable = true;

    settings = {
      appearance.nerd_font_variant = "mono";
      signature.enabled = true;
      snippets.preset = "luasnip";
      completion.documentation.auto_show = false;
      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
        ];
      };
      fuzzy.implementation = "lua";

      keymap = {
        "<S-CR>" = [ "accept" ];
        "<S-Tab>" = [ "select_next" ];
        #"<S-Tab>" = [ "select_prev" ];
      };
    };
  };

  guess-indent.enable = true;
  todo-comments.enable = true;

  mini = {
    enable = true;
    modules = {
      ai = {
        enable = true;
      };
      #bufremove = { enable = true; };
      #comment = { enable = true; };
      #cursorword = { enable = true; };
      #indentscope = {enable = true;};
      #move = { enable = true; };
      #pairs = { enable = true; };
      #sessions = { enable = true; };
      #splitjoin = { enable = true; };
      surround = {
        enable = true;
        mappings = {
          add = "ma";
          delete = "md";
          find = "mf";
          find_left = "mF";
          highlight = "mh";
          replace = "mr";
          update_n_lines = "mn";
        };
      };
      #tabline = { enable = true; };
      #trailspace = { enable = true; };
      statusline = {
        enable = true;
      };
    };
  };

  hlchunk = {
    enable = true;
    settings = {
      blank = {
        enable = false;
        chars = [ " " ];
        style = [
          { bg = "#434437"; }
          { bg = "#2f4440"; }
          { bg = "#433054"; }
          { bg = "#284251"; }
        ];
      };
      chunk = {
        enable = true;
        use_treesitter = true;
        #style.fg = "#91bef0";
        max_file_size = 10 * 1024 * 1024;
        chars = {
          horizontal_line = "─";
          left_bottom = "╰";
          left_top = "╭";
          right_arrow = "─";
          vertical_line = "│";
        };
        exclude_filetypes = {
          lazyterm = true;
          neo-tree = true;
        };
      };
      indent = {
        enable = true;
        chars = [ "│" ];
        exclude_filetypes = {
          lazyterm = true;
          neo-tree = true;
        };
        #style.fg = "#45475a";
        style = [
          "#434437"
          "#2f4440"
          "#433054"
          "#284251"
        ];
        use_treesitter = false;
      };
      line_num = {
        enable = true;
        use_treesitter = true;
        #style = "#91bef0";
      };
    };
  };

  copilot-lua = {
    enable = true;
    settings = {
      suggestion = {
        enabled = true;
        auto_trigger = true;
        debounce = 75;
        keymap = {
          accept = "<Tab>";
          accept_word = "<M-w>";
          accept_line = "<M-l>";
          next = "<M-]>";
          prev = "<M-[>";
          dismiss = "<C-]>";
        };
      };
      panel = {
        enabled = true;
        keymap = {
          open = "<leader>cp";
        };
      };
      filetypes = {
        markdown = true;
        gitcommit = true;
        nix = true;
        lua = true;
        python = true;
        javascript = true;
        typescript = true;
        # "*": true;
      };
    };
  };

  opencode = {
    enable = true;
    autoLoad = true;
    settings = {
      auto_reload = true;
      # port = 8080;
    };
  };

  snacks = {
    enable = true;
    settings = {
      input.enabled = true;
      picker.enabled = true;
      terminal.enabled = true;
      toggle.enabled = true;
    };
  };

  neoscroll = {
    enable = true;
    settings = {
      easing_function = "cubic";
      hider_cursor = true;
      #mappings.__empty = null;
      #mappings = ["<C-j>" "<C-k>"];
    };
  };

  smear-cursor = {
    enable = false;
    settings = {
      legacy_computing_symbols_support = true;
      never_draw_over_target = true;
      hide_target_hack = true;
      #delay_animation_start = 10;
      min_jump = 3;

      #time_interval = 8;

      gradient_exponent = 0;

      particles_enabled = false;
      particle_spread = 1.25;
      particles_per_second = 150; # 100
      particles_per_length = 100; # 75
      particle_max_lifetime = 1500;
      particle_max_initial_velocity = 15; # 20;
      particle_velocity_from_cursor = 1;
      particle_damping = 0.05; # 0.15;
      particle_gravity = 20; # 50
      #min_distance_emit_particles = 0.25;
    };
  };

  #rainbow.enable = true;
  rainbow-delimiters.enable = true;

  twilight = {
    enable = true;
    settings = {
      dimming = {
        alpha = 0.55; # amount of dimming
        # Try to get the foreground from the highlight groups or fallback color
        color = [
          "Normal"
          "#ffffff"
        ];
        term_bg = "#000000"; # if guibg=NONE, this will be used to calculate text color
        inactive = false; # when true, other windows will be fully dimmed (unless they contain the same buffer)
      };
      context = 10; # amount of lines we will try to show around the current lineb
      treesitter = true; # use treesitter when available for the filetype
      # treesitter is used to automatically expand the visible text,
      # but you can further control the types of nodes that should always be fully expanded
      expand = [
        # for treesitter, we we always try to expand to the top-most ancestor with these types
        "function"
        "method"
        "table"
        "if_statement"
      ];
      exclude = [ ]; # exclude these filetypes
    };
  };
}
