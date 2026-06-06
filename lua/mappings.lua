require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

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
  end,
})
