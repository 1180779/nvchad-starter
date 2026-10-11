# Send LaTeX selections to Claude Code or Codex

Leader is Space. These visual mappings work in LaTeX and other text buffers:

| Shortcut | Action |
| --- | --- |
| Space l s | Send to the selected AI target (Claude by default) |
| Ctrl+Alt+K | Same as Space l s |
| Space l Shift+s | Send directly to Codex |

Run `:AISendTarget codex` to make the shared shortcuts send to Codex for this
Neovim session. Run `:AISendTarget claude` to switch back. To use Codex by default
after every restart, set `vim.g.ai_send_target = "codex"` in `init.lua`.

## Claude Code

Start Claude Code in your separate terminal and connect it to Neovim with `/ide`.
Sending uses `claudecode.nvim`'s existing `ClaudeCodeSend` command and adds the
file/line reference to Claude. This connection protocol is specific to Claude;
Codex uses the terminal workflow below.

## Codex in a separate terminal

On this machine, run `codex` as usual from your project directory. The shell
function keeps `codex-statusline`'s usage bar and private tmux session. The
`NVIM_CODEX_TMUX_SOCKETS` setting in `.zshrc` lets Neovim discover these sessions,
including several concurrent launches. Open a new shell, or run `source ~/.zshrc`,
then restart Neovim from that shell so it inherits the setting.

Alternatively, start the Codex executable directly in tmux from your LaTeX
project directory:

    tmux new-session -s codex ~/.local/bin/codex

For this manual launch, Neovim and Codex must use the same tmux server.
Neovim can run outside tmux.
If you already use tmux, run `codex` in another pane or window on that server.
The sender discovers panes whose foreground command is `codex`. If there are
several, it asks you to choose one and shows each pane's working directory and
server socket. The usage utility's Python supervisor is also recognized.

Select text in Neovim and press Space l Shift+s, or set `:AISendTarget codex`
and use Space l s / Ctrl+Alt+K. The selection is pasted into the Codex prompt,
with its absolute file path, line range, and file type. Add your request there,
then press Enter in Codex. Sending keeps editor focus and does not submit the
prompt.

The sender includes current unsaved text, without saving the file or changing
your yank register. Character, line, and block selections are supported.
Codex still reads files from disk when using its tools; save first if you want
those reads to match your buffer.

If tmux is unavailable or no Codex pane is found, the sender copies the same
context to your system clipboard and tells you to paste it into Codex manually.
This also works with Codex in an ordinary terminal without tmux. Clipboard
fallback requires a working Neovim clipboard provider.

Codex's interactive terminal workflow is described in the
[official CLI documentation](https://learn.chatgpt.com/docs/codex/cli).

## Verification

    nvim -n --headless -u NONE -i NONE -l tests/ai_send.lua

These tests verify selection extraction, unsaved text and file/line context,
target switching, pane selection, clipboard fallback, failed-paste cleanup,
and preserving editor focus and yank registers.
