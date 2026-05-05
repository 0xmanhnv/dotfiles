-- conform.nvim — formatter dispatch + format-on-save.
-- Comprehensive setup covering daily-driver languages for polyglot dev.
-- Mason auto-installs the formatter binaries; conform routes per filetype.

return {
  -- ---------------------------------------------------------------------------
  -- conform.nvim
  -- ---------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer / range",
      },
      {
        "<leader>uf",
        function()
          if vim.b.disable_autoformat or vim.g.disable_autoformat then
            vim.b.disable_autoformat = false
            vim.g.disable_autoformat = false
            vim.notify("Format-on-save: ON")
          else
            vim.b.disable_autoformat = true
            vim.notify("Format-on-save: OFF (this buffer only)")
          end
        end,
        desc = "Toggle format-on-save (buffer)",
      },
      {
        "<leader>uF",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format-on-save: " .. (vim.g.disable_autoformat and "OFF (global)" or "ON"))
        end,
        desc = "Toggle format-on-save (global)",
      },
    },
    opts = {
      -- Per-filetype formatter chains. `stop_after_first = true` runs the
      -- first available; otherwise all listed run in order.
      formatters_by_ft = {
        -- Shell / scripting
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },

        -- Python (ruff is fast + handles both format and import sort)
        python = { "ruff_format", "ruff_organize_imports" },

        -- JS / TS / web
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        vue = { "prettierd", "prettier", stop_after_first = true },
        svelte = { "prettierd", "prettier", stop_after_first = true },
        astro = { "prettierd", "prettier", stop_after_first = true },

        -- Data / config
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        toml = { "taplo" },
        xml = { "xmlformatter" },

        -- Markup / docs
        markdown = { "prettierd", "prettier", stop_after_first = true },
        ["markdown.mdx"] = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },
        less = { "prettierd", "prettier", stop_after_first = true },
        graphql = { "prettierd", "prettier", stop_after_first = true },

        -- Systems / compiled
        c = { "clang-format" },
        cpp = { "clang-format" },
        objc = { "clang-format" },
        cuda = { "clang-format" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        zig = { "zigfmt" },

        -- JVM
        java = { "google-java-format" },
        kotlin = { "ktlint" },
        scala = { "scalafmt" },
        groovy = { "npm-groovy-lint" },

        -- Other dev languages
        ruby = { "rubocop", "rufo", stop_after_first = true },
        php = { "php_cs_fixer" },
        sql = { "sqlfluff" },
        nix = { "alejandra" },
        elixir = { "mix" },
        haskell = { "fourmolu", "ormolu", stop_after_first = true },
        ocaml = { "ocamlformat" },
        proto = { "buf" },

        -- Infra / DevOps / SecOps
        terraform = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
        dockerfile = {},  -- no canonical formatter; use hadolint as linter elsewhere
        solidity = { "forge_fmt" },

        -- Catch-all: trim trailing whitespace + final newlines for any filetype
        ["_"] = { "trim_whitespace", "trim_newlines" },
      },

      -- Format-on-save with safety guards.
      format_on_save = function(bufnr)
        -- Per-buffer or global opt-out (toggle with <leader>uf / <leader>uF)
        if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
          return
        end
        -- Skip files larger than 1 MB (avoid blocking on big logs / dumps)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname ~= "" then
          local stat = (vim.uv or vim.loop).fs_stat(fname)
          if stat and stat.size > 1024 * 1024 then
            return
          end
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,

      -- Per-formatter argument overrides
      formatters = {
        shfmt = {
          -- -i 2: 2-space indent
          -- -bn:  binary ops at start of line (if/while readability)
          -- -ci:  indent switch cases
          -- -sr:  redirect operators followed by space
          prepend_args = { "-i", "2", "-bn", "-ci", "-sr" },
        },
        stylua = {
          prepend_args = {
            "--column-width", "100",
            "--indent-type", "Spaces",
            "--indent-width", "2",
            "--quote-style", "AutoPreferDouble",
          },
        },
        ["clang-format"] = {
          prepend_args = { "--style={IndentWidth: 2, ColumnLimit: 100}" },
        },
        injected = { options = { ignore_errors = true } },
      },

      notify_on_error = true,
    },

    init = function()
      -- Wire conform into vim's `gq` motion (format selection in normal mode)
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },

  -- ---------------------------------------------------------------------------
  -- mason: ensure formatter binaries are installed alongside LSPs
  -- ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Shell / scripting
        "stylua",
        "shfmt",

        -- Python
        "ruff",

        -- JS / TS / web (prettierd is the daemon variant, much faster)
        "prettier",
        "prettierd",

        -- Systems
        "clang-format",
        "goimports",
        "taplo",

        -- JVM
        "google-java-format",
        "ktlint",

        -- Other
        "rubocop",
        "php-cs-fixer",
        "sqlfluff",
        "alejandra",
        "buf",
        "yamlfmt",
        "xmlformatter",
      })
    end,
  },
}
