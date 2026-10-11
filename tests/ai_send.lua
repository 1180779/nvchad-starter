-- Run: nvim -n --headless -u NONE -i NONE -l tests/ai_send.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.g.mapleader = " "
local calls, notices, clipboard = {}, {}, nil
local panes = "%12\tcodex\t/home/me/paper\n"
local failure
local current_command = "codex\n"
vim.notify = function(message, level)
  notices[#notices + 1] = { message, level }
end
vim.system = function(args, opts)
  calls[#calls + 1] = { args = args, opts = opts }
  return {
    wait = function()
      if args[2] == failure then
        return { code = 1, stdout = "", stderr = "test failure" }
      end
      local stdout = args[2] == "list-panes" and panes or args[2] == "display-message" and current_command or ""
      return { code = 0, stdout = stdout, stderr = "" }
    end,
  }
end
local original_setreg = vim.fn.setreg
vim.fn.setreg = function(register, text, ...)
  if register == "+" then
    clipboard = text
    return 0
  end
  return original_setreg(register, text, ...)
end
local ai = require "ai_send"
ai.setup()
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buf, "/tmp/paper quote's.tex")
vim.bo.filetype = "tex"
local win = vim.api.nvim_get_current_win()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "α + β", "\\section{Draft}", "unsaved text" })
vim.fn.setreg('"', "keep my yank")

local function select(keys, row, col)
  calls, notices, clipboard = {}, {}, nil
  vim.cmd "normal! \27"
  vim.api.nvim_win_set_cursor(win, { row or 1, col or 0 })
  vim.cmd("normal! " .. keys)
end
local function pasted_text()
  assert(calls[1].args[2] == "list-panes")
  assert(calls[2].args[2] == "display-message")
  assert(calls[3].args[2] == "load-buffer")
  assert(calls[3].args[#calls[3].args] == "-")
  assert(calls[4].args[2] == "paste-buffer")
  assert(vim.tbl_contains(calls[4].args, "-p"), "Missing bracketed paste")
  assert(vim.tbl_contains(calls[4].args, "-r"), "Newlines must be preserved")
  assert(calls[4].args[#calls[4].args] == "%12")
  assert(#calls == 4, "Must not press Enter or execute a prompt")
  assert(vim.api.nvim_get_current_win() == win, "Sending stole focus")
  assert(vim.fn.getreg '"' == "keep my yank", "Sending clobbered yank register")
  assert(vim.bo.modified, "Sending saved unsaved edits")
  return calls[3].opts.stdin
end

select("Vj", 2)
ai.send_codex()
local text = pasted_text()
assert(text:find("/tmp/paper quote's.tex:2-3", 1, true), text)
assert(text:find("```tex\n\\section{Draft}\nunsaved text\n```", 1, true), text)
select "v"
ai.send_codex()
assert(pasted_text():find("```tex\nα\n```", 1, true), "UTF-8 character selection was truncated")
select("Vk", 3)
-- A backwards line selection must retain source order.
ai.send_codex()
assert(pasted_text():find("\\section{Draft}\nunsaved text", 1, true))
vim.o.selection = "exclusive"
select "vl"
ai.send_codex()
assert(pasted_text():find("```tex\nα\n```", 1, true))
vim.o.selection = "inclusive"
select("\22jl", 2)
ai.send_codex()
assert(pasted_text():find("```tex\n\\s\nun\n```", 1, true), "Block selection must keep its rectangle")

local picked
vim.ui.select = function(items, _, callback)
  picked = items
  callback(items[2])
end
panes = "%12\tcodex\t/project/one\n%13\tcodex\t/project/two\n%14\tzsh\t/project/three\n"
select "V"
ai.send_codex()
assert(#picked == 2, "Offered a shell as a Codex target")
assert(calls[4].args[#calls[4].args] == "%13")
current_command = "zsh\n"
select "V"
ai.send_codex()
assert(#calls == 2 and clipboard, "Pasted after Codex exited during pane selection")
current_command = "codex\n"

panes = "%14\tzsh\t/project\n"
select "V"
ai.send_codex()
assert(#calls == 1, "Pasted into a shell without Codex")
assert(clipboard and clipboard:find("α + β", 1, true), "Missing clipboard fallback")
failure = "list-panes"
select "V"
ai.send_codex()
assert(clipboard, "Unavailable tmux should offer clipboard fallback")
failure = "load-buffer"
panes = "%12\tcodex\t/project\n"
select "V"
ai.send_codex()
assert(#calls == 3 and clipboard, "A failed buffer load must not paste")
failure = "paste-buffer"
panes = "%12\tcodex\t/project\n"
select "V"
ai.send_codex()
assert(calls[5].args[2] == "delete-buffer", "Failed paste left a temporary tmux buffer")
assert(clipboard, "Failed paste should retain selection for manual paste")
failure = nil

vim.ui.select = function(_, _, callback)
  callback(nil)
end
panes = "%12\tcodex\t/project/one\n%13\tcodex\t/project/two\n"
select "V"
ai.send_codex()
assert(#calls == 1 and not clipboard, "Cancelling the pane chooser sent text")
panes = "%12\tcodex\t/project\n"
select "V"
vim.cmd "normal! \27"
ai.send_codex()
assert(#calls == 0 and not clipboard, "Sent stale text outside Visual mode")

vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "```", "α + β" })
select "Vj"
ai.send_codex()
assert(pasted_text():find("````tex\n```\nα + β\n````", 1, true), "Embedded fences broke context")

local claude_calls = 0
vim.api.nvim_create_user_command("ClaudeCodeSend", function()
  assert(vim.fn.mode() == "V", "Claude lost the active visual selection")
  claude_calls = claude_calls + 1
end, {})
select "V"
ai.send()
assert(claude_calls == 1, "Default Claude send was changed")
vim.cmd "AISendTarget codex"
select "V"
ai.send()
pasted_text()
vim.cmd "AISendTarget claude"
select "V"
ai.send()
assert(claude_calls == 2)
vim.cmd "AISendTarget invalid"
assert(vim.g.ai_send_target == "claude", "An invalid target replaced a working target")
-- Load the real mappings file and trigger the LaTeX hooks to detect conflicts.
package.loaded["nvchad.mappings"] = true
require "mappings"
vim.api.nvim_exec_autocmds("FileType", { pattern = "tex" })
assert(vim.fn.maparg(" ls", "x", false, true).callback)
assert(vim.fn.maparg(" lS", "x", false, true).callback)
assert(vim.fn.maparg("<C-M-k>", "x", false, true).callback)
assert(vim.fn.maparg(" lc", "n", false, true).rhs:lower() == "<plug>(vimtex-clean)")
print "AI selection sending tests passed"
