-- Run: nvim --headless -u NONE -i NONE -l tests/matlab_lsp.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:prepend(vim.fn.stdpath "data" .. "/lazy/nvim-lspconfig")
local nvchad = dofile(vim.fn.stdpath "data" .. "/lazy/NvChad/lua/nvchad/configs/lspconfig.lua")
package.loaded["nvchad.configs.lspconfig"] = {
  defaults = function()
    vim.lsp.config("*", { on_init = nvchad.on_init })
  end,
}
vim.lsp.enable = function() end
require "configs.lspconfig"

local config = vim.lsp.config.matlab_ls
local temp = vim.fn.tempname()
vim.fn.mkdir(temp .. "/project/.git", "p")
vim.fn.mkdir(temp .. "/project/src", "p")
vim.fn.mkdir(temp .. "/standalone", "p")
local function root_for(path)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, path)
  local root
  config.root_dir(buf, function(dir)
    root = dir
  end)
  vim.api.nvim_buf_delete(buf, { force = true })
  return root
end

local ok, err = pcall(function()
  assert(root_for(temp .. "/project/src/demo.m") == temp .. "/project", "Git project root lost")
  -- The test runner's temporary directory may itself be inside a Git workspace.
  local find_root = vim.fs.root
  vim.fs.root = function() return nil end
  local standalone_root = root_for(temp .. "/standalone/demo.m")
  vim.fs.root = find_root
  assert(
    standalone_root == temp .. "/standalone",
    "Standalone MATLAB file must not use the editor's working directory as its workspace"
  )
  vim.fs.root = function() return vim.uv.os_homedir() end
  local home_root = root_for(temp .. "/standalone/demo.m")
  vim.fs.root = find_root
  assert(home_root == temp .. "/standalone", "A home directory Git marker must not index all of ~")
  local tokens = { full = true, legend = { tokenTypes = { "function" }, tokenModifiers = {} } }
  local client = {
    server_capabilities = { semanticTokensProvider = tokens },
    supports_method = function() return true end,
  }
  config.on_init(client, {})
  assert(client.server_capabilities.semanticTokensProvider == tokens, "MATLAB semantic tokens disabled")
  for _, name in ipairs { "installPath", "matlabConnectionTiming", "indexWorkspace", "telemetry",
    "maxFileSizeForAnalysis", "signIn", "prewarmGraphics", "defaultEditor" } do
    assert(config.settings.MATLAB[name] ~= nil, "Missing server setting: " .. name)
  end
end)
vim.fn.delete(temp, "rf")
assert(ok, err)
print "MATLAB workspace root and semantic highlighting checks passed"
