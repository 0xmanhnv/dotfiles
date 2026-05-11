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

-- LazyVim project-root detection. Default { "lsp", { ".git", "lua" }, "cwd" }
-- mis-detects the root in two ways for this workflow:
--   1. lua-ls reports its workspace as `dot_config/nvim/` (the nvim config
--      dir, not the dotfiles repo). LSP is queried first, so LazyVim.root()
--      ends up at the subfolder.
--   2. The "lua" pattern matches any dir containing a `lua/` subdir, which
--      hits `dot_config/nvim/` even without LSP.
--
-- Use only "cwd": match VS Code's "workspace = the folder you opened"
-- semantics. `nvim ~/Data/Me/dotfiles` -> cwd = dotfiles -> explorer rooted
-- there regardless of which buffer is focused or what LSP says.
vim.g.root_spec = { "cwd" }

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

-- Clipboard: `y` yanks into the OS clipboard so paste into terminals,
-- Claude Code, browsers, etc. just works. LazyVim already sets this;
-- restating for explicitness.
vim.opt.clipboard = "unnamedplus"

-- When SSH'd into a remote, pbcopy/xclip on the *local* machine aren't
-- reachable from the remote Neovim. Switch the clipboard provider to
-- OSC 52 (built-in since Neovim 0.10) — it writes via terminal escape
-- sequences which Ghostty intercepts and writes into the host clipboard.
-- Requires tmux `set -g set-clipboard on` (already configured) so the
-- sequence propagates out of nested tmux.
if vim.env.SSH_TTY ~= nil then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy  = { ["+"] = osc52.copy("+"),  ["*"] = osc52.copy("*") },
    paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
  }
end
