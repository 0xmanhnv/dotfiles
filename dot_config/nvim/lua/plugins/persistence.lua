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
        if vim.fn.argc() == 0 then
          require("persistence").load()
        end
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
