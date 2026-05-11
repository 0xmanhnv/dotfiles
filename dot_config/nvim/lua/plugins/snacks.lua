-- Buddha Bless dashboard header
local function get_header()
  return table.concat({
    "                   _oo0oo_                   ",
    "                  o8888888o                  ",
    '                  88" . "88                  ',
    "                  (| -_- |)                  ",
    "                  0\\  =  /0                  ",
    "                ___/`---'\\___                ",
    "              .' \\|     |// '.               ",
    "             / \\|||  :  |||// \\              ",
    "            / _||||| -:- |||||- \\            ",
    "           |   | \\  -  /// |   |             ",
    "           | \\_|  ''\\---/''  |_/ |           ",
    "           \\  .-\\__  '-'  ___/-. /           ",
    "         ___'. .'  /--.--\\  `. .'___         ",
    '      ."" \'<  `.___\\_<|>_/___.\' >\' "".       ',
    "     | | :  `- \\`.;`\\ _ /`;.`/ - ` : | |     ",
    "     \\  \\ `_.   \\_ __\\ /__ _/   .-` /  /     ",
    " =====`-.____`.___ \\_____/___.-`___.-'=====  ",
    "                   `=---='                   ",
    "                                             ",
    "    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    ",
    "    Buddha Bless: Critical Bugs Incoming     ",
    "    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    ",
  }, "\n")
end

return {
  "folke/snacks.nvim",
  opts = {
    -- LazyVim enables snacks.scroll by default (animated smooth scroll).
    -- It races with the `zz` suffix on our <C-d>/<C-u>/<C-f> keymaps:
    -- the animation hasn't finished moving the cursor when zz snaps it
    -- back to center, producing the "page-down then jumps back" feel
    -- when keys are pressed in quick succession. Disable smooth scroll
    -- and let the keymaps' instant <C-d>zz behavior win.
    scroll = { enabled = false },

    dashboard = {
      enabled = true,
      preset = {
        header = get_header(),
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
    },
    explorer = {
      enabled = true,
      replace_netrw = true,
    },

    picker = {
      enabled = true,
      sources = {
        explorer = {
          hidden = true,   -- show dotfiles
          ignored = false, -- hide gitignored files
          watch = true,    -- libuv fs_event watcher: auto-refresh when files change on disk
          auto_close = false,
          -- follow_file = true (snacks default): auto-reveal the active
          -- buffer, VS Code-style. The view scrolls to the open file's
          -- location but the root stays at cwd — scroll up to see the
          -- top-level project structure.
          --
          -- Industry-standard sidebar width. VS Code's Explorer panel sits
          -- around 0.20-0.25; neo-tree's fixed 40 cols also lands near 0.22
          -- on a typical MacBook display. 0.20 fits longer filenames
          -- (Java/TS spec files) comfortably while still scaling with the
          -- monitor. min_width 25 keeps it readable in narrow splits.
          layout = {
            preset = "sidebar",
            layout = { width = 0.20, min_width = 25 },
          },
        },
      },
    },
  },
}
