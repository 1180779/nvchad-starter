require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "texlab" }
vim.lsp.enable(servers)

-- texlab: VimTeX already drives latexmk compilation and forward search, so turn
-- off everything texlab would otherwise do that duplicates it or adds latency.
vim.lsp.config("texlab", {
  settings = {
    texlab = {
      build = {
        onSave = false,        -- VimTeX/latexmk owns compilation
        forwardSearchAfter = false,
      },
      -- chktex shells out on every edit/save; biggest source of lag. Off = snappy.
      chktex = {
        onOpenAndSave = false,
        onEdit = false,
      },
      diagnosticsDelay = 300,  -- debounce diagnostics (ms)
    },
  },
})

-- read :h vim.lsp.config for changing options of lsp servers 
