local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    tex = { "latexindent" },
    plaintex = { "latexindent" },
    matlab = { "mh_style" },
    -- Add dedicated formatters here as you install them via :Mason
    -- Anything NOT listed here falls back to the LSP formatter (see below),
    -- which is the closest equivalent to IntelliJ's "ReformatCode".
    -- python = { "ruff_format" },
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
    -- typescript = { "prettierd", "prettier", stop_after_first = true },
    -- json = { "prettierd", "prettier", stop_after_first = true },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  formatters = {
    mh_style = {
      command = vim.fn.stdpath "config" .. "/scripts/matlab_format.py",
      args = { "--fix", "--tab_width", "2", "$FILENAME" },
      condition = function()
        return vim.fn.executable "mh_style" == 1
      end,
    },
  },

  -- For any filetype without a dedicated formatter above, use the active LSP.
  -- e.g. Java -> jdtls, so reformatting matches your language server's rules.
  default_format_opts = {
    lsp_format = "fallback",
  },

  -- No format_on_save: formatting happens only on keypress (<leader>f),
  -- mirroring IntelliJ's manual Ctrl+Alt+L behavior.
}

return options
