-- Check the configured lint table against Neovim's real filetype detection,
-- without loading plugins, the user's init, or any language servers.
local source = table.concat(vim.fn.readfile(arg[1]), "\n")
local table_source = assert(source:match("lint%.linters_by_ft%s*=%s*(%b{})"), "Missing lint table")
local linters = assert(loadstring("return " .. table_source))()

for _, extension in ipairs({ "js", "ts", "jsx", "tsx" }) do
  local filetype = assert(vim.filetype.match({ filename = "example." .. extension }))
  assert(
    vim.tbl_contains(linters[filetype] or {}, "eslint_d"),
    extension .. " detected as " .. filetype .. " must select eslint_d"
  )
end

for _, alias in ipairs({ "jsx", "tsx" }) do
  assert(vim.tbl_contains(linters[alias] or {}, "eslint_d"), "Missing compatibility alias: " .. alias)
end

print("Neovim JavaScript/TypeScript lint mappings passed")
