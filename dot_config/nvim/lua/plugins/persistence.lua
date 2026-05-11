-- folke/persistence.nvim — per-project session save/restore.
--
-- Behavior:
--   * Auto-saves on VimLeavePre (plugin default, kicked off by setup()).
--   * Auto-restores on VimEnter when nvim is started with no file args
--     (`nvim` alone). With file args we open just the file, not the session.
--   * Sessions are keyed by cwd + git branch (one per cwd; branch = true
--     splits further so swapping branches doesn't trash the session).
return {
  "folke/persistence.nvim",
  lazy = false, -- needed so the VimEnter autocmd has the plugin available
  opts = function()
    -- Extend Neovim's default sessionoptions with `localoptions` so
    -- per-buffer settings (filetype, shiftwidth, …) survive the round
    -- trip. Without this, mksession drops local options and restored
    -- buffers come back with filetype="", which is why treesitter / LSP
    -- never attach. Captured at spec-eval time, after LazyVim's
    -- options.lua has populated sessionoptions.
    local options = vim.opt.sessionoptions:get()
    if not vim.tbl_contains(options, "localoptions") then
      table.insert(options, "localoptions")
    end
    return {
      branch = true,
      options = options,
    }
  end,
  init = function()
    local group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true })

    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true, -- let BufEnter/FileType/etc. fire so LSP + treesitter attach
      callback = function()
        local argc = vim.fn.argc()
        -- Case 1: `nvim` with no args — restore session for current cwd
        if argc == 0 then
          require("persistence").load()
          return
        end
        -- Case 2: `nvim <dir>` — auto-cd autocmd in options.lua already
        -- changed cwd; restore session for that directory
        if argc == 1 then
          local arg = vim.fn.argv(0) --[[@as string]]
          if vim.fn.isdirectory(arg) == 1 then
            require("persistence").load()
          end
        end
        -- Case 3: `nvim file.lua` — open just the file, no session restore
      end,
    })

    -- After a session is restored, open the file tree and force-trigger
    -- FileType detection on every restored buffer. mksession reloads the
    -- buffers but FileType autocmds don't fire reliably for buffers
    -- created by :badd/:edit during session sourcing — treesitter, LSP,
    -- and other plugins that key off FileType then never attach. Walking
    -- the buffer list and running `filetype detect` in each buffer's
    -- context re-fires those autocmds. vim.schedule defers the work past
    -- persistence's own window-wiring so we don't race.
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "PersistenceLoadPost",
      callback = function()
        vim.schedule(function()
          -- Open the file tree. Neo-tree isn't always installed (this
          -- config uses snacks.explorer instead); try Neotree, fall
          -- back to Snacks.explorer, no-op if neither is available.
          -- pcall wraps an anonymous fn because lua-ls types vim.cmd
          -- as table|callable and refuses to accept it as `fun(...)`.
          -- rawget hides the Snacks global lookup from the "undefined
          -- field" check (no type def for the Snacks global exists).
          if vim.fn.exists(":Neotree") == 2 then
            pcall(function() vim.cmd("Neotree show") end)
          else
            local snacks = rawget(_G, "Snacks")
            if snacks and snacks.explorer then
              pcall(snacks.explorer)
            end
          end
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" and vim.fn.filereadable(name) == 1 then
                vim.api.nvim_buf_call(buf, function()
                  vim.cmd("filetype detect")
                end)
              end
            end
          end
        end)
      end,
    })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end,                desc = "Restore session (cwd)" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>qS", function() require("persistence").select() end,              desc = "Select session" },
    { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't save this session" },
  },
}
