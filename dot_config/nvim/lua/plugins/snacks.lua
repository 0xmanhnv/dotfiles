return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true, -- show dotfiles (default is already true)
          ignored = false, -- hide gitignored files (default is false)
        },
      },
    },
  },
}
