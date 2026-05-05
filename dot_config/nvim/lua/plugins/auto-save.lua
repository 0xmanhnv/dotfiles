-- Auto-save: trigger BufWritePre when buffer changes / leaves insert mode.
-- Combined with conform's format_on_save → typing → leave insert → auto save
-- → auto format. Zero key-presses for formatting.
--
-- Disable per-buffer: :let b:disable_autosave = 1

return {
  "okuuva/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    -- Trigger events
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },         -- save now
      defer_save = { "InsertLeave", "TextChanged" },        -- debounced save
      cancel_deferred_save = { "InsertEnter" },             -- cancel if typing again
    },
    -- Conditions: skip auto-save in these cases
    condition = function(buf)
      -- Skip unmodifiable / readonly / unnamed buffers
      if not vim.api.nvim_buf_get_option(buf, "modifiable") then return false end
      if vim.api.nvim_buf_get_option(buf, "readonly") then return false end
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then return false end
      -- Skip oil / fugitive / other non-file buffers
      local ft = vim.api.nvim_buf_get_option(buf, "filetype")
      local skip_ft = { "oil", "fugitive", "TelescopePrompt", "snacks_picker_input" }
      for _, f in ipairs(skip_ft) do
        if ft == f then return false end
      end
      -- Per-buffer opt-out
      if vim.b[buf].disable_autosave then return false end
      return true
    end,
    -- Wait this long after last change before saving (debounce)
    debounce_delay = 1000,
    -- Don't print "saved" message for every save (too noisy)
    execution_message = {
      enabled = false,
    },
  },
  keys = {
    {
      "<leader>us",
      function()
        if vim.b.disable_autosave then
          vim.b.disable_autosave = false
          vim.notify("Auto-save: ON")
        else
          vim.b.disable_autosave = true
          vim.notify("Auto-save: OFF (this buffer)")
        end
      end,
      desc = "Toggle auto-save (buffer)",
    },
  },
}
