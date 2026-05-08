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
   - `01-install-packages` — `brew bundle` (macOS) or apt / pacman / dnf (Linux) using the `packages/*.txt` lists. Installs zsh, neovim, tmux, eza, bat, fzf, zoxide, ripgrep, fd, jq, gh, starship, language toolchains (openjdk, node, go, python, ruby), and OS-specific extras. On Ubuntu/Debian, NodeSource is set up first so `nodejs` resolves to v24 LTS instead of the apt's old v18.
   - `02-install-zsh-plugins` — clones 4 zsh plugins (`zsh-autosuggestions`, `fzf-tab`, `zsh-syntax-highlighting`, `zsh-history-substring-search`) into `~/.local/share/zsh/plugins/`.
   - `03-install-rust` — runs the official rustup installer (stable toolchain). Skipped if `~/.cargo` already exists.
4. Renders templates (OS-aware) and links every dotfile into place
5. Runs `run_once_after_*` scripts:
   - `02-setup-shell` — `chsh` to zsh. TPM is bootstrapped by `~/.tmux.conf` itself on first tmux launch.

If the machine doesn't have `git`/`curl` yet, run the bootstrap helper:

```sh
curl -fsSL https://raw.githubusercontent.com/0xmanhnv/dotfiles/main/scripts/bootstrap.sh | bash
```

> **On a server, jump host, or restricted account?** Skip the heavy language
> toolchain install with `--minimal` — see [Full vs Minimal mode](#full-vs-minimal-mode).

### On an EXISTING machine that already has its own config

`chezmoi apply` will overwrite files like `~/.zshrc`, `~/.gitconfig`, and
`~/.ssh/config` without backing up. Use the helper scripts:

```sh
chezmoi init --source=$(pwd)              # point chezmoi at your local clone
bash scripts/backup-before-apply.sh       # snapshot files + migrate SSH hosts
chezmoi diff                              # review what changes
chezmoi apply --exclude=scripts           # skip run_once if packages already installed

# If something breaks, in another terminal:
bash scripts/restore-from-backup.sh       # revert from latest backup
```

The backup script also extracts host entries from `~/.ssh/config` into
`~/.ssh/config.local` (untracked) so the catch-all-only `~/.ssh/config` shipped
by the repo doesn't wipe your real hosts.

### Full vs Minimal mode

`bootstrap.sh` accepts a `--minimal` flag for machines that don't need the
full dev toolchain (Java/Node/Go/Python/Ruby/Rust + NodeSource + rustup).

```sh
# FULL (default) — workstations, dev servers, build agents
curl -fsSL .../scripts/bootstrap.sh | bash

# MINIMAL — production servers, jump hosts, restricted accounts, containers
curl -fsSL .../scripts/bootstrap.sh | bash -s -- --minimal
# or
curl -fsSL .../scripts/bootstrap.sh | MINIMAL=1 bash
```

What `--minimal` skips:

|                                    | Full | Minimal |
|------------------------------------|------|---------|
| Dotfiles + zsh modules             | ✓    | ✓       |
| 4 zsh plugins (autosuggest etc.)   | ✓    | ✓       |
| Brewfile / apt / dnf / pacman      | ✓    | ✗ skipped (install zsh, neovim, tmux yourself first) |
| Java/Node/Go/Python/Ruby/Rust      | ✓    | ✗       |
| NodeSource + GitHub CLI repos      | ✓    | ✗       |
| rustup install                     | ✓    | ✗       |
| `chsh` to zsh                      | ✓    | ✗       |
| GUI configs (Ghostty)              | ✓    | ✗ skipped via `profile = "server"` in chezmoi.toml |

`--minimal` also writes `~/.config/chezmoi/chezmoi.toml` with `profile = "server"`
so subsequent `chezmoi apply` keeps skipping desktop-only configs. To later
upgrade a server to a desktop profile (rare on a server, but possible):

```sh
# Edit ~/.config/chezmoi/chezmoi.toml — change profile = "desktop"
chezmoi apply
```

Internally `--minimal` just adds `--exclude=scripts` to `chezmoi update`,
so all `run_once_*` scripts are skipped. Add toolchains later if needed:
```sh
sudo apt install nodejs golang-go default-jdk ruby   # Debian/Ubuntu/Kali
```

### Nerd Font fallback

The starship prompt OS icons and clock glyph, the Ghostty `font-family`,
and the eza-based fzf-tab previews all rely on Nerd Font codepoints. The
default `nerd_font: true` matches the primary workstation (Brewfile installs
`font-jetbrains-mono-nerd-font` on macOS; the Linux `run_once` fetches
JetBrainsMono from the official Nerd Fonts release).

On a machine where the terminal can't render Nerd Font (plain xterm, Linux
console, some SSH clients, WSL when the Windows Terminal font isn't a
Nerd Font), opt out:

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
nerd_font = false
```

Then `chezmoi apply`. Starship's OS icon falls back to plain distro names
(`mac`, `arch`, `debian`…), the clock prefix and folder substitutions are
dropped, fzf-tab previews drop `--icons`, and Ghostty's `font-family` falls
back to plain `JetBrains Mono`. The `eza` aliases (`ls`/`ll`/`la`/`lt`/
`tree`) never request `--icons` regardless of this flag — pass `--icons`
ad hoc when you want them.

---

## What's inside

```
.
├── .editorconfig                      Editor defaults (indent, charset, EOL)
├── .gitignore                         Repo metadata (OS cruft, editor swap, chezmoi local data)
├── .github/workflows/ci.yml           shellcheck + chezmoi bootstrap on Ubuntu / Fedora / Kali
│
├── scripts/
│   ├── bootstrap.sh                   Pre-flight installer (git/curl + chezmoi); supports --minimal
│   ├── backup-before-apply.sh         Snapshot files chezmoi would overwrite + migrate SSH hosts
│   ├── restore-from-backup.sh         Revert from a backup dir (counterpart to backup script)
│   ├── migrate-omz-to-starship.sh     One-shot OMZ → Starship migration on a live machine
│   └── zshrc.local.example            Template for ~/.zshrc.local (per-machine overrides)
│
├── Brewfile                           macOS packages (`brew bundle`)
├── packages/
│   ├── apt.txt                        Debian / Ubuntu
│   ├── pacman.txt                     Arch
│   └── dnf.txt                        Fedora
│
├── .chezmoidata.yaml                  Variables (name, email, github_user)
├── .chezmoiignore                     Per-OS file filters
│
├── dot_zshrc                          Loader: pure zsh + Starship + 4 plugins (no OMZ)
├── dot_zshenv                         Pre-shell PATH (cargo, foundry — both guarded)
├── dot_gitconfig.tmpl                 Git config (templated identity, points at ~/.gitignore_global)
├── dot_gitignore_global               Patterns ignored in EVERY git repo (.DS_Store, IDE state, *.local, ...)
├── dot_tmux.conf                      tmux + auto-install TPM
│
├── dot_config/
│   ├── nvim/                          LazyVim distro + snacks dashboard (Buddha banner)
│   ├── ghostty/config                 macOS — terminal emulator
│   ├── starship.toml                  Custom Catppuccin Mocha prompt
│   ├── zellij/config.kdl              Multiplexer (alternative to tmux)
│   └── zsh/                           Modular shell config (see below)
│
├── private_dot_ssh/config.tmpl        SSH client (0600, Include config.local for hosts)
│
└── run_once_*.sh.tmpl                 Idempotent setup scripts (packages, plugins, rustup, chsh)
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

| File             | Purpose                                                                                           |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| `00-env.zsh`     | Cross-OS env vars (`HOMEBREW_NO_*`, `JAVA_TOOL_OPTIONS`, `PYTHONDONTWRITEBYTECODE`)               |
| `10-path.zsh`    | Common PATH entries (`~/.local/bin`, `~/go/bin`) — all guarded with `[[ -d ]]`                    |
| `20-tools.zsh`   | Tool init: cargo, gvm, jenv (eager), redos, **zoxide** (`z`), **fzf** keybindings (Ctrl-R / T / Alt-C) |
| `30-aliases.zsh` | `ls/ll/lt` (eza), `cat` (bat), `..` `...`, `take` fn, term-title hooks, 20 git aliases            |
| `40-darwin.zsh`  | macOS only: Homebrew Cellar globs, Android SDK, Ghostty integration                               |
| `40-linux.zsh`   | Linux only: Linuxbrew, snap, flatpak                                                              |

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
- Loader uses `null_glob` so an empty `~/.config/zsh/` doesn't error. Real
  syntax errors are still printed by zsh itself with file:line, so the loader
  doesn't wrap `source` with a custom reporter (it would false-fire on files
  that legitimately end on a falsey conditional).
- `compinit` cached daily — full re-build only runs if `~/.zcompdump` is older
  than 24 hours.
- `40-darwin.zsh` detects `BREW_PREFIX` (`/opt/homebrew` on Apple Silicon,
  `/usr/local` on Intel) so all Cellar/opt globs work on both arches.

### fzf-tab UX

Tab completion is replaced by an fzf picker with type-aware preview:

| Trigger              | Preview                                   |
| -------------------- | ----------------------------------------- |
| `cd <Tab>`, `z <Tab>` | `eza` listing of the candidate directory  |
| Generic file complete | `bat` line-range render, falls back to eza |
| `kill <Tab>`, `ps <Tab>` | `ps -o pid,cmd -p $word`               |
| `git add/diff/restore` | live `git diff --color` preview         |
| `git checkout/switch/branch` | `git log --oneline --graph -20`   |

Tab key bound to `accept` so a single tab confirms.

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

|                              | macOS                                  | Linux                |
| ---------------------------- | -------------------------------------- | -------------------- |
| CPU arch                     | Apple Silicon + Intel (both supported) | x86_64 / arm64       |
| Brew prefix                  | `/opt/homebrew` or `/usr/local` (auto) | (Linuxbrew opt-in)   |
| Package manager              | Homebrew (`Brewfile`)                  | apt / pacman / dnf   |
| Default terminal             | Ghostty (config tracked)               | (your choice)        |
| `40-darwin.zsh`              | Loaded                   | Skipped              |
| `40-linux.zsh`               | Skipped                  | Loaded               |
| Cellar version pinning       | Auto via glob            | N/A                  |
| Git credential helper        | `osxkeychain`            | `cache --timeout`    |
| SSH `UseKeychain`            | Yes                      | No                   |
| Java LTS                     | openjdk@25 (latest LTS)  | openjdk-21 (broader distro support) |
| Node 24 LTS source           | Homebrew                 | NodeSource on Ubuntu/Debian; rolling repo on Kali/Parrot |

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
  chezmoi --source=/dotfiles apply
'
```

This bypasses GitHub entirely — chezmoi reads source files straight from the
mounted dir.

> Pass `--source` on every chezmoi invocation rather than `chezmoi init
> --source=DIR`. The `init` flag doesn't reliably persist `sourceDir` into
> `~/.config/chezmoi/chezmoi.toml` when no remote URL is given, so subsequent
> `apply` falls back to the default `~/.local/share/chezmoi`.

### What to verify after install completes

Inside the container after the script returns, sanity-check:

```sh
echo $SHELL                              # → /usr/bin/zsh (or similar)
ls ~/.local/share/zsh/plugins/           # → zsh-autosuggestions, fzf-tab, zsh-syntax-highlighting, zsh-history-substring-search
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
| Shell       | zsh + [starship](https://starship.rs/) + 4 plugins ([zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [fzf-tab](https://github.com/Aloxaf/fzf-tab), [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting), [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)) — no framework |
| Editor      | [Neovim](https://neovim.io/) + [LazyVim](https://www.lazyvim.org/) + [snacks.nvim](https://github.com/folke/snacks.nvim) explorer/dashboard/picker |
| Terminal    | [Ghostty](https://ghostty.org/) (macOS) — Catppuccin Mocha theme    |
| Multiplexer | [tmux](https://github.com/tmux/tmux) + [TPM](https://github.com/tmux-plugins/tpm), and/or [Zellij](https://zellij.dev/) |
| Prompt      | [Starship](https://starship.rs/) — custom Catppuccin Mocha config (info-rich, no segments) |
| CLI tools   | [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat), [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [zoxide](https://github.com/ajeetdsouza/zoxide), [jq](https://jqlang.org/), [gh](https://cli.github.com/) |
| Languages   | Java (openjdk@25 macOS / 21 LTS Linux) + jenv, Node 24 LTS, Go latest, Python 3.13, Ruby 3.4, Rust stable (rustup) |
| Manager     | [chezmoi](https://www.chezmoi.io/)                                  |

---

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to
`main` and on PRs:

| Job                  | What it tests                                                  |
| -------------------- | -------------------------------------------------------------- |
| `shellcheck`         | All `scripts/*.sh` lint clean (excl. SC1090/SC1091 dynamic source) |
| `bootstrap-ubuntu`   | Full `chezmoi apply` inside `ubuntu:24.04` Docker, then loads zsh and verifies aliases / plugins / starship / TPM |
| `bootstrap-fedora`   | Full apply inside `fedora:latest` (dnf branch + `--skip-unavailable`) |
| `bootstrap-kali`     | Full apply inside `kalilinux/kali-rolling` (Debian branch, NodeSource auto-skipped via `/etc/os-release` ID check) |

This catches regressions like "OMZ install runs before zsh is installed" or
"NodeSource conflicts with apt's `npm`" before they hit a real machine.

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
