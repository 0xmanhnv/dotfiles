-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
-- Disable netrw (built-in file explorer; snacks.explorer replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Disable optional language providers we don't use (silences :checkhealth
-- warnings about missing perl / Neovim::Ext / neovim-ruby-host / neovim pip).
-- Re-enable any of these (set to 1 or remove the line) if you ever write
-- nvim plugins/RPC clients in that language.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

-- 1. Enable internal diff with linematch
vim.opt.diffopt:append("linematch:60")
vim.opt.diffopt:append("algorithm:histogram")

-- 2. Override color diff (edit hex colorscheme for you)
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2d4f3e" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#5c2929", fg = "#ff6b6b" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2d3a5c" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#4a5a8a", bold = true })
  end,
})

-- When nvim is opened with a directory argument, cd into that directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg = vim.fn.argv(0) --[[@as string]]
    if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(arg))
    end
  end,
  desc = "Auto-cd into directory passed as argument",
})
