{ haveNerd }:
{
  globals = {
    mapleader = " ";
    have_nerd_font = haveNerd;
  };
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
    updatetime = 50; # 250
    timeoutlen = 300;
    splitright = true;
    splitbelow = true;
    #list = true;
    #listchars = "tab:» ,trail:·,nbsp:␣";
    inccommand = "split";
    cursorline = true;
    scrolloff = 5;
    confirm = true;
    termguicolors = true;
    expandtab = true;
    shiftwidth = 2;
    tabstop = 2;
    smartindent = true;
    viewoptions = "folds,cursor,curdir";
    lazyredraw = true;
    ttyfast = true;
  };

  # Autocmds
  autoCmd = [
    {
      event = [ "FileType" ];
      pattern = [ "markdown" ];
      desc = "Hard wrap Markdown while typing";
      callback.__raw = ''
        function()
          -- Insert real line breaks when typing past 'textwidth'.
          -- This is buffer-local so it doesn't affect other filetypes.
          vim.opt_local.textwidth = 80
          vim.opt_local.formatoptions:append({ "t" })
          vim.opt_local.formatoptions:remove({ "l" })
        end
      '';
    }

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
}
