return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true, -- still hides node_modules, dist, etc.
        never_show = {
          ".DS_Store",
        },
      },
    },
  },
}
