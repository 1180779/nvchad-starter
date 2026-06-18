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

    -- Split selected comma-separated list (e.g. inside [...]) one item per line.
    -- Only top-level commas (depth 0 of (), [], {}) are split, so nested groups stay intact.
    map("x", "<leader>l,", function()
      local s = vim.fn.getpos("'<")
      local e = vim.fn.getpos("'>")
      local srow, scol = s[2] - 1, s[3] - 1
      local erow, ecol = e[2] - 1, e[3] -- end-exclusive for set_text
      local text = table.concat(vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {}), "\n")

      -- indent: one shiftwidth deeper than the line where the selection starts
      local base = vim.api.nvim_buf_get_lines(0, srow, srow + 1, true)[1]:match("^%s*") or ""
      local sw = vim.bo.expandtab and string.rep(" ", vim.fn.shiftwidth()) or "\t"
      local indent = base .. sw

      local items, buf, depth = {}, "", 0
      for i = 1, #text do
        local c = text:sub(i, i)
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

      local out = indent .. table.concat(items, ",\n" .. indent)
      vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, vim.split(out, "\n"))
    end, vim.tbl_extend("force", opts, { desc = "split comma list onto lines" }))
  end,
})
