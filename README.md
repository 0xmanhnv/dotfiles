# dotfiles

Personal development environment for **macOS** and **Linux**, bootstrapped on a
fresh machine in one command. Managed with [chezmoi](https://www.chezmoi.io).

---

## Quick start

On a brand-new machine:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply 0xmanhnv
```

What that does, in order:

1. Installs the `chezmoi` binary
2. Clones this repo into `~/.local/share/chezmoi`
3. Runs `run_once_before_*` scripts:
   - `01-install-packages` — Homebrew + `Brewfile` (macOS) or apt/pacman/dnf (Linux). This is what installs zsh, neovim, tmux, etc.
   - `02-install-zsh-plugins` — clones the 3 zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`) into `~/.local/share/zsh/plugins/`. Must run after step 3a so git is available.
4. Renders templates (OS-aware) and links every dotfile into place
5. Runs `run_once_after_*` scripts:
   - `02-setup-shell` — `chsh` to zsh; TPM is bootstrapped by `~/.tmux.conf` itself on first tmux launch

If the machine doesn't have `git`/`curl` yet, run the bootstrap helper:

```sh
curl -fsSL https://raw.githubusercontent.com/0xmanhnv/dotfiles/main/bootstrap.sh | bash
```

---

## What's inside

```
.
├── bootstrap.sh                       Pre-flight installer (git/curl + chezmoi)
├── Brewfile                           macOS packages (`brew bundle`)
├── packages/
│   ├── apt.txt                        Debian/Ubuntu
│   └── pacman.txt                     Arch
│
├── .chezmoidata.yaml                  Variables (name, email, github_user)
├── .chezmoiignore                     Per-OS file filters
│
├── dot_zshrc                          Loader: pure zsh + Starship + 3 plugins (no OMZ)
├── dot_zshenv                         Pre-shell PATH (cargo, foundry)
├── dot_gitconfig.tmpl                 Git config (templated identity)
├── dot_tmux.conf                      tmux + auto-install TPM
│
├── dot_config/
│   ├── nvim/                          LazyVim distro
│   ├── ghostty/config                 macOS — terminal emulator
│   ├── starship.toml                  Prompt
│   ├── zellij/config.kdl              Multiplexer (alternative to tmux)
│   └── zsh/                           Modular shell config (see below)
│
├── private_dot_ssh/config.tmpl        SSH client (0600, OS-aware UseKeychain)
├── Library/Application Support/Code/User/settings.json   macOS — VS Code
│
└── run_once_*.sh.tmpl                 Idempotent setup scripts
```

---

## chezmoi naming conventions

| Source filename                  | Result                          |
| -------------------------------- | ------------------------------- |
| `dot_<name>`                     | `~/.<name>`                     |
| `<name>.tmpl`                    | Rendered as a Go template       |
| `private_<name>`                 | Permission `0600`               |
| `executable_<name>`              | Permission `0755`               |
| `run_once_<name>`                | Runs once per machine (by hash) |
| `run_onchange_<name>`            | Runs when content changes       |

The `dot_` prefix exists so the source dir doesn't end up cluttered with
hidden files when browsing in a file manager.

---

## Modular zsh

`~/.zshrc` is a 60-line **loader**. The real config lives in
`~/.config/zsh/*.zsh`, sourced in lexical order:

| File             | Purpose                                                   |
| ---------------- | --------------------------------------------------------- |
| `00-env.zsh`     | Cross-OS env vars (`HOMEBREW_NO_*`, `JAVA_TOOL_OPTIONS`)  |
| `10-path.zsh`    | Common PATH entries (`~/.local/bin`, `~/go/bin`)          |
| `20-tools.zsh`   | Tool init: cargo, gvm, jenv, redos                        |
| `30-aliases.zsh` | Aliases — every file path guarded by `[[ -d ]]`           |
| `40-darwin.zsh`  | macOS only: Homebrew Cellar globs, Android SDK, Ghostty   |
| `40-linux.zsh`   | Linux only: Linuxbrew, snap, flatpak                      |

OS-specific files are filtered by `.chezmoiignore`, so on Linux the macOS
file isn't even rendered to disk.

### Why modular?

1. **Adding a tool** is a 1-file edit, not "scroll through 250-line zshrc".
2. **`git diff`** stays per-topic.
3. **OS isolation** is structural (filename), not runtime conditionals.
4. **Cellar paths use globs** (`sort -V | tail -1`) — `brew upgrade` doesn't
   require editing PATH versions.

### Machine-specific overrides

Anything truly local (work laptop API keys, employer-specific paths) goes in
`~/.zshrc.local`. The loader sources it last. Not tracked.

### Performance notes

- `jenv` is initialized eagerly so `JAVA_HOME` auto-switches on `cd` in every
  shell (~50ms startup cost, accepted as a daily-driver tool). Future tools
  with similarly slow init (rbenv/nvm/pyenv) can be lazy-loaded with the
  stub-function pattern if startup speed becomes a concern.
- Loader uses `null_glob` so an empty `~/.config/zsh/` doesn't error.
- Source errors in any module are surfaced to stderr, not silently swallowed.

---

## Daily workflow

```sh
chezmoi edit ~/.zshrc          # Open the source file in $EDITOR
chezmoi diff                   # Preview pending changes
chezmoi apply                  # Apply them
chezmoi update                 # git pull + apply (the common one)
chezmoi add <file>             # Track a new dotfile
chezmoi cd                     # cd into the source repo
chezmoi source-path            # Print the source dir
```

### Adding a new dotfile

```sh
chezmoi add ~/.config/lazygit/config.yml
chezmoi cd
git add . && git commit -m "Add lazygit config" && git push
```

### Re-syncing a tool that rewrote its config

Some tools edit their own configs (e.g., LazyVim updates `lazy-lock.json`):

```sh
chezmoi re-add ~/.config/nvim/lazy-lock.json
```

---

## OS-specific behavior

|                              | macOS                    | Linux                |
| ---------------------------- | ------------------------ | -------------------- |
| Package manager              | Homebrew (`Brewfile`)    | apt / pacman / dnf   |
| Default terminal             | Ghostty (config tracked) | (your choice)        |
| `~/Library/...` configs      | Applied                  | Skipped              |
| `40-darwin.zsh`              | Loaded                   | Skipped              |
| `40-linux.zsh`               | Skipped                  | Loaded               |
| Cellar version pinning       | Auto via glob            | N/A                  |
| Git credential helper        | `osxkeychain`            | `cache --timeout`    |
| SSH `UseKeychain`            | Yes                      | No                   |

---

## Testing the bootstrap

Before trusting the one-liner on a real new machine, validate it end-to-end
in a throwaway container.

### Option A — test the live remote bootstrap (after pushing to GitHub)

```sh
docker run -it --rm ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq curl sudo
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply 0xmanhnv
'
```

Takes ~5–10 minutes. The container is wiped on exit, no cleanup needed.
Swap `ubuntu:24.04` for `archlinux:latest` or `fedora:latest` to test the
other distro paths in `run_once_before_01-install-packages.sh.tmpl`.

> **Private repo?** This needs `chezmoi init` to be able to clone via HTTPS or
> SSH. Either make the repo public for the test, mount a PAT into the
> container (`-e GITHUB_TOKEN=...`), or use Option B instead.

### Option B — test the local source (no push needed)

Useful while iterating on the source dir before pushing:

```sh
docker run -it --rm -v "$PWD:/dotfiles:ro" ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq curl sudo git
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
  chezmoi init --source=/dotfiles
  chezmoi apply
'
```

This bypasses GitHub entirely — chezmoi reads source files straight from the
mounted dir.

### What to verify after install completes

Inside the container after the script returns, sanity-check:

```sh
echo $SHELL                              # → /usr/bin/zsh (or similar)
ls ~/.local/share/zsh/plugins/           # → zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search
ls ~/.config/zsh/                        # → 00-env.zsh, 10-path.zsh, ... (no 40-darwin.zsh on Linux)
zsh -lic 'echo OK; exit'                 # → loader runs without "error sourcing" lines
nvim --headless +q                       # → exits 0, LazyVim plugins install on first real launch
tmux new-session -d 'echo ok' \; kill-server   # → tmux config loads
ls ~/.tmux/plugins/tpm 2>/dev/null && echo "TPM ready"
```

If any step fails, scroll up the bootstrap log — the offending `run_once`
script will be named in the error.

### macOS testing

No throwaway equivalent — `cask` installs (Ghostty, VS Code, fonts) need a
real macOS GUI. Options:

- Use a fresh VM (UTM with macOS, ~30 min provisioning) — most realistic
- Borrow another Mac
- Trust the Brewfile and apply on the next real machine you set up

---

## Stack

| Layer       | Tool                                                                |
| ----------- | ------------------------------------------------------------------- |
| Shell       | zsh + [starship](https://starship.rs/) + 3 plugins ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting), [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)) — no framework |
| Editor      | [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/)  |
| Terminal    | [Ghostty](https://ghostty.org/) (macOS)                             |
| Multiplexer | [tmux](https://github.com/tmux/tmux) + [TPM](https://github.com/tmux-plugins/tpm) and/or [Zellij](https://zellij.dev/) |
| Prompt      | [Starship](https://starship.rs/)                                    |
| Manager     | [chezmoi](https://www.chezmoi.io/)                                  |

---

## Troubleshooting

**`chezmoi diff` shows changes I didn't make.**
Some tools rewrite their own config (LazyVim → `lazy-lock.json`, VS Code
extensions, etc.). Either `chezmoi re-add <file>` to accept the change, or
add the file to `.chezmoiignore` if it's never worth tracking.

**Tool reports "command not found" after fresh apply.**
The `run_once_install-packages` script may have failed silently. Re-run:

```sh
chezmoi apply --refresh-externals --force
```

Then check `brew bundle --file=~/.local/share/chezmoi/Brewfile` (macOS) or
`xargs -a ~/.local/share/chezmoi/packages/apt.txt sudo apt-get install -y`
(Debian).

**Want a one-off override on this machine only.**
Edit `.chezmoiignore` locally — chezmoi respects it without `init` again.

**Forgot the source dir.**
`chezmoi source-path`.

---

## License

Personal config. Most plugin/tool defaults are stock LazyVim /
chezmoi — credit upstream. Feel free to copy anything useful.
