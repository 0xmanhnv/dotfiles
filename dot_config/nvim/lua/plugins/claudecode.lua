-- Layered overrides on top of lazyvim.plugins.extras.ai.claudecode.
-- That extra already loads the plugin with default config and registers
-- the <leader>a "+ai" group label plus 8 ClaudeCode bindings:
--   <leader>ac Toggle | <leader>af Focus | <leader>ar Resume
--   <leader>aC Continue | <leader>ab Add buffer | <leader>as Send (v)
--   <leader>as TreeAdd (ft = NvimTree/neo-tree/oil) | <leader>aa Accept
--   <leader>ad Deny
--
-- lazy.nvim merges every spec for "coder/claudecode.nvim" into one. We
-- contribute ONLY what the extra is missing — duplicating the rest would
-- silently freeze us at today's cmd strings if LazyVim later improves any
-- of those 8 defaults (e.g. adds a new flag to ClaudeCode).
--
-- What we add:
--   1. opts.models — fresh labels (extra ships outdated 4.1 / 4.5 names).
--   2. <leader>am — Select Model (extra has no shortcut for it).
--   3. <leader>as TreeAdd in mini.files / netrw too (extra's ft list
--      stops at oil).
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },

  -- Lazy-loaded via keys (default behavior)

  ---@module "claudecode"
  ---@type PartialClaudeCodeConfig
  opts = {
    -- ===== Terminal: where Claude window opens and its size =====
    ---@diagnostic disable-next-line: missing-fields
    terminal = {
      -- Use snacks.nvim as the terminal provider (nicer UI, supports float)
      provider = "snacks",

      -- Position and size of the split on the right
      split_side = "right",
      split_width_percentage = 0.35, -- 35% of screen width, wide enough to read

      -- Auto-close behavior when Claude exits
      auto_close = false, -- keep window open to inspect errors if any

      -- Use snacks float window for a nicer UX (optional)
      -- Uncomment the block below to use a floating window instead of a split
      -- snacks_win_opts = {
      --     position = "float",
      --     width = 0.5,
      --     height = 0.9,
      --     border = "rounded",
      --     keys = {
      --         claude_hide = {
      --             "<C-,>",
      --             function(self) self:hide() end,
      --             mode = { "n", "t" },
      --             desc = "Hide Claude",
      --         },
      --     },
      -- },
    },
    -- ===== Diff view: open in a dedicated tab, no terminal sandwich =====
    -- Default behavior keeps the Claude terminal in the same tab while a
    -- diff is open, so the layout ends up [old | terminal | new] — the
    -- terminal column wedges between the two file panes and kills the
    -- side-by-side review. Punt the diff to its own tab and suppress the
    -- terminal there:
    --   open_in_new_tab           = true  → diff opens in a fresh tab
    --   hide_terminal_in_new_tab  = true  → no terminal vsplit in that tab
    -- Only takes effect together; the second is gated on the first
    -- (diff.lua:257-263). <C-Tab> back to the original tab to keep
    -- chatting with Claude.
    ---@diagnostic disable-next-line: missing-fields
    diff_opts = {
      open_in_new_tab = true,
      hide_terminal_in_new_tab = true,
    },
    models = {
      { name = "Claude Opus 4.7 (Latest)", value = "opus" },
      { name = "Claude Sonnet 4.6 (Latest)", value = "sonnet" },
      { name = "Opusplan: Claude Opus 4.7 (Latest) + Sonnet 4.6 (Latest)", value = "opusplan" },
      { name = "Claude Haiku 4.5 (Latest)", value = "haiku" },
    },
    -- ===== smart cwd resolution =====
    cwd_provider = function(ctx)
      -- Prefer git root of the current file, fallback to file's dir or Neovim cwd
      local cwd = require("claudecode.cwd").git_root(ctx.file_dir or ctx.cwd)
        or ctx.file_dir
        or ctx.cwd
      return cwd
    end,
  },
  keys = {
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
  },
}
