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

-- Column-limit ruler. Visual guide only (no textwidth auto-wrap; conform's
-- format-on-save handles the real reformat to each language's canonical
-- width). 100 columns is the modern polyglot default — matches rustfmt,
-- stylua (configured to 100 in plugins/conform.lua), Google Java style,
-- Kotlin style guide, and clang-format ColumnLimit:100 set in conform.
-- Per-filetype overrides handle the cases where the language ecosystem
-- has clearly converged on a different number.
vim.opt.colorcolumn = "100"

-- Match each filetype's ruler to what its formatter actually wraps to,
-- so the visual guide predicts what `:w` will reformat. Width sources:
-- rustfmt / google-java-format / Kotlin style → 100;
-- stylua / clang-format → 100 (explicitly set in plugins/conform.lua);
-- Black / Ruff → 88; prettier default → 80; gofmt → no limit;
-- commit-body convention → 72.
local ft_colorcolumn = {
  -- Python: Black / Ruff converge on 88
  python = "88",

  -- Prettier-formatted languages: default printWidth = 80. A project's
  -- .prettierrc still wins at format time; this just shows the canonical
  -- default visually.
  javascript = "80",
  javascriptreact = "80",
  typescript = "80",
  typescriptreact = "80",
  vue = "80",
  svelte = "80",
  astro = "80",
  json = "80",
  jsonc = "80",
  yaml = "80",
  css = "80",
  scss = "80",
  less = "80",
  html = "80",
  graphql = "80",

  -- Commit body convention (git log / GitHub UI wrap to this)
  gitcommit = "72",

  -- Prose / structured docs: no ruler — wrapping is editorial, not mechanical
  markdown = "",
  text = "",
  help = "",          -- vim's built-in help has its own layout
}

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("user_colorcolumn", { clear = true }),
  desc = "Per-filetype colorcolumn",
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    -- Use nil-aware lookup: missing FT falls back to global (100); explicit
    -- "" disables the ruler. BufWinEnter handles the case where the same
    -- window cycles between buffers of different filetypes.
    local cc = ft_colorcolumn[ft]
    vim.opt_local.colorcolumn = cc ~= nil and cc or "100"
  end,
})

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
