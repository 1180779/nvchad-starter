-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "onedark",
  transparency = true,
  -- MATLAB-only colors, including LSP tokens that take priority over syntax.
  hl_add = {
    matlabFunctionCall = { fg = "blue", bold = true },
    matlabFunctionName = { fg = "blue", bold = true },
    matlabImplicit = { fg = "blue" },
    matlabFunction = { fg = "purple", bold = true },
    matlabSection = { fg = "green", bold = true },
    matlabComment = { fg = "green" },
    matlabMultilineComment = { fg = "green" },
    ["@comment.matlab"] = { fg = "green" },
    matlabConditional = { fg = "purple", bold = true },
    matlabRepeat = { fg = "purple", bold = true },
    matlabNumber = { fg = "yellow" },
    matlabFloat = { fg = "yellow" },
    matlabOperator = { fg = "cyan" },
    matlabAssignment = { fg = "cyan" },
    ["@lsp.type.function.matlab"] = { fg = "blue", bold = true },
    ["@lsp.type.variable.matlab"] = { fg = "white" },
  },

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }

-- Disable the buffer/tab bar at the top — use <leader><leader> (find files) to switch instead.
M.ui = {
  tabufline = {
    enabled = false,
  },
}

return M
