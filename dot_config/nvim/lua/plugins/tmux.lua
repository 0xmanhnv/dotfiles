-- Seamless <C-h/j/k/l> navigation between Neovim splits and tmux panes.
-- Pairs with the matching block in ~/.tmux.conf — see docs/nvim-tmux.md.
return {
  "christoomey/vim-tmux-navigator",
  lazy = false,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",     desc = "Go to left split/pane" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>",     desc = "Go to lower split/pane" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>",       desc = "Go to upper split/pane" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>",    desc = "Go to right split/pane" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to previous split/pane" },
  },
}
