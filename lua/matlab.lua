local M = {}
local job, output_buf, busy
local help_origin, help_win
local output = ""
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

function M.root()
  if vim.g.matlab_root then
    return vim.g.matlab_root
  end
  local executable = vim.fn.exepath "matlab"
  local resolved = vim.uv.fs_realpath(executable)
  local root = resolved and vim.fn.fnamemodify(resolved, ":h:h") or ""
  if vim.fn.filereadable(root .. "/bin/glnxa64/MATLAB") == 1 then
    return root
  end
  -- A user launcher may be first on PATH; the packaged executable still
  -- identifies the installation used by the Python Engine and language server.
  resolved = vim.uv.fs_realpath "/usr/bin/matlab"
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

local function fail(text)
  busy = false
  if help_origin then
    help_origin = nil
    vim.notify(text, vim.log.levels.WARN)
  else
    append(text .. "\n")
  end
end

local function show_help(text)
  local origin = help_origin
  help_origin, busy = nil, false
  if
    not origin
    or not vim.api.nvim_win_is_valid(origin.win)
    or vim.api.nvim_win_get_buf(origin.win) ~= origin.buf
    or not vim.deep_equal(vim.api.nvim_win_get_cursor(origin.win), origin.cursor)
  then
    return
  end
  if vim.trim(text) == "" then
    vim.notify("No MATLAB help found for " .. origin.topic, vim.log.levels.INFO)
    return
  end
  -- MATLAB help can contain desktop hyperlinks; keep their readable labels.
  text = text:gsub("<a[^>]*>(.-)</a>", "%1")
  vim.api.nvim_win_call(origin.win, function()
    local buf
    buf, help_win = vim.lsp.util.open_floating_preview(vim.split(text, "\n"), "plaintext", {
      border = "rounded",
      title = " MATLAB: " .. origin.topic .. " ",
      max_width = 90,
      max_height = 20,
      focus_id = "matlab-help",
    })
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = buf, silent = true })
  end)
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
        elseif ok and event.type == "help" then
          show_help(event.text)
        elseif ok and event.type == "error" then
          fail(event.text)
        elseif ok and event.type == "done" then
          busy = false
          append "\n[Finished]\n"
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
      job = nil
      if busy or code ~= 0 then
        fail("[Bridge exited: " .. code .. "]")
      end
    end,
  })
  if id <= 0 then
    fail "Cannot start Python; configure vim.g.matlab_python."
    return false
  end
  job = id
  return true
end

local function request(payload)
  busy = true
  if start_bridge() then
    local ok = pcall(vim.fn.chansend, job, vim.json.encode(payload) .. "\n")
    if not ok then
      fail "Bridge disconnected; try again."
    end
  end
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
  request { code = code }
end

function M.help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_set_current_win(help_win)
    return
  end
  if busy then
    vim.notify("MATLAB is still running the previous request", vim.log.levels.WARN)
    return
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local topic
  -- Keep dotted names intact: help containers.Map.isKey, not just isKey.
  for first, name, last in line:gmatch "()([%a_][%w_%.]*)()" do
    if first <= col and col < last then
      topic = name:gsub("%.$", "")
      break
    end
  end
  if not topic then
    vim.notify("Place the cursor on a MATLAB symbol", vim.log.levels.INFO)
    return
  end
  help_origin = {
    win = vim.api.nvim_get_current_win(),
    buf = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(0),
    topic = topic,
  }
  request { help = topic }
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

function M.format()
  require("conform").format({ async = true, lsp_format = "fallback", quiet = true }, function(err)
    if err then
      -- Conform uses a temporary filename beside the source file.
      local message = err:gsub("%.conform%.%d+%.", "")
      vim.notify(message, vim.log.levels.ERROR, { title = "MATLAB formatting" })
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
    { "n", "<leader>qd", M.help, "MATLAB help for symbol" },
    { { "n", "x" }, "<leader>f", M.format, "Format MATLAB code" },
  } do
    vim.keymap.set(entry[1], entry[2], entry[3], { buffer = buf, desc = entry[4] })
  end
end

return M
