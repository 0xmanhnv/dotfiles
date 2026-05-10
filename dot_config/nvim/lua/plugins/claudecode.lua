-- Extra keymaps on top of LazyVim's lazyvim.plugins.extras.ai.claudecode
-- (which loads the plugin with default config + the <leader>a group label).
-- lazy.nvim merges multiple specs for the same plugin, so we just add keys
-- here — no need to redeclare `dependencies = { "folke/snacks.nvim" }` or
-- `config = true`, and no `<leader>a` group entry (the extra owns that,
-- and registering it twice triggers a which-key duplicate warning).
return {
  "coder/claudecode.nvim",
  -- Override the plugin's hard-coded model labels (claudecode.nvim:config.lua
  -- still ships "Opus 4.1 / Sonnet 4.5"). The `value` aliases unchanged —
  -- Claude Code CLI resolves them to the actual latest at invocation time —
  -- so this only freshens the picker labels for ClaudeCodeSelectModel.
  opts = {
    models = {
      { name = "Claude Opus 4.7 (Latest)", value = "opus" },
      { name = "Claude Sonnet 4.6 (Latest)", value = "sonnet" },
      { name = "Opusplan: Claude Opus 4.7 (Latest) + Sonnet 4.6 (Latest)", value = "opusplan" },
      { name = "Claude Haiku 4.5 (Latest)", value = "haiku" },
    },
  },
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
}
