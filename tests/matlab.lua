-- Run: nvim --headless -u NONE -i NONE -l tests/matlab.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local matlab = require "matlab"
local sent, callbacks, request
vim.fn.jobstart = function(_, opts)
  callbacks = opts
  return 123
end
vim.fn.chansend = function(_, data)
  request = vim.json.decode(data)
  sent = request.code
  if request.help then
    callbacks.on_stdout(
      123,
      { '{"type":"help","text":"Map.isKey - Test key membership\\nSyntax: isKey(map,key)"}', "" }
    )
    return
  end
  callbacks.on_stdout(123, { '{"type":"output","text":"Result: 42\\n"}', '{"type":"done","text":""}', "" })
end

local source = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()
matlab.attach(source)
assert(vim.fn.maparg(" mr", "n", false, true).buffer == 1)
vim.api.nvim_buf_set_lines(source, 0, -1, false, {
  "before = 1;",
  "%% First",
  "x = 2;",
  "%% Second",
  "y = 3;",
})
vim.api.nvim_win_set_cursor(win, { 3, 0 })
matlab.run_cell()
assert(sent == "%% First\nx = 2;", sent)
assert(vim.api.nvim_get_current_win() == win, "Execution stole editor focus")
assert(#vim.api.nvim_list_wins() == 2)
local output_buf
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buf].filetype == "matlaboutput" then
    output_buf = buf
  end
end
assert(output_buf)
assert(table.concat(vim.api.nvim_buf_get_lines(output_buf, 0, -1, false), "\n"):find("Result: 42", 1, true))
vim.api.nvim_win_set_cursor(win, { 4, 0 })
matlab.run_cell()
assert(sent == "%% Second\ny = 3;", sent)
assert(#vim.api.nvim_list_wins() == 2, "Created another output split")
vim.api.nvim_win_set_cursor(win, { 1, 0 })
matlab.run_cell()
assert(sent == "before = 1;", sent)

vim.api.nvim_buf_set_lines(source, 0, -1, false, { "α = 1;", "beta = 2;" })
vim.api.nvim_win_set_cursor(win, { 1, 0 })
vim.cmd "normal! v"
matlab.run_selection()
assert(sent == "α", sent)
vim.api.nvim_win_set_cursor(win, { 1, 0 })
vim.cmd "normal! Vj"
matlab.run_selection()
assert(sent == "α = 1;\nbeta = 2;", sent)

local path = vim.fn.tempname() .. " quote's.m"
vim.api.nvim_buf_set_name(source, path)
matlab.run_file()
assert(sent == "run('" .. path:gsub("'", "''") .. "')", sent)
assert(vim.fn.readfile(path)[1] == "α = 1;", "Did not save before running")
vim.fn.delete(path)

matlab.toggle_output()
assert(#vim.api.nvim_list_wins() == 1)
matlab.toggle_output()
assert(#vim.api.nvim_list_wins() == 2)
assert(vim.fn.winbufnr(vim.fn.win_findbuf(output_buf)[1]) == output_buf)
assert(vim.api.nvim_get_current_win() == win)
local previous_output = vim.api.nvim_buf_get_lines(output_buf, 0, -1, false)
vim.api.nvim_buf_set_lines(source, 0, -1, false, { "found = containers.Map.isKey(map, key);" })
vim.api.nvim_win_set_cursor(win, { 1, 27 })
matlab.help()
assert(request.help == "containers.Map.isKey", vim.inspect(request))
assert(
  vim.deep_equal(previous_output, vim.api.nvim_buf_get_lines(output_buf, 0, -1, false)),
  "Help replaced run output"
)
assert(vim.api.nvim_get_current_win() == win, "Help stole editor focus")
local popup
for _, float in ipairs(vim.api.nvim_list_wins()) do
  if vim.api.nvim_win_get_config(float).relative ~= "" then
    popup = float
  end
end
assert(popup, "No help popup")
assert(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(popup), 0, 1, false)[1]:find("Map.isKey", 1, true))
matlab.help()
assert(vim.api.nvim_get_current_win() == popup, "Second help press did not focus the popup")
vim.cmd "normal \27"
assert(not vim.api.nvim_win_is_valid(popup), "Escape did not close the help popup")
assert(vim.api.nvim_get_current_win() == win, "Escape did not return to the editor")
assert(vim.fn.maparg(" qd", "n", false, true).buffer == 1)
print "MATLAB mapping, selection, section, save, and output checks passed"
vim.cmd "qa!"
