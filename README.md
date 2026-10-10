**This repo is supposed to be used as config by NvChad users!**

- The main nvchad repo (NvChad/NvChad) is used as a plugin by this repo.
- So you just import its modules , like `require "nvchad.options" , require "nvchad.mappings"`
- So you can delete the .git from this repo ( when you clone it locally ) or fork it :)

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!

# MATLAB

Edit ordinary `.m` files in Neovim, with MathWorks' `matlab_ls` for completion,
diagnostics, signature help, and definition/reference navigation. Execution uses
a persistent Python bridge to your existing MATLAB desktop session. Text output
appears in a reusable bottom split; focus stays in your code. Variables and figure
windows belong to the connected MATLAB session.

## Setup

1. Install the language server with `:MasonInstall matlab-language-server`
   (already installed on this machine). It requires Node.js and MATLAB R2021b+.
2. In your MATLAB Command Window, once per desktop session, run:
   ```matlab
   matlab.engine.shareEngine('NvimMatlab')
   ```
3. Restart Neovim and open a `.m` file. Check `:checkhealth vim.lsp` if the server
   does not attach. Syntax highlighting is provided by Neovim; the execution
   bridge runs independently of the language server.

The MATLAB root is detected from the resolved `matlab` executable on PATH.
R2026a+ ships a Python Engine in `extern/engines/python/dist`, which the bridge
uses automatically. This machine's R2026b installation works with `python3`.
For older releases, install the matching MATLAB Engine into a compatible Python
environment using [MathWorks' installation instructions](https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html).

Optional overrides belong in `init.lua`, before plugin setup:

```lua
vim.g.matlab_root = "/usr/local/MATLAB/R2026b"
vim.g.matlab_python = "/path/to/venv/bin/python"
vim.g.matlab_session = "NvimMatlab"
```

## Shortcuts

These mappings apply only to MATLAB buffers. Leader is Space.

| Shortcut | Action |
| --- | --- |
| `<leader>mr` | Save and run the current `.m` script |
| Visual `<leader>mr` | Evaluate the selected characters/lines |
| `<leader>mc` | Evaluate the current `%%` section |
| `<leader>mo` | Show/hide the output split |
| `<leader>me` | Enter a MATLAB command, e.g. `result = myfunction(3)` |

Use normal split navigation (`Ctrl-w j/k`) to enter/leave the output pane, and
`q` there to hide it. You can search and yank output normally. Each run replaces
the previous output. Another run is rejected while the previous one is active.

Scripts execute in the shared session's base workspace. Functions requiring
arguments should be called through `<leader>me`. Selections and sections evaluate
without saving; dependent functions must be on MATLAB's path. Plot output stays
in MATLAB figure windows. Use MATLAB's GUI for interactive debugging and stopping
a computation; this output pane is not an interactive Command Window. Binary
`.mlx` live scripts are not supported by this editing workflow.

The LSP may launch a separate MATLAB process for analysis. Its completion does
not automatically inspect variables from the shared desktop. The bridge only
attaches to the explicitly named session; it never starts another MATLAB instance.
If MATLAB restarts, share the new session and run again.

## Verification

```sh
python3 -B tests/test_matlab_bridge.py
nvim --headless -u NONE -i NONE -l tests/matlab.lua
```

These check the protocol, failure recovery, mappings, selection/section execution,
save-before-run, and split behavior without a MATLAB license/session. To check
the real connection, share your desktop session and run a script such as
`bridge_check = 42; disp(bridge_check)` using `<leader>mr`; then inspect
`bridge_check` in MATLAB's Workspace browser.
