local M = {}
local job, output_buf, busy
local output = ""
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

function M.root()
  if vim.g.matlab_root then
    return vim.g.matlab_root
  end
  local executable = vim.fn.exepath "matlab"
  local resolved = vim.uv.fs_realpath(executable)
  return resolved and vim.fn.fnamemodify(resolved, ":h:h") or ""
end

local function buffer()
  if not output_buf or not vim.api.nvim_buf_is_valid(output_buf) then
    output_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(output_buf, "MATLAB output")
    vim.bo[output_buf].bufhidden = "hide"
    vim.bo[output_buf].swapfile = false
    vim.bo[output_buf].filetype = "matlaboutput"
    vim.keymap.set("n", "q", M.toggle_output, { buffer = output_buf, desc = "Hide MATLAB output" })
  end
  return output_buf
end

local function append(text)
  output = output .. text
  local buf = buffer()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n", { plain = true }))
  vim.bo[buf].modifiable = false
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
end

local function show_output()
  local buf = buffer()
  if #vim.fn.win_findbuf(buf) > 0 then
    return
  end
  local current = vim.api.nvim_get_current_win()
  vim.cmd "botright 12split"
  vim.api.nvim_win_set_buf(0, buf)
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.api.nvim_set_current_win(current)
end

function M.toggle_output()
  local wins = output_buf and vim.fn.win_findbuf(output_buf) or {}
  if #wins == 0 then
    show_output()
  else
    for _, win in ipairs(wins) do
      if #vim.api.nvim_list_wins() > 1 then
        vim.api.nvim_win_close(win, false)
      end
    end
  end
end

local function start_bridge()
  if job then
    return true
  end
  local pending = ""
  local id = vim.fn.jobstart({
    vim.g.matlab_python or "python3",
    "-u",
    config_dir .. "/scripts/matlab_bridge.py",
    M.root(),
    vim.g.matlab_session or "NvimMatlab",
  }, {
    on_stdout = function(_, data)
      pending = pending .. table.concat(data, "\n")
      while pending:find("\n", 1, true) do
        local line, rest = pending:match "^(.-)\n(.*)$"
        pending = rest
        local ok, event = pcall(vim.json.decode, line)
        if ok and event.type == "output" then
          append(event.text)
        elseif ok and (event.type == "done" or event.type == "error") then
          busy = false
          append(event.type == "done" and "\n[Finished]\n" or "\n" .. event.text .. "\n")
        elseif line ~= "" then
          append(line .. "\n")
        end
      end
    end,
    on_stderr = function(_, data)
      local text = table.concat(data, "\n")
      if text ~= "" then
        append(text .. "\n")
      end
    end,
    on_exit = function(_, code)
      job, busy = nil, false
      if code ~= 0 then
        append("\n[Bridge exited: " .. code .. "]\n")
      end
    end,
  })
  if id <= 0 then
    busy = false
    append "Cannot start Python; configure vim.g.matlab_python.\n"
    return false
  end
  job = id
  return true
end

local function quote(text)
  return "'" .. text:gsub("'", "''") .. "'"
end

local function send(code, label)
  if busy then
    vim.notify("MATLAB is still running the previous request", vim.log.levels.WARN)
    return
  end
  output = ""
  append(">> " .. label .. "\n")
  show_output()
  busy = true
  if start_bridge() then
    local ok = pcall(vim.fn.chansend, job, vim.json.encode { code = code } .. "\n")
    if not ok then
      busy = false
      append "Bridge disconnected; try again.\n"
    end
  end
end

function M.run_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.fn.fnamemodify(path, ":e") ~= "m" then
    vim.notify("Save the script as a .m file first", vim.log.levels.WARN)
    return
  end
  vim.cmd "write"
  send("run(" .. quote(path) .. ")", "run: " .. vim.fn.fnamemodify(path, ":t"))
end

function M.run_selection()
  if vim.fn.mode():sub(1, 1) == "\22" then
    vim.notify("Use a character or line selection for MATLAB code", vim.log.levels.WARN)
    return
  end
  local anchor, cursor = vim.fn.getpos "v", vim.fn.getpos "."
  local first, last = anchor[2], cursor[2]
  local first_col, last_col = anchor[3], cursor[3]
  if first > last or (first == last and first_col > last_col) then
    first, last, first_col, last_col = last, first, last_col, first_col
  end
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  if vim.fn.mode() == "v" then
    local finish = last_col
    if vim.o.selection == "exclusive" then
      finish = finish - 1
    else
      local tail = lines[#lines]:sub(last_col)
      finish = last_col + #(vim.fn.strcharpart(tail, 0, 1)) - 1
    end
    lines[#lines] = lines[#lines]:sub(1, finish)
    lines[1] = lines[1]:sub(first_col)
  end
  vim.cmd "normal! \27"
  send(table.concat(lines, "\n"), "selection")
end

function M.run_cell()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local first, last = 1, #lines
  for i, line in ipairs(lines) do
    if line:match "^%s*%%%%" then
      if i <= row then
        first = i
      else
        last = i - 1
        break
      end
    end
  end
  send(table.concat(vim.list_slice(lines, first, last), "\n"), "current section")
end

function M.command()
  vim.ui.input({ prompt = "MATLAB > " }, function(code)
    if code and vim.trim(code) ~= "" then
      send(code, code)
    end
  end)
end

function M.attach(buf)
  for _, entry in ipairs {
    { "n", "<leader>mr", M.run_file, "Run MATLAB script" },
    { "x", "<leader>mr", M.run_selection, "Run MATLAB selection" },
    { "n", "<leader>mc", M.run_cell, "Run MATLAB section" },
    { "n", "<leader>mo", M.toggle_output, "Toggle MATLAB output" },
    { "n", "<leader>me", M.command, "Enter MATLAB command" },
  } do
    vim.keymap.set(entry[1], entry[2], entry[3], { buffer = buf, desc = entry[4] })
  end
end

return M
