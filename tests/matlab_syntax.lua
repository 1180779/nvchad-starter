-- Run: nvim -n --headless -u NONE -i NONE -l tests/matlab_syntax.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.getcwd() .. "/after")
vim.cmd "syntax on"
vim.bo.filetype = "matlab"
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "%% Compute results",
  "function result = compute(x)",
  "result = helper(x) + 42;",
  "label = 'helper(x)'; % helper(x)",
})
local function group(row, col)
  return vim.fn.synIDattr(vim.fn.synID(row, col, 1), "name")
end
assert(group(1, 4) == "matlabSection", group(1, 4))
assert(group(2, 19) == "matlabFunctionName", group(2, 19))
assert(group(3, 10) == "matlabFunctionCall", group(3, 10))
assert(group(4, 12) == "matlabString", "Function highlighting leaked into a string")
assert(group(4, 24) == "matlabComment", "Function highlighting leaked into a comment")
print "MATLAB syntax checks passed"
vim.cmd "qa!"
