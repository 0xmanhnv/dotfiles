return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "render-markdown.nvim/lua", words = { "render%.md" } },
    },
  },
}
