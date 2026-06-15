require "nvchad.options"

-- add yours here!

local o = vim.o

-- Ported from ~/.ideavimrc so Neovim behaves like your IdeaVim setup
o.scrolloff = 5 -- keep 5 lines of context above/below the cursor
o.relativenumber = true -- relative line numbers
o.ignorecase = true -- case-insensitive searching...
o.smartcase = true -- ...unless the query contains an uppercase letter
o.incsearch = true -- show matches as you type (default on in nvim)

-- Use the system clipboard for all yank/paste (like clipboard+=unnamed/ideaput)
o.clipboard = "unnamedplus"

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
