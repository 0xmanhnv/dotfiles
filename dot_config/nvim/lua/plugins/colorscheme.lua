-- Catppuccin, following the terminal's light/dark mode: Mocha on a dark
-- background, Latte on a light one — same pair as Ghostty, tmux, starship,
-- delta and bat. Neovim (0.10+) asks the terminal for its background color
-- at startup (OSC 11) and sets 'background'; flavour = "auto" maps that to
-- the matching flavour. The plugin spec itself ships with LazyVim (lazy,
-- with its integrations list); this only picks the flavours.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "auto",
      background = { light = "latte", dark = "mocha" },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },
}
