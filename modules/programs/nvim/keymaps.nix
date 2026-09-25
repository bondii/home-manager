[
  {
    mode = "n";
    key = "K";
    action.__raw = "vim.lsp.buf.hover";
    options.desc = "Hover";
  }
  # Jump to definition
  {
    mode = "n";
    key = "gd";
    action.__raw = "vim.lsp.buf.definition";
    options.desc = "Go to definition";
  }
  {
    mode = "n";
    key = "gD";
    # action.__raw = "vim.lsp.buf.declaration";
    # options.desc = "Go to declaration";
    action.__raw = "require('telescope.builtin').lsp_definitions";
    options.desc = "Definition";
  }
  {
    mode = "n";
    key = "gy";
    # action.__raw = "vim.lsp.buf.type_definition";
    # options.desc = "Go to type definition";
    action.__raw = "require('telescope.builtin').lsp_type_definitions";
    options.desc = "Type def";
  }
  {
    mode = "n";
    key = "gi";
    # action.__raw = "vim.lsp.buf.implementation";
    # options.desc = "Go to implementation";
    action.__raw = "require('telescope.builtin').lsp_implementations";
    options.desc = "Implementation";
  }
  {
    mode = "n";
    key = "gr";
    # action.__raw = "vim.lsp.buf.references";
    # options = {desc = "List references";};
    action.__raw = "require('telescope.builtin').lsp_references";
    options.desc = "Refs (Tel)";
  }

  # LSP Rename
  {
    mode = "n";
    key = "<F2>";
    action.__raw = "function() vim.lsp.buf.rename() end";
    options = {
      desc = "LSP Rename";
    };
  }
  {
    mode = [
      "n"
      "x"
    ];
    key = "<C-.>";
    action.__raw = "vim.lsp.buf.code_action";
    options.desc = "Code action";
  }

  # Normal: Ctrl-S saves (silent, only if changed with :update)
  {
    mode = "n";
    key = "<C-s>";
    action = ":update<CR>";
    options.silent = true;
  }

  # Insert: Ctrl-S saves and stays in Insert
  {
    mode = "i";
    key = "<C-s>";
    action = "<C-o>:update<CR>";
    options.silent = true;
  }

  # Visual/Select: Ctrl-S saves
  {
    mode = "v";
    key = "<C-s>";
    action = "<C-c>:update<CR>";
    options.silent = true;
  }
  {
    mode = "x";
    key = "<C-s>";
    action = "<C-c>:update<CR>";
    options.silent = true;
  }
  {
    mode = "s";
    key = "<C-s>";
    action = "<C-c>:update<CR>";
    options.silent = true;
  }

  # Leader save bindings
  {
    mode = "n";
    key = "<leader>w";
    action = ":update<CR>";
    options.silent = true;
  }
  {
    mode = "n";
    key = "<leader>W";
    action = ":wall<CR>";
    options.silent = true;
  }

  {
    mode = [
      "n"
      "v"
    ];
    key = "<Space>";
    action = "<Nop>";
    options.silent = true;
  }
  {
    mode = "n";
    key = "<Esc>";
    action = "<cmd>nohlsearch<CR>";
    options.desc = "Clear search highlight";
  }
  {
    mode = "t";
    key = "<Esc><Esc>";
    action = "<C-\\\\><C-n>";
    options.desc = "Exit terminal";
  }
  {
    mode = "n";
    key = "<C-h>";
    action = "<C-w><C-h>";
    options.desc = "Win left";
  }
  {
    mode = "n";
    key = "<C-l>";
    action = "<C-w><C-l>";
    options.desc = "Win right";
  }
  {
    mode = "n";
    key = "<C-j>";
    action.__raw = ''
      function()
        local neoscroll = require("neoscroll")
        local lines = math.max(1, math.floor(vim.api.nvim_win_get_height(0) * 0.25))
        neoscroll.scroll(lines, { move_cursor = true, duration = 150 })
      end
    '';
    options.desc = "Scroll down (1/4 screen)";
    options.silent = true;
  }
  {
    mode = "n";
    key = "<C-k>";
    action.__raw = ''
      function()
        local neoscroll = require("neoscroll")
        local lines = math.max(1, math.floor(vim.api.nvim_win_get_height(0) * 0.25))
        neoscroll.scroll(-lines, { move_cursor = true, duration = 150 })
      end
    '';
    options.desc = "Scroll up (1/4 screen)";
    options.silent = true;
  }
  {
    mode = "n";
    key = "<C-n>";
    action = "<cmd>Neotree toggle<CR>";
    options.desc = "Toggle file tree";
    options.silent = true;
  }
  #{ mode = "i"; key = "jk"; action = "<Esc>"; options.silent = true; }

  # Telescope binds
  {
    mode = "n";
    key = "<leader>sh";
    action.__raw = "require('telescope.builtin').help_tags";
    options.desc = "[S]earch [H]elp";
  }
  {
    mode = "n";
    key = "<leader>sk";
    action.__raw = "require('telescope.builtin').keymaps";
    options.desc = "[S]earch [K]eymaps";
  }
  {
    mode = "n";
    key = "<leader>sf";
    action.__raw = "require('telescope.builtin').find_files";
    options.desc = "[S]earch [F]iles";
  }
  {
    mode = "n";
    key = "<leader>ss";
    action.__raw = "require('telescope.builtin').builtin";
    options.desc = "[S]elect Telescope";
  }
  {
    mode = "n";
    key = "<leader>sw";
    action.__raw = "require('telescope.builtin').grep_string";
    options.desc = "[S]earch current [W]ord";
  }
  {
    mode = "n";
    key = "<leader>sg";
    action.__raw = ''
      function()
        _G.project_fuzzy_grep()
      end
    '';
    options.desc = "[S]earch by fuzzy [G]rep";
  }
  {
    mode = "n";
    key = "<leader>sd";
    action.__raw = "require('telescope.builtin').diagnostics";
    options.desc = "[S]earch [D]iagnostics";
  }
  {
    mode = "n";
    key = "<leader>sr";
    action.__raw = "require('telescope.builtin').resume";
    options.desc = "[S]earch [R]esume";
  }
  {
    mode = "n";
    key = "<leader>sR";
    action.__raw = "function() _G.project_replace() end";
    options.desc = "[S]earch and [R]eplace";
  }
  {
    mode = "x";
    key = "<leader>sR";
    action.__raw = "function() _G.project_replace_visual() end";
    options.desc = "[S]earch and [R]eplace";
  }
  {
    mode = "n";
    key = "<leader>s.";
    action.__raw = "require('telescope.builtin').oldfiles";
    options.desc = "Recent files";
  }
  {
    mode = "n";
    key = "<leader>/";
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
    mode = "n";
    key = "<leader>s/";
    action.__raw = ''
      function()
        require('telescope.builtin').live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
      end
    '';
    options.desc = "[S]earch [/] in open files";
  }
  {
    mode = "n";
    key = "<leader>f";
    action.__raw = ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
    options.desc = "[F]ormat buffer";
  }
  {
    mode = "n";
    key = "<leader>mp";
    action = "<cmd>MarkdownPreviewToggle<CR>";
    options.desc = "Preview Markdown";
    options.silent = true;
  }

  {
    mode = "n";
    key = "<leader>u";
    action = "<cmd>UndotreeToggle<CR>";
    options.desc = "Undo tree";
  }
  #{ mode = "n"; key = "<leader>u>"; action = "<cmd>Telescope undo<CR>"; options.desc = "Undo tree"; }

  # OpenCode assistant bindings
  {
    mode = [
      "n"
      "x"
    ];
    key = "<leader>oa";
    action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
    options.desc = "Ask about this";
  }
  {
    mode = [
      "n"
      "x"
    ];
    key = "<leader>os";
    action.__raw = ''function() require("opencode").select() end'';
    options.desc = "Select prompt";
  }
  {
    mode = [
      "n"
      "x"
    ];
    key = "<leader>o+";
    action.__raw = ''function() require("opencode").prompt("@this") end'';
    options.desc = "Add this";
  }
  {
    mode = "n";
    key = "<leader>ot";
    action.__raw = ''function() require("opencode").toggle() end'';
    options.desc = "Toggle embedded";
  }
  {
    mode = "n";
    key = "<leader>oc";
    action.__raw = ''function() require("opencode").command() end'';
    options.desc = "Select command";
  }
  {
    mode = "n";
    key = "<leader>on";
    action.__raw = ''function() require("opencode").command("session_new") end'';
    options.desc = "New session";
  }
  {
    mode = "n";
    key = "<leader>oi";
    action.__raw = ''function() require("opencode").command("session_interrupt") end'';
    options.desc = "Interrupt session";
  }
  {
    mode = "n";
    key = "<leader>oA";
    action.__raw = ''function() require("opencode").command("agent_cycle") end'';
    options.desc = "Cycle selected agent";
  }
  {
    mode = "n";
    key = "<S-C-u>";
    action.__raw = ''function() require("opencode").command("messages_half_page_up") end'';
    options.desc = "Messages half page up";
  }
  {
    mode = "n";
    key = "<S-C-d>";
    action.__raw = ''function() require("opencode").command("messages_half_page_down") end'';
    options.desc = "Messages half page down";
  }
]
