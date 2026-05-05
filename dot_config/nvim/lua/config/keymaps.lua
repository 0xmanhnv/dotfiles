-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Ctrl+A — select all (VSCode-style)
vim.keymap.set("n", "<C-a>", "ggVG",      { desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Select all" })
