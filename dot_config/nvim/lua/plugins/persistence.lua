-- folke/persistence.nvim — per-project session save/restore.
--
-- Behavior:
--   * Auto-saves on VimLeavePre (plugin default, kicked off by setup()).
--   * Auto-restores on VimEnter when nvim is started with no file args
--     (`nvim` alone). With file args we open just the file, not the session.
--   * Sessions are keyed by cwd + git branch (one per cwd; branch = true
--     splits further so swapping branches doesn't trash the session).
return {
  "folke/persistence.nvim",
  lazy = false, -- needed so the VimEnter autocmd has the plugin available
  opts = {
    branch = true,
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
      nested = true, -- let BufEnter/FileType/etc. fire so LSP + treesitter attach
      callback = function()
        local argc = vim.fn.argc()
        -- Case 1: `nvim` with no args — restore session for current cwd
        if argc == 0 then
          require("persistence").load()
          return
        end
        -- Case 2: `nvim <dir>` — auto-cd autocmd in options.lua already
        -- changed cwd; restore session for that directory
        if argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
          require("persistence").load()
        end
        -- Case 3: `nvim file.lua` — open just the file, no session restore
      end,
    })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end,                desc = "Restore session (cwd)" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qS", function() require("persistence").select() end,              desc = "Select session" },
    { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't save this session" },
  },
}
