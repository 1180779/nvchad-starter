require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- ╭──────────────────────────────────────────────────────────────╮
-- │  IdeaVim parity — mirrors ~/.ideavimrc  (leader = Space)        │
-- ╰──────────────────────────────────────────────────────────────╯

-- Free up the <leader>f prefix so <leader>f (reformat) fires instantly.
-- Removes NvChad's Telescope/format finders on <leader>f*; use <leader><leader>
-- (find files) and <leader>F (live grep) instead.
for _, lhs in ipairs { "<leader>fm", "<leader>fw", "<leader>fb", "<leader>fh", "<leader>fo", "<leader>fz", "<leader>ff", "<leader>fa" } do
  for _, mode in ipairs { "n", "x", "v" } do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Refactor / navigation (LSP)
map("n", "<leader>r", vim.lsp.buf.rename, { desc = "rename symbol (RenameElement)" })
map({ "n", "v" }, "<leader>t", vim.lsp.buf.code_action, { desc = "code/refactor actions (QuickList)" })
map("n", "<leader>g", vim.lsp.buf.definition, { desc = "goto declaration (GotoDeclaration)" })
map({ "n", "v" }, "<leader>f", function()
  require("conform").format { async = true, lsp_format = "fallback" }
end, { desc = "reformat code (ReformatCode)" })

-- Buffer / split management
map("n", "<leader>q", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "close buffer (CloseContent)" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "vertical split" })
map("n", "<leader>h", "<cmd>split<CR>", { desc = "horizontal split" })
map("n", "<leader>x", "<C-w>c", { desc = "close window" })
map("n", "<leader>X", "<C-w>o", { desc = "close other windows (UnsplitAll)" })

-- Quick info / docs
map("n", "<leader>qd", vim.lsp.buf.hover, { desc = "hover docs (QuickJavaDoc)" })
map("n", "<leader>qp", vim.lsp.buf.signature_help, { desc = "signature help (ParameterInfo)" })
map("n", "<leader>qe", vim.diagnostic.open_float, { desc = "show diagnostic (ShowErrorDescription)" })

-- Folding (closest analog to Collapse/Expand DocComments)
map("n", "<leader>zc", "zM", { desc = "collapse all folds" })
map("n", "<leader>zo", "zR", { desc = "expand all folds" })

-- VCS (gitsigns)
map({ "n", "v" }, "<leader>vr", "<cmd>Gitsigns reset_hunk<CR>", { desc = "rollback hunk (RollbackChangedLines)" })
map("n", "<leader>vb", "<cmd>Gitsigns blame_line<CR>", { desc = "blame line (Annotate)" })
-- NvChad maps <leader>gt (git status); that prefix makes <leader>g (goto-def) wait
-- timeoutlen before firing. Remove it and rehome git status under the <leader>v family.
pcall(vim.keymap.del, "n", "<leader>gt")
map("n", "<leader>vg", "<cmd>Telescope git_status<CR>", { desc = "git status (telescope)" })

-- Safe paste in visual mode (don't clobber the yank register) + toggle, like .ideavimrc
local paste_safe = true
map("x", "p", '"_dP', { desc = "paste without clobbering register" })
map("n", "<leader>pp", function()
  paste_safe = not paste_safe
  if paste_safe then
    map("x", "p", '"_dP', { desc = "paste without clobbering register" })
    vim.notify "Paste mode: SAFE (preserves register)"
  else
    map("x", "p", "p", { desc = "paste (overwrites register)" })
    vim.notify "Paste mode: DEFAULT (overwrites register)"
  end
end, { desc = "toggle safe paste" })

-- Fuzzy find & project search (same keys mirrored in .ideavimrc for parity)
map("n", "<leader><leader>", "<cmd>Telescope find_files<CR>", { desc = "find files (Search Everywhere)" })
map("n", "<leader>F", "<cmd>Telescope live_grep<CR>", { desc = "find in project (Find in Files)" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
-- 
-- VimTeX: these are already set by the plugin via <localleader>l*
-- but listed here for reference/documentation:
-- ,ll  → compile toggle
-- ,lv  → view PDF (forward search)
-- ,lk  → stop compiler
-- ,le  → quickfix errors
-- ,lo  → compiler output log
-- ,li  → plugin info / debug
-- ,lt  → table of contents
-- ,lc  → clean auxiliary files
-- ,lC  → clean all generated files

-- If you want <leader> aliases instead of / in addition to <localleader>:
vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    local opts = { buffer = true, silent = true }
    map("n", "<leader>ll", "<plug>(vimtex-compile)",        vim.tbl_extend("force", opts, { desc = "VimTeX compile toggle" }))
    map("n", "<leader>lv", "<plug>(vimtex-view)",           vim.tbl_extend("force", opts, { desc = "VimTeX view PDF" }))
    map("n", "<leader>lk", "<plug>(vimtex-stop)",           vim.tbl_extend("force", opts, { desc = "VimTeX stop compiler" }))
    map("n", "<leader>le", "<plug>(vimtex-errors)",         vim.tbl_extend("force", opts, { desc = "VimTeX errors" }))
    map("n", "<leader>lo", "<plug>(vimtex-compile-output)", vim.tbl_extend("force", opts, { desc = "VimTeX compiler output" }))
    map("n", "<leader>li", "<plug>(vimtex-info)",           vim.tbl_extend("force", opts, { desc = "VimTeX info" }))
    map("n", "<leader>lt", "<plug>(vimtex-toc-open)",       vim.tbl_extend("force", opts, { desc = "VimTeX TOC" }))
    map("n", "<leader>lc", "<plug>(vimtex-clean)",          vim.tbl_extend("force", opts, { desc = "VimTeX clean aux" }))
    -- Wrap visual selection in braces: { selection }  (VimTeX has no plain-brace wrap)
    map("x", "<leader>{", "c{<C-r>\"}<Esc>", vim.tbl_extend("force", opts, { desc = "wrap selection in { }" }))

    -- Debug: time the raw textDocument/definition LSP round-trip (texlab latency).
    -- Put cursor on a \ref/\cite and press <leader>ld; reports ms + #locations found.
    map("n", "<leader>ld", function()
      local t = vim.loop.hrtime()
      local params = vim.lsp.util.make_position_params(0, "utf-16")
      vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
        local ms = (vim.loop.hrtime() - t) / 1e6
        local n = result and (vim.islist(result) and #result or 1) or 0
        if err then
          vim.notify(("def: error after %.0f ms: %s"):format(ms, err.message), vim.log.levels.WARN)
        else
          vim.notify(("def: %.0f ms, %d location(s)"):format(ms, n))
        end
      end)
    end, vim.tbl_extend("force", opts, { desc = "debug: time goto-definition" }))

    -- Unroll a delimited, comma-separated group onto multiple lines.
    --     leaf/.style={draw=none, font=\small},
    -- becomes
    --     leaf/.style={
    --         draw=none,
    --         font=\small
    --     },
    -- Opening delimiter stays inline; each top-level item on its own indented line;
    -- closing delimiter on its own line at the source indent. Nested groups (depth>0)
    -- are left intact. The indentation produced matches latexindent's, so no extra
    -- formatter pass is needed.
    --
    -- Core: rewrite the buffer region [srow,scol)..(erow,ecol) spanning a group.
    local function unroll(srow, scol, erow, ecol)
      -- Line-wise (V) / end-of-line selections set the col to MAXCOL; clamp to the
      -- real line lengths so nvim_buf_set_text doesn't error with out-of-range cols.
      scol = math.min(scol, #vim.api.nvim_buf_get_lines(0, srow, srow + 1, true)[1])
      ecol = math.min(ecol, #vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1])
      local text = table.concat(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {}), "\n")

      -- indentation: base = source line's leading whitespace; items one shiftwidth deeper
      local base = vim.api.nvim_buf_get_lines(0, srow, srow + 1, true)[1]:match("^%s*") or ""
      local sw = vim.bo.expandtab and string.rep(" ", vim.fn.shiftwidth()) or "\t"
      local item_indent = base .. sw

      -- Detect an enclosing delimiter pair (va{ / va[ / va( style selection).
      local closes = { ["("] = ")", ["["] = "]", ["{"] = "}" }
      local lead = text:match("^%s*")
      local trail = text:match("%s*$")
      local core = text:sub(#lead + 1, #text - #trail)
      local open = core:sub(1, 1)
      local close = closes[open]
      local wrapped = close ~= nil and core:sub(-1) == close
      local inner = wrapped and core:sub(2, -2) or core

      -- Split inner at top-level commas (depth 0); nested () [] {} stay intact.
      local items, buf, depth = {}, "", 0
      for i = 1, #inner do
        local c = inner:sub(i, i)
        if c == "(" or c == "[" or c == "{" then depth = depth + 1
        elseif c == ")" or c == "]" or c == "}" then depth = depth - 1 end
        if c == "," and depth == 0 then
          items[#items + 1] = vim.trim(buf)
          buf = ""
        else
          buf = buf .. c
        end
      end
      items[#items + 1] = vim.trim(buf)

      local out
      if wrapped then
        -- open inline, items indented, close on its own line at base indent
        out = lead .. open
        for i, item in ipairs(items) do
          out = out .. "\n" .. item_indent .. item .. (i < #items and "," or "")
        end
        out = out .. "\n" .. base .. close
      else
        -- no enclosing delimiter selected: just split items onto indented lines
        out = item_indent .. table.concat(items, ",\n" .. item_indent)
      end
      vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, vim.split(out, "\n"))
    end

    -- Visual: unroll the current selection (select around the delimiter, e.g. va{).
    -- Disabled in favor of the normal-mode auto-detect map below; uncomment to restore.
    -- map("x", "<leader>l,", function()
    --   local s = vim.fn.getpos("'<")
    --   local e = vim.fn.getpos("'>")
    --   unroll(s[2] - 1, s[3] - 1, e[2] - 1, e[3])
    -- end, vim.tbl_extend("force", opts, { desc = "unroll selected delimited list" }))

    -- Normal: locate the innermost () [] {} group around the cursor and unroll it,
    -- so you don't have to select first. (Patterns: [ and ] need escaping in regex.)
    map("n", "<leader>l,", function()
      local best
      for _, p in ipairs { { "{", "}" }, { "\\[", "\\]" }, { "(", ")" } } do
        local o = vim.fn.searchpairpos(p[1], "", p[2], "nbcW")
        local c = vim.fn.searchpairpos(p[1], "", p[2], "ncW")
        if o[1] > 0 and c[1] > 0 then
          -- innermost enclosing group = the opening delimiter that comes latest
          if not best or o[1] > best.o[1] or (o[1] == best.o[1] and o[2] > best.o[2]) then
            best = { o = o, c = c }
          end
        end
      end
      if not best then
        vim.notify("No enclosing (), [] or {} around cursor", vim.log.levels.WARN)
        return
      end
      unroll(best.o[1] - 1, best.o[2] - 1, best.c[1] - 1, best.c[2])
    end, vim.tbl_extend("force", opts, { desc = "unroll delimited group at cursor" }))
  end,
})
