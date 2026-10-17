-- In-buffer markdown rendering (headings, code blocks, tables, checkboxes).
-- Loads only for markdown buffers: user specs default to lazy = false in
-- config/lazy.lua, so without `ft` this (plus all of mini.nvim, which it
-- used to depend on) loaded on every start. Icons come from mini.icons,
-- which LazyVim already ships — no need for the whole mini.nvim suite.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
