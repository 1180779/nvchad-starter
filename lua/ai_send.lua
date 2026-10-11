local M = {}

local function tmux(args, stdin)
  local ok, result = pcall(function()
    return vim.system(vim.list_extend({ "tmux" }, args), { text = true, stdin = stdin }):wait(2000)
  end)
  return ok and result.code == 0 and result.stdout or nil
end

local function copy_for_codex(text, reason)
  local ok, result = pcall(vim.fn.setreg, "+", text)
  if ok and result == 0 then
    vim.notify(reason .. "; selection copied. Paste it into Codex.", vim.log.levels.WARN)
  else
    vim.notify(reason .. "; could not copy to the clipboard.", vim.log.levels.ERROR)
  end
end

local function paste_into(pane, text)
  local command = tmux { "display-message", "-p", "-t", pane.id, "#{pane_current_command}" }
  if not command or vim.trim(command) ~= "codex" then
    copy_for_codex(text, "The selected pane is no longer running Codex")
    return
  end
  local buffer = "nvim-codex-" .. vim.fn.getpid() .. "-" .. vim.uv.hrtime()
  if not tmux({ "load-buffer", "-b", buffer, "-" }, text) then
    copy_for_codex(text, "Could not load the tmux paste buffer")
    return
  end
  -- Preserve newlines and request bracketed paste. Leave Enter to the user.
  if not tmux { "paste-buffer", "-p", "-r", "-d", "-b", buffer, "-t", pane.id } then
    tmux { "delete-buffer", "-b", buffer }
    copy_for_codex(text, "Could not paste into the Codex pane")
    return
  end
  vim.notify("Selection pasted into Codex " .. pane.id .. ". Submit it in that terminal.")
end

function M.send_codex()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    vim.notify("Select text before sending to Codex", vim.log.levels.WARN)
    return
  end
  local anchor, cursor = vim.fn.getpos "v", vim.fn.getpos "."
  local lines = vim.fn.getregion(anchor, cursor, { type = mode, exclusive = vim.o.selection == "exclusive" })
  local first = math.min(anchor[2], cursor[2])
  local path = vim.api.nvim_buf_get_name(0)
  local text = table.concat(lines, "\n")
  local fence = "```"
  for ticks in text:gmatch "`+" do
    if #ticks >= #fence then
      fence = string.rep("`", #ticks + 1)
    end
  end
  local prompt = ("Selection from %s:%d-%d (current buffer):\n%s%s\n%s\n%s"):format(
    path ~= "" and path or "[unnamed]",
    first,
    first + #lines - 1,
    fence,
    vim.bo.filetype,
    text,
    fence
  )
  vim.cmd "normal! \27"

  local output = tmux { "list-panes", "-a", "-F", "#{pane_id}\t#{pane_current_command}\t#{pane_current_path}" }
  if not output then
    copy_for_codex(prompt, "tmux is unavailable")
    return
  end
  local panes = {}
  for line in output:gmatch "[^\n]+" do
    local id, command, cwd = line:match "^(%%%d+)\t([^\t]+)\t(.*)$"
    if command == "codex" then
      panes[#panes + 1] = { id = id, cwd = cwd }
    end
  end
  if #panes == 0 then
    copy_for_codex(prompt, "No Codex tmux pane found")
  elseif #panes == 1 then
    paste_into(panes[1], prompt)
  else
    vim.ui.select(panes, {
      prompt = "Send selection to Codex:",
      format_item = function(pane)
        return pane.id .. "  " .. pane.cwd
      end,
    }, function(pane)
      if pane then
        paste_into(pane, prompt)
      end
    end)
  end
end

function M.send()
  local target = vim.g.ai_send_target or "claude"
  if target == "codex" then
    M.send_codex()
  elseif target == "claude" then
    vim.cmd "ClaudeCodeSend"
  else
    vim.notify("Unknown AI send target: " .. tostring(target), vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("AISendTarget", function(opts)
    if opts.args ~= "claude" and opts.args ~= "codex" then
      vim.notify("Use :AISendTarget claude or :AISendTarget codex", vim.log.levels.ERROR)
      return
    end
    vim.g.ai_send_target = opts.args
    vim.notify("AI send target: " .. opts.args)
  end, {
    nargs = 1,
    complete = function()
      return { "claude", "codex" }
    end,
  })
  vim.keymap.set("x", "<leader>ls", M.send, { desc = "Send selection to AI" })
  vim.keymap.set("x", "<C-M-k>", M.send, { desc = "Send selection to AI" })
  vim.keymap.set("x", "<leader>lS", M.send_codex, { desc = "Send selection to Codex" })
end

return M
