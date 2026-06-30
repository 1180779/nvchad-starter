return {
  {
    "writing_exercises",
    lazy = false,
    dev = true,
  },
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },
  {
    "ludovicchabant/vim-gutentags",
    ft = { "tex", "bib" }, -- lazy-load only for tex files
    init = function()
      -- gutentags config must be set before the plugin loads
      vim.g.gutentags_enabled = 1
      vim.g.gutentags_generate_on_new = 1
      vim.g.gutentags_generate_on_missing = 1
      vim.g.gutentags_generate_on_write = 1
      vim.g.gutentags_generate_on_empty_buffer = 0

      -- Optional: store tag files in a central cache dir
      -- instead of polluting your project directories
      vim.g.gutentags_cache_dir = vim.fn.expand "~/.cache/nvim/ctags"

      -- Optional: restrict to only tex-related file types
      vim.g.gutentags_project_root = { ".git", ".latexmkrc", "main.tex" }
      vim.g.gutentags_file_list_command = "find . -name '*.tex' -o -name '*.bib'"
    end,
  },
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_imaps_enabled = 0
      vim.g.vimtex_mappings_enabled = 1
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
    config = function()
      -- Maximize the zathura window showing the given (or current) PDF.
      local function maximize_zathura(pdf)
        pdf = pdf or (vim.fn.expand "%:p:r" .. ".pdf")
        vim.fn.jobstart {
          "bash",
          "-c",
          [[
          pdf="]] .. pdf .. [["
          wid=$(xdotool search --class zathura 2>/dev/null | while read id; do
            name=$(xdotool getwindowname "$id" 2>/dev/null)
            case "$name" in
              *"$pdf"*) echo "$id"; break;;
            esac
          done)
          [ -z "$wid" ] && wid=$(xdotool search --sync --class zathura 2>/dev/null | tail -1)
          [ -n "$wid" ] && xdotool windowfocus --sync "$wid" && \
            wmctrl -i -r "$(printf '0x%x' "$wid")" -b add,maximized_vert,maximized_horz
        ]],
        }
      end

      -- Explicit forward search / :VimtexView
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventView",
        callback = function()
          maximize_zathura()
        end,
      })

      -- First automatic open after the initial successful compile (once per buffer)
      vim.api.nvim_create_autocmd("User", {
        pattern = "VimtexEventCompileSuccess",
        callback = function()
          if vim.b.zathura_maximized then
            return
          end
          vim.b.zathura_maximized = true
          local pdf = vim.fn.expand "%:p:r" .. ".pdf"
          -- small delay so zathura has spawned and the WM has mapped its window
          vim.defer_fn(function()
            maximize_zathura(pdf)
          end, 800)
        end,
      })
    end,
  },
  {
    "coder/claudecode.nvim",
    event = "VeryLazy", -- load at startup so the WS server + ~/.claude/ide/ lockfile exist for /ide
    opts = {
      -- Claude runs in a separate terminal, so no-op the integrated terminal (no split on send)
      terminal = { provider = "none" },
    },
    keys = {
      -- Visually select, then push it to a connected Claude Code session as @file#Lx-y
      { "<leader>ls", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude Code" },
      -- IntelliJ muscle memory: Ctrl+Alt+K also sends the selection.
      { "<C-M-k>", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude Code" },
    },
  },
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
