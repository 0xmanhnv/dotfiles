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
