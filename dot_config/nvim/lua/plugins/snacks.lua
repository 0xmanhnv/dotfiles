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
          -- Trim the sidebar so explorer + Claude split + editor all fit
          -- on a MacBook display (~180 cols): explorer 0.15 + Claude 0.25
          -- + editor 0.60 = 27 + 45 + 108 cols. The editor side just
          -- clears the 100-col ruler. min_width 25 keeps filenames legible
          -- when 15% of a narrow split would shrink the panel below useful.
          -- On a wide external monitor, 15% still scales up naturally.
          layout = {
            preset = "sidebar",
            layout = { width = 0.15, min_width = 25 },
          },
        },
      },
    },
  },
}
