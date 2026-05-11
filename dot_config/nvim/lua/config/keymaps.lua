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

-- Force <leader>e to always open the explorer at cwd root, fully
-- collapsed, no auto-reveal.
--
-- snacks.explorer:
--   1. uses a module-level Tree singleton — node.open survives pickers
--   2. State.new(picker) unconditionally calls Tree:open(buf_file)
--      (explorer.lua:47), re-expanding every ancestor of the focused
--      buffer on every open — there's no config flag to disable it
--
-- Pre-call close_all and deferred close_all both lose the race against
-- that Tree:open. The only reliable fix is to neuter Tree.open just
-- while the picker initializes, then restore it. Combined with a
-- close_all pass to wipe lingering expansion, the new picker renders
-- only direct children of cwd. pcall guards against API renames.
vim.keymap.set("n", "<leader>e", function()
  local ok_root, root = pcall(function() return LazyVim.root() end)
  local cwd = (ok_root and root) or vim.fn.getcwd()
  pcall(function()
    local Tree = require("snacks.explorer.tree")
    Tree:close_all(cwd)
    local orig_open = Tree.open
    Tree.open = function(_self, _path) end -- no-op during picker init
    Snacks.explorer({ cwd = cwd, follow_file = false })
    vim.schedule(function() Tree.open = orig_open end)
  end)
end, { desc = "Explorer (root, collapsed, no reveal)" })

-- Diagnostic → clipboard helpers. Lets you grab an LSP/linter error and
-- paste straight into a search bar / chat / commit message without
-- retyping. Uses `+` register (system clipboard), which the OSC 52
-- fallback in options.lua makes work over SSH too.
local diag_severity_name = {
  [vim.diagnostic.severity.ERROR] = "ERROR",
  [vim.diagnostic.severity.WARN]  = "WARN",
  [vim.diagnostic.severity.INFO]  = "INFO",
  [vim.diagnostic.severity.HINT]  = "HINT",
}

vim.keymap.set("n", "<leader>cy", function()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diags = vim.diagnostic.get(0, { lnum = lnum })
  if vim.tbl_isempty(diags) then
    vim.notify("No diagnostic on current line", vim.log.levels.WARN)
    return
  end
  local msgs = {}
  for _, d in ipairs(diags) do
    table.insert(msgs, d.message)
  end
  vim.fn.setreg("+", table.concat(msgs, "\n"))
  vim.notify(string.format("Copied %d diagnostic(s)", #diags))
end, { desc = "Copy line diagnostic(s) to clipboard" })

vim.keymap.set("n", "<leader>cY", function()
  local diags = vim.diagnostic.get(0)
  if vim.tbl_isempty(diags) then
    vim.notify("No diagnostics in buffer", vim.log.levels.WARN)
    return
  end
  table.sort(diags, function(a, b)
    if a.lnum ~= b.lnum then return a.lnum < b.lnum end
    return (a.col or 0) < (b.col or 0)
  end)
  local lines = {}
  for _, d in ipairs(diags) do
    local sev = diag_severity_name[d.severity] or "?"
    table.insert(lines, string.format("[%s] L%d: %s", sev, d.lnum + 1, d.message))
  end
  vim.fn.setreg("+", table.concat(lines, "\n"))
  vim.notify(string.format("Copied %d diagnostic(s) to clipboard", #diags))
end, { desc = "Copy all buffer diagnostics to clipboard" })
