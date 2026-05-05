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
      -- Skip unmodifiable / readonly / unnamed buffers.
      -- Use vim.bo[buf] (modern API) instead of nvim_buf_get_option (deprecated 0.11+).
      if not vim.bo[buf].modifiable then return false end
      if vim.bo[buf].readonly then return false end
      if vim.api.nvim_buf_get_name(buf) == "" then return false end

      -- Skip oil / fugitive / pickers / other non-file buffers
      local skip_ft = { "oil", "fugitive", "TelescopePrompt", "snacks_picker_input" }
      for _, f in ipairs(skip_ft) do
        if vim.bo[buf].filetype == f then return false end
      end

      -- Per-buffer opt-out
      if vim.b[buf].disable_autosave then return false end
      return true
    end,
    -- Wait this long after last change before saving (debounce)
    debounce_delay = 1000,
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
