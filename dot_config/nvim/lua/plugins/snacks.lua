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
        },
      },
    },
  },
}
