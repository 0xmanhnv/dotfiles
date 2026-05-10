-- Catppuccin Mocha — matches the palette already used by Ghostty
-- (theme = light:Catppuccin Latte,dark:Catppuccin Mocha) and Starship
-- (palette = catppuccin_mocha) for a consistent look across the stack.
--
-- `name = "catppuccin"` overrides lazy.nvim's default plugin dir name. The
-- repo is `catppuccin/nvim`, so lazy would clone it to `nvim/`, shadowing
-- `$VIMRUNTIME/lua/nvim`. Renaming avoids that collision.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte / frappe / macchiato / mocha
      transparent_background = false,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        notify = true,
        mason = true,
        which_key = true,
        telescope = { enabled = true },
        snacks = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
