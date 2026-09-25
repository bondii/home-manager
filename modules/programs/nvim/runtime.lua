local telescope_conf = require("telescope.config").values
local telescope_finders = require("telescope.finders")
local telescope_make_entry = require("telescope.make_entry")
local telescope_pickers = require("telescope.pickers")

function _G.project_fuzzy_grep()
  local cwd = vim.uv.cwd()
  telescope_pickers.new({}, {
    prompt_title = "Project Fuzzy Grep",
    finder = telescope_finders.new_oneshot_job({
      "rg",
      "--vimgrep",
      "--hidden",
      "--glob",
      "!.git",
      "--no-messages",
      "--color=never",
      "^.",
    }, {
      cwd = cwd,
      entry_maker = telescope_make_entry.gen_from_vimgrep({}),
    }),
    previewer = telescope_conf.grep_previewer({}),
    sorter = telescope_conf.generic_sorter({}),
  }):find()
end

local function project_root()
  local root = vim.fs.root(0, { ".git" })
  if root and root ~= "" then
    return root
  end

  return vim.uv.cwd()
end

function _G.project_replace()
  require("grug-far").open({
    prefills = {
      paths = project_root(),
    },
  })
end

function _G.project_replace_visual()
  require("grug-far").with_visual_selection({
    prefills = {
      paths = project_root(),
    },
  })
end

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

-- LSP floats: add a clear border and background for hover/signature
vim.lsp.handlers["textDocument/hover"] = vim.lsp.buf.hover
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.buf.signature_help
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1f1f1f" })
vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#6b6b6b", bg = "#1f1f1f" })

local opts = { noremap=true, silent=true }
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
-- END Diagnostics --


local lint = require("lint")

local function python_linters()
  local linters = { "ruff" }
  local venv = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX

  if venv and venv ~= "" then
    local bin_dir = venv .. "/bin"
    if vim.fn.executable(bin_dir .. "/flake8") == 1 then
      table.insert(linters, "flake8")
    end
    if vim.fn.executable(bin_dir .. "/mypy") == 1 then
      table.insert(linters, "mypy")
    end
  end

  return linters
end

local function try_lint_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype == "python" then
    lint.try_lint(python_linters())
  else
    lint.try_lint()
  end
end

lint.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  tsx        = { "eslint_d" },
  jsx        = { "eslint_d" },
  lua        = { "luacheck" },
  python     = { },
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
  callback = try_lint_current_buffer,
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

vim.o.autoread = true  -- Required for OpenCode?
