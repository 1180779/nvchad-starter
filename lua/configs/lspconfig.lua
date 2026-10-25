require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "texlab", "matlab_ls" }
vim.lsp.config("matlab_ls", {
  root_dir = function(bufnr, on_dir)
    -- Index the project, or this file's folder, even when Neovim starts in ~.
    local file = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(bufnr, ".git")
    if root == vim.uv.os_homedir() then
      root = nil
    end
    on_dir(root or vim.fs.dirname(file))
  end,
  -- NvChad's default on_init removes semantic tokens from every server.
  on_init = function() end,
  settings = {
    MATLAB = {
      installPath = require("matlab").root(),
      indexWorkspace = true,
      matlabConnectionTiming = "onStart",
      telemetry = false,
      -- v1.3.12 compares settings without guarding omitted optional values.
      maxFileSizeForAnalysis = 0,
      signIn = false,
      prewarmGraphics = false,
      defaultEditor = true,
    },
  },
})
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
