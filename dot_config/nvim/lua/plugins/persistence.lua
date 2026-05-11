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

    -- Filetypes / buftypes that should NEVER end up in a saved session.
    -- Pickers, file trees, dashboards, plugin UIs, terminals, help/qf
    -- splits, scratch buffers — wiping them in pre_save keeps the
    -- session file clean and avoids weird [No Name] ghosts on restore.
    local bad_filetypes = {
      ["neo-tree"] = true,
      ["neo-tree-popup"] = true,
      ["snacks_dashboard"] = true,
      ["snacks_picker"] = true,
      ["snacks_picker_input"] = true,
      ["snacks_picker_list"] = true,
      ["snacks_picker_preview"] = true,
      ["snacks_explorer"] = true,
      ["snacks_terminal"] = true,
      ["snacks_notif"] = true,
      ["TelescopePrompt"] = true,
      ["TelescopeResults"] = true,
      ["lazy"] = true,
      ["mason"] = true,
      ["noice"] = true,
      ["alpha"] = true,
      ["dashboard"] = true,
      ["help"] = true,
      ["qf"] = true,
      ["trouble"] = true,
      ["lspinfo"] = true,
      ["checkhealth"] = true,
    }
    local bad_buftypes = {
      terminal = true,
      nofile = true,
      help = true,
      quickfix = true,
      prompt = true,
    }

    return {
      branch = true,
      options = options,
      pre_save = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            local ft = vim.bo[buf].filetype
            local bt = vim.bo[buf].buftype
            local junk = name == ""
              or (name ~= "" and vim.fn.isdirectory(name) == 1)
              or bad_buftypes[bt] == true
              or bad_filetypes[ft] == true
            if junk then
              pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
          end
        end
      end,
    }
  end,
  init = function()
    local group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true })

    -- Wipe loaded buffers that are either nameless or point at a directory.
    -- The startup splash buffer that nvim creates with no args is nameless;
    -- `nvim <dir>` creates a directory-named buffer. If we let mksession's
    -- restore script run with either of those still alive, they hang
    -- around in the bufferline. Strip them before load() takes over.
    local function wipe_unwanted_buffers()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local name = vim.api.nvim_buf_get_name(buf)
          if name == "" or vim.fn.isdirectory(name) == 1 then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end
        end
      end
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      group = group,
      nested = true, -- let BufEnter/FileType/etc. fire so LSP + treesitter attach
      callback = function()
        local argc = vim.fn.argc()
        -- Case 1: `nvim` with no args — restore session for current cwd
        if argc == 0 then
          wipe_unwanted_buffers()
          require("persistence").load()
          return
        end
        -- Case 2: `nvim <dir>` — auto-cd autocmd in options.lua already
        -- changed cwd; restore session for that directory
        if argc == 1 then
          local arg = vim.fn.argv(0) --[[@as string]]
          if vim.fn.isdirectory(arg) == 1 then
            wipe_unwanted_buffers()
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
        -- 100ms gives persistence time to finish wiring windows /
        -- buffers before we re-detect filetypes and open the tree.
        vim.defer_fn(function()
          -- pre_save filters the save, but [No Name] and directory
          -- buffers still slip through on restore — mksession recreates
          -- the cwd entry from `nvim <dir>` as a directory buffer, and
          -- the very first window often lands on a fresh [No Name]
          -- before persistence wires it. Wipe both unconditionally
          -- before doing anything else so filetype detect and Neotree
          -- don't act on them.
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              local name = vim.api.nvim_buf_get_name(buf)
              if name == "" or vim.fn.isdirectory(name) == 1 then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
              end
            end
          end
          -- Re-fire FileType in each restored buffer so treesitter / LSP
          -- attach (mksession + :badd don't fire FileType reliably).
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
          -- Try to open neo-tree; if it's not loaded yet (cmd=
          -- lazy-loaded specs register the command late), retry once
          -- after another 200ms. pcall wraps an anonymous fn so lua-ls
          -- doesn't trip on vim.cmd's union type.
          local ok = pcall(function() vim.cmd("Neotree show") end)
          if not ok then
            vim.defer_fn(function()
              pcall(function() vim.cmd("Neotree show") end)
            end, 200)
          end
        end, 100)
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
