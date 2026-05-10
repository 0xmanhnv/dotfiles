-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Exit terminal mode with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Ctrl+A — select all (VSCode-style)
vim.keymap.set("n", "<C-a>", "ggVG",      { desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Select all" })

-- Page navigation: half-page jumps keep cursor centered (no scroll-lag),
-- full-page-down via <C-f>. <C-b> is tmux prefix so it doesn't reach Neovim
-- — use <PageUp> or <C-u> instead.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { desc = "Full page down (centered)" })

-- Physical PageDown/PageUp keys → half-page jump (centered). Works in
-- normal + visual modes; insert mode untouched so they don't break typing.
vim.keymap.set({ "n", "v" }, "<PageDown>", "<C-d>zz", { desc = "Half page down" })
vim.keymap.set({ "n", "v" }, "<PageUp>",   "<C-u>zz", { desc = "Half page up" })

-- Search results: keep centered + open folds (zv) so the match is visible
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })
