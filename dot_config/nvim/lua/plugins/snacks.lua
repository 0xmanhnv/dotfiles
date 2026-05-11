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
          -- Trim the sidebar from snacks's default 40 cols. Use a %-based
          -- width so the explorer scales with the monitor (MacBook 14"
          -- vs an external 27" both end up with a reasonable ratio).
          -- min_width 30 keeps the sidebar readable on small splits /
          -- narrow windows where 20% would shrink below useful.
          layout = {
            preset = "sidebar",
            layout = { width = 0.20, min_width = 30 },
          },
        },
      },
    },
  },
}
