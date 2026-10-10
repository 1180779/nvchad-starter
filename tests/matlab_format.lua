-- Run: nvim -n --headless -u NONE -i NONE -l tests/matlab_format.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:prepend(vim.fn.stdpath "data" .. "/lazy/conform.nvim")
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin:" .. vim.env.PATH
local conform = require "conform"
conform.setup(require "configs.conform")
local path = vim.fn.tempname() .. ".m"
vim.fn.writefile({ "% original disk contents" }, path)
vim.api.nvim_buf_set_name(0, path)
vim.bo.filetype = "matlab"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "if true", "x=[1,2,3];", "end" })
assert(conform.get_formatter_info("mh_style").available, "Install :MasonInstall miss_hit first")
local format_error
conform.format({ async = false, timeout_ms = 5000 }, function(err)
  format_error = err
end)
assert(not format_error, format_error)
local formatted = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
assert(formatted:find("    x = [1, 2, 3];", 1, true), formatted)
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "function [] = sep()",
  "persistent separator",
  "",
  "if isempty(separator)",
  "  separator = string(strcat(repmat('-', 1, 20), \"\\n\"));",
  "end",
  "fprintf(separator)",
  "end",
})
conform.format({ async = false, timeout_ms = 5000 }, function(err)
  format_error = err
end)
assert(not format_error, format_error)
local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(lines[2] == "    persistent separator", table.concat(lines, "\n"))
assert(lines[4] == "    if isempty(separator)", table.concat(lines, "\n"))
assert(lines[5]:match "^        separator =", table.concat(lines, "\n"))
assert(lines[6] == "    end", table.concat(lines, "\n"))
assert(lines[7] == "    fprintf(separator);", table.concat(lines, "\n"))
assert(lines[8] == "end", table.concat(lines, "\n"))
assert(vim.fn.readfile(path)[1] == "% original disk contents", "Formatter modified the saved file")
vim.fn.delete(path)
print "Real MATLAB formatter spacing, indentation, and unsaved-buffer checks passed"
vim.cmd "qa!"
