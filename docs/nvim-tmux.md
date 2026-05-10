# Neovim + tmux

A practical guide to the workflow this repo configures: tmux as the
session/pane manager, Neovim as the editor inside it. Splits in either tool
behave like splits in the other — `<C-h/j/k/l>` jumps across the boundary.

Source files: [`dot_tmux.conf`](../dot_tmux.conf),
[`dot_config/nvim/lua/plugins/tmux.lua`](../dot_config/nvim/lua/plugins/tmux.lua).

---

## Why tmux + Neovim (not zellij)

- `christoomey/vim-tmux-navigator` — battle-tested seamless pane navigation.
  Same `<C-h/j/k/l>` works whether the focused split is a Neovim window or a
  shell. Zellij needs `zellij-nav.nvim` plus lock-mode wrangling.
- tmux ships everywhere by default. SSH into any Linux box, `tmux` is there.
- Lower memory + zero-dependency. zellij is a Rust binary with WASM plugins.

---

## First-time bootstrap

After `chezmoi apply`, launch `tmux`. The config self-bootstraps TPM and
installs plugins on first run:

```sh
tmux           # opens a session; TPM clones itself + installs plugins
```

If plugin install gets stuck or you add new `@plugin` lines later:

```
<prefix> I       # install (capital I)
<prefix> U       # update
<prefix> alt-u   # remove plugins not in config
```

The prefix is `C-b` (tmux default).

---

## The navigation contract

In **both** tmux panes and Neovim splits:

| Key      | Action                                  |
| -------- | --------------------------------------- |
| `C-h`    | Move focus left                         |
| `C-j`    | Move focus down                         |
| `C-k`    | Move focus up                           |
| `C-l`    | Move focus right                        |
| `C-\`    | Jump to previously focused split/pane   |

How it works: tmux's `is_vim` shell check inspects the focused pane's
foreground process. If it's `vim`/`nvim`/`fzf`, the keystroke is forwarded
into the editor (where vim-tmux-navigator handles it). Otherwise tmux moves
between its own panes.

> `C-l` normally clears the shell screen. That's now `<prefix> C-l`.

---

## Cheat sheet

### tmux (prefix = `C-b`)

| Keybind             | Action                                       |
| ------------------- | -------------------------------------------- |
| `<prefix> \|`       | Split pane vertically (keeps cwd)            |
| `<prefix> -`        | Split pane horizontally (keeps cwd)          |
| `<prefix> H/J/K/L`  | Resize current pane (repeatable)             |
| `<prefix> c`        | New window                                   |
| `<prefix> ,`        | Rename window                                |
| `<prefix> 1..9`     | Jump to window N                             |
| `<prefix> z`        | Zoom / unzoom current pane                   |
| `<prefix> d`        | Detach session (reattach with `tmux a`)      |
| `<prefix> s`        | List sessions (switch with arrow + Enter)    |
| `<prefix> [`        | Enter copy-mode (vi keys: `v` select, `y` yank) |
| `<prefix> r`        | Reload `~/.tmux.conf`                        |
| `<prefix> C-l`      | Clear shell screen (`C-l` is now navigation) |

### Neovim splits

| Keybind   | Action                                 |
| --------- | -------------------------------------- |
| `<C-w>s`  | Horizontal split                       |
| `<C-w>v`  | Vertical split                         |
| `<C-w>q`  | Close current split                    |
| `<C-w>=`  | Equalize all split sizes               |

Combine with the navigation contract above for a smooth flow.

---

## Sessions: project-per-session pattern

A clean way to use tmux long-term is one session per project. Most people do
it via [`tmuxp`](https://github.com/tmux-python/tmuxp),
[`tmuxinator`](https://github.com/tmuxinator/tmuxinator), or this two-line
shell function:

```zsh
# Add to ~/.config/zsh/30-aliases.zsh
tm() {
  local name="${1:-$(basename "$PWD")}"
  tmux has-session -t "$name" 2>/dev/null \
    && tmux attach -t "$name" \
    || tmux new-session -s "$name"
}
```

Then `tm` from inside any project root attaches to (or creates) a session
named after the directory. `<prefix> s` lists all running sessions.

`tmux-resurrect` + `tmux-continuum` (already enabled) automatically save
sessions every 15 minutes and restore them on next tmux launch — so a
restart doesn't lose your layout.

---

## Clipboard

Three layers cooperate:

1. **Neovim** — uses the system clipboard register (`+`) directly. Either
   set `vim.opt.clipboard = "unnamedplus"` (LazyVim default behavior) or
   yank with `"+y` explicitly.
2. **tmux copy-mode** — `<prefix> [` enters copy-mode, `v` to select, `y`
   to yank. `tmux-yank` (already loaded) copies to the OS clipboard
   automatically (`pbcopy` on macOS, `xclip`/`wl-copy` on Linux).
3. **OSC 52** — `set -g set-clipboard on` lets remote tmux sessions over
   SSH yank to your local clipboard via the terminal escape sequence.
   Ghostty supports this out of the box.

---

## Truecolor & undercurl in Neovim

Without correct tmux config, Neovim inside tmux loses 24-bit color and
LSP wavy underlines.

This repo's `dot_tmux.conf` sets:

```tmux
set  -g default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB"
set -as terminal-features ",xterm-ghostty:RGB"
set -as terminal-features ",*:usstyle"     # styled underlines (undercurl)
set -as terminal-features ",*:hyperlinks"  # OSC 8
```

Verify inside tmux:

```sh
tmux info | grep -E '(RGB|Tc)'
:checkhealth                # in Neovim — should report 24-bit color
```

If colors look washed out, your **outer** terminal needs to advertise RGB.
Ghostty does. For others (Alacritty, Kitty, WezTerm) — check their docs.

---

## Extended keys (CSI-u)

`set -g extended-keys on` lets Neovim distinguish keys that classic xterm
collapses to the same code:

- `<C-i>` vs. `<Tab>`
- `<C-Tab>`, `<C-S-key>`, `<C-S-Tab>`
- Function keys with modifiers

This matters mostly for Neovim plugins that bind chords like `<C-S-h>`.
Both tmux and the outer terminal must support it; Ghostty does.

---

## Common pitfalls

**Esc lag in Neovim insert→normal mode.**
Already mitigated with `set -g escape-time 10`. Don't set it to `0` — that
breaks meta-key sequences sent as `Esc + key`.

**`<C-h>` doesn't move left in Neovim.**
Some terminals send `<BS>` for `<C-h>`. If you hit this, add to nvim:

```lua
-- lua/config/keymaps.lua
vim.keymap.set({ "n", "i" }, "<BS>", "<C-h>")
```

Or fix the terminal — Ghostty handles it correctly.

**Pane-nav forwarded into the wrong process.**
The `is_vim` regex in `dot_tmux.conf` matches `vim`, `nvim`, `view`, `fzf`,
plus `*diff` variants. If you wrap nvim in another command (e.g. `sudoedit
nvim`, a custom shell script), tmux won't recognize it and will move panes
instead of forwarding. Either rename the wrapper or extend the regex.

**`tmux` shows old config after edit.**
Either `<prefix> r` to reload, or kill the server: `tmux kill-server`. Live
sessions reload, but per-session options set via `set -g` only apply to
new sessions.

**TERM warning when SSH'ing.**
If you see `terminfo missing for TERM=xterm-ghostty`, the host's terminfo
DB doesn't know Ghostty. Ghostty's config in this repo enables the
`ssh-terminfo` shell-integration feature, which auto-installs the
terminfo on first connect. See [`dot_config/ghostty/config.tmpl`](../dot_config/ghostty/config.tmpl).

---

## Customization pointers

- Add tmux plugins: append `set -g @plugin '…'` lines, then `<prefix> I`.
- Add Neovim splits-aware resizing (`<A-h/j/k/l>` resizes across boundary):
  swap vim-tmux-navigator for [`mrjones2014/smart-splits.nvim`](https://github.com/mrjones2014/smart-splits.nvim) and
  add the matching tmux bindings. Heavier but slicker.
- Save layouts as code: try
  [`tmuxp`](https://github.com/tmux-python/tmuxp) (`tmuxp load project.yaml`)
  for repeatable per-project window/pane layouts.
