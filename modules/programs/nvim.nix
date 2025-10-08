{
  config,
  pkgs,
  lib,
  features,
  ...
}: let
  cfg = features;
  haveNerd = cfg.fonts or false;
in {
  imports = lib.optionals (cfg.nixvim or false) [./vim-shared.nix];

  config = lib.mkIf (cfg.nixvim or false) {
    home.packages = with pkgs; [
      terraform # Formatter (and CLI)
      terraform-ls
      tflint
      docker-language-server
      hadolint # Dockerfile linter
      dockfmt
      yamllint
      jq
      nodePackages.prettier
      shfmt
      stylua
      black
      ruff
    ];

    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      #enableLuaLoader = true;

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
          event = ["TextYankPost"];
          desc = "Highlight when yanking text";
          #group = "highlight-yank";
          callback.__raw = "function() vim.hl.on_yank() end";
        }

        {
          event = ["BufReadPost"];
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
          options = {desc = "LSP Rename";};
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
          mode = ["n" "v"];
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
              neoscroll.scroll(lines, true, 150)
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
              neoscroll.scroll(-lines, true, 150)
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
          action.__raw = "require('telescope.builtin').live_grep";
          options.desc = "[S]earch by [G]rep";
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
              "bash"
              "c"
              "cpp"
              "lua"
              "python"
              "rust"
              "go"
              "javascript"
              "typescript"
              "tsx"
              "json"
              "yaml"
              "toml"
              "nix"
              "markdown"
              "regex"
              "diff"
              "vim"
              "vimdoc"
              "luadoc"
              "markdown_inline"
              "query"

              "hcl"
              "terraform"
              "dockerfile"
            ];
            highlight.enable = true;
            highlight.additional_vim_regex_highlighting = ["ruby"];
            indent.enable = true;
            indent.disable = ["ruby"];
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
          closeIfLastWindow = true;
          filesystem = {
            bindToCwd = false;
            followCurrentFile = {
              enabled = true;
            };
            useLibuvFileWatcher = true;
          };
          window = {
            width = 32;
            mappings = {
              "<space>" = "none";
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
              default = ["lsp" "path" "snippets"];
            };
            fuzzy.implementation = "lua";

            keymap = {
              "<S-CR>" = ["accept"];
              "<S-Tab>" = ["select_next"];
              #"<S-Tab>" = [ "select_prev" ];
            };
          };
        };

        # LSP (utan Mason)
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            lua_ls = {
              enable = true;
              settings.Lua.completion.callSnippet = "Replace";
            };
            bashls.enable = true;
            pyright.enable = true;
            ts_ls.enable = true; # om din Nixvim-version kräver tsserver: byt till tsserver
            rust_analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
            };
            gopls.enable = true;
            jsonls.enable = true;

            terraformls.enable = true;

            yamlls = {
              enable = true;

              # Azure DevOps Pipelines via YAML-LS + SchemaStore
              settings = {
                redhat.telemetry.enabled = false;
                yaml = {
                  validate = true;
                  hover = true;
                  completion = true;
                  format.enable = true;
                  schemaStore = {
                    enable = true;
                    url = "https://www.schemastore.org/api/json/catalog.json";
                  };
                  # Point specifically at the Azure Pipelines schema
                  schemas = {
                    "https://json.schemastore.org/azure-pipelines.json" = [
                      "azure-pipelines.yml"
                      "azure-pipelines.yaml"
                      "azure-pipelines/*.yml"
                      "azure-pipelines/*.yaml"
                      ".azure-pipelines/*.yml"
                      ".azure-pipelines/*.yaml"
                      "**/azure-pipelines*.y?(a)ml"
                    ];
                  };
                };
              };

              # Don't attach to docker-compose files
              extraOptions.on_attach.__raw = ''
                function(client, bufnr)
                  local name = vim.api.nvim_buf_get_name(bufnr)
                  if name:match("docker%-compose%.ya?ml$") or name:match("compose%.ya?ml$") then
                    client.stop()
                  end
                end
              '';
            };

            docker_compose_language_service.enable = lib.mkForce false;
            dockerls = {
              enable = true;

              filetypes = ["dockerfile" "json" "hcl"];
              rootMarkers = [
                "compose.yaml"
                "compose.yml"
                "docker-compose.yaml"
                "docker-compose.yml"
                "docker-bake.hcl"
                "docker-bake.json"
                "Dockerfile"
                ".git"
              ];
              extraOptions.on_attach.__raw = ''
                function(client, bufnr)
                  local ft = vim.bo[bufnr].filetype
                  if ft == "json" or ft == "hcl" then
                    local name = vim.api.nvim_buf_get_name(bufnr)
                    if not name:match("docker%-bake%.json$") and not name:match("docker%-bake%.hcl$") then
                      client.stop()
                    end
                  end
                end
              '';
            };
          }; # END servers
        }; # END lsp

        # formatter
        conform-nvim = {
          enable = true;
          settings = {
            notify_on_error = false;
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 500;
            };
            formatters_by_ft = {
              nix = ["alejandra"]; # alt: nixpkgs.nixfmt
              lua = ["stylua"];
              terraform = ["terraform_fmt"];
              dockerfile = ["dockfmt"];
              python = ["black" "ruff"];
              json = ["prettierd" "prettier"];
              jsonc = ["prettierd" "prettier"];
              javascript = ["prettierd" "prettier"];
              javascriptreact = ["prettierd" "prettier"];
              typescript = ["prettierd" "prettier"];
              typescriptreact = ["prettierd" "prettier"];
              html = ["prettierd" "prettier"];
              css = ["prettierd" "prettier"];
              scss = ["prettierd" "prettier"];
              less = ["prettierd" "prettier"];
              yaml = ["prettierd" "prettier"];
              markdown = ["prettierd" "prettier"];
              sh = ["shfmt"];
              bash = ["shfmt"];
              zsh = ["shfmt"];
            };
            formatters = {
              shfmt.prepend_args = ["-i" "2" "-ci"];
            };
          };
        };

        guess-indent.enable = true;
        todo-comments.enable = true;

        mini = {
          enable = true;
          modules = {
            ai = {enable = true;};
            #bufremove = { enable = true; };
            #comment = { enable = true; };
            #cursorword = { enable = true; };
            #indentscope = {enable = true;};
            #move = { enable = true; };
            #pairs = { enable = true; };
            #sessions = { enable = true; };
            #splitjoin = { enable = true; };
            surround = {enable = true;};
            #tabline = { enable = true; };
            #trailspace = { enable = true; };
            statusline = {enable = true;};
          };
        };

        hlchunk = {
          enable = true;
          settings = {
            blank = {
              enable = false;
              chars = [" "];
              style = [
                {bg = "#434437";}
                {bg = "#2f4440";}
                {bg = "#433054";}
                {bg = "#284251";}
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
              chars = ["│"];
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
          enable = true;
          settings = {
            #hide_target_hack = true;
            #delay_animation_start = 10;
            min_jump = 3;
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
              color = ["Normal" "#ffffff"];
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
            exclude = []; # exclude these filetypes
          };
        };
      }; # END plugins

      extraPlugins = with pkgs.vimPlugins; [
        #vimplugin-telescope-undo-nvim
        markdown-preview-nvim
        vim-nix
      ];

      extraConfigVim = "source ${config.xdg.configHome}/vim/shared-maps.vim";

      # nvim-lint-mappning + auto-run
      extraConfigLua = ''
        -- Markdown preview plugin defaults
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_auto_close = 1
        vim.g.mkdp_filetypes = { "markdown" }

        -- Diagnostics --
        vim.diagnostic.config({
          virtual_text = { spacing = 2, prefix = "●" },
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
          float = { border = "rounded", source = "if_many" },
        })

        local opts = { noremap=true, silent=true }
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
        vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
        -- END Diagnostics --


        local lint = require("lint")
        lint.linters_by_ft = {
          javascript = { "eslint_d" },
          typescript = { "eslint_d" },
          tsx        = { "eslint_d" },
          jsx        = { "eslint_d" },
          lua        = { "luacheck" },
          python     = { "flake8", "ruff", "mypy" },
          nix        = { "statix", "deadnix" },
          sh         = { "shellcheck" },
          bash       = { "shellcheck" },
          zsh        = { "shellcheck" },
          go         = { "golangci_lint" },
          markdown   = { "markdownlint" },
          dockerfile = { "hadolint" },
          yaml       = { "yamllint" },
        }


        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
          callback = function() require("lint").try_lint() end,
        })

        vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
        --require("telescope").load_extension("undo")

        local ls = require("luasnip")
        vim.keymap.set({"i","s"}, "<C-j>", function() if ls.expand_or_jumpable() then ls.expand_or_jump() end end, {silent=true})
        vim.keymap.set({"i","s"}, "<C-k>", function() if ls.jumpable(-1) then ls.jump(-1) end end, {silent=true})

        vim.filetype.add({
          extension = {
            tf = "terraform",
            tfvars = "terraform",  -- Some use  "terraform-vars", terraformls can handle either
            hcl = "hcl",
            MD = "markdown",
          },
        })
        vim.filetype.add({
          filename = { ["Dockerfile"] = "dockerfile" },
          pattern  = { ["Dockerfile%..*"] = "dockerfile" },
        })
      ''; # END extraConfigLua
    };
  };
}
