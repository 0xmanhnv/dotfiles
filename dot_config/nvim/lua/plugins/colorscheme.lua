-- Tokyonight Moon variant. Tokyonight ships with LazyVim by default; this
-- spec just selects the moon style and sets it as the active colorscheme.
-- Other variants: storm (LazyVim default), night, day.
return {
  {
    "folke/tokyonight.nvim",
    opts = { style = "moon" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-moon" },
  },
}
