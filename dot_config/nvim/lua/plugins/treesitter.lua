-- Extend LazyVim's nvim-treesitter ensure_installed with parsers needed for
-- snacks.nvim image rendering (it requires the parser of the file's filetype
-- to know where image references live), plus common web-dev languages.

return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = opts.ensure_installed or {}
    vim.list_extend(opts.ensure_installed, {
      -- Web styling — also unlocks snacks.image scope detection
      "css",
      "scss",
      -- Web frameworks
      "vue",
      "svelte",
      -- Document / typesetting (snacks.image image rendering)
      "latex",
      "typst",
      "norg",
    })
  end,
}
