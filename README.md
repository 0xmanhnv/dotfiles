# dotfiles

Personal development environment for **macOS** and **Linux**, bootstrapped on a
fresh machine in one command. Managed with [chezmoi](https://www.chezmoi.io).

---

## Quick start

On a brand-new machine:

```sh
sh -c "$(curl --proto '=https' -fsLS https://get.chezmoi.io)" -- init --apply 0xmanhnv
```

What that does, in order:

1. Installs the `chezmoi` binary
2. Clones this repo into `~/.local/share/chezmoi`
3. Runs the `before` scripts:
   - `run_onchange_before_01-install-packages` — `brew bundle` (macOS) or apt / pacman / dnf (Linux) using the `packages/*.txt` lists. It embeds a hash of this OS's package lists, so it **re-runs whenever you edit the Brewfile / `packages/*.txt`** (idempotent; `brew bundle --no-upgrade`). Installs zsh, neovim, tmux, eza, bat, fzf, zoxide, ripgrep, fd, jq, gh, starship, language toolchains (openjdk, node, go, python, ruby), and OS-specific extras. On Ubuntu/Debian, NodeSource is set up first so `nodejs` resolves to v24 LTS instead of the apt's old v18.
   - `run_once_before_03-install-rust` — runs the official rustup installer (stable toolchain). Skipped if `~/.cargo` already exists.
4. Renders templates (OS-aware) and links every dotfile into place. The 4 zsh
   plugins (`zsh-autosuggestions`, `fzf-tab`, `zsh-syntax-highlighting`,
   `zsh-history-substring-search`) come from `.chezmoiexternal.toml` into
   `~/.local/share/zsh/plugins/` and are fast-forwarded weekly
   (`chezmoi apply --refresh-externals` to force).
5. Runs `run_once_after_*` scripts:
   - `02-setup-shell` — `chsh` to zsh. TPM and the tmux plugins are externals (cloned with the zsh plugins).

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
(`mac`, `arch`, `debian`…), the clock prefix is dropped, fzf-tab previews drop `--icons`, and Ghostty's `font-family` falls
back to plain `JetBrains Mono`. The `eza` aliases (`ls`/`ll`/`la`/`lt`/
`tree`) never request `--icons` regardless of this flag — pass `--icons`
ad hoc when you want them.

### Slow-terminal mode

If typing feels laggy and characters double up or drop on a particular
machine — typically code-server's browser xterm.js, SSH over high-RTT
links, or a low-CPU VM — opt the heavy `zsh-syntax-highlighting` plugin
out:

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
slow_terminal = true
```

`zsh-autosuggestions` stays on but runs async (set globally for everyone
since async has no downside). The default `slow_terminal: false` keeps
the full plugin set on workstations where there's plenty of CPU and a
local terminal.

### Pentest mode

The base package lists are dev-focused. Offensive-security tooling (nmap,
ffuf, sqlmap, hashcat, john, ghidra, burp-suite, radare2, mitmproxy,
exiftool, tcpdump, …) lives in separate lists and only installs when
explicitly opted in:

```toml
# ~/.config/chezmoi/chezmoi.toml
[data]
pentest = true
```

Then `chezmoi apply` re-runs the install script, which layers
`Brewfile.pentest` on macOS or `packages/{apt,dnf,pacman}.pentest.txt`
on Linux on top of the base lists. Default `pentest: false` keeps
dev-only machines lean.

Python tooling (impacket, NetExec, responder) isn't in package repos —
install with `pipx` once, then they auto-update via `pipx upgrade-all`:

```sh
pipx install impacket
pipx install git+https://github.com/Pennyw0rth/NetExec
```

### Docker

Container runtime is included in every OS list (always installed):

| OS                | Tool                                      |
| ----------------- | ----------------------------------------- |
| macOS             | Docker Desktop (`cask "docker-desktop"`)  |
| Debian/Ubuntu/Kali| `docker.io docker-compose-v2 docker-buildx` |
| Fedora            | `moby-engine docker-compose`              |
| Arch              | `docker docker-compose docker-buildx`     |

On Linux the install script runs `systemctl enable --now docker` and adds
the current user to the `docker` group automatically — log out / `newgrp
docker` for the group change to take effect in the active shell. On
macOS, launch Docker Desktop once after install to finish its setup.

Docker Desktop over OrbStack: OrbStack is lighter and faster, but Docker
Desktop is the reference engine everything is tested against. If Docker.app
was installed from the .dmg, the Brewfile skips the cask (brew would refuse
to overwrite the app); `brew install --cask --force docker-desktop` hands it
over to brew, which then also links the zsh completions.

### SSH terminfo on remote hosts

`$TERM=xterm-ghostty` (and Kitty's `xterm-kitty`, WezTerm's `wezterm`,
etc.) isn't in the default terminfo database on most servers. Without
a matching entry the remote shell mis-counts character widths and you
see duplicated keystrokes / garbled prompts.

Ghostty's `shell-integration-features = ssh-terminfo` (configured in
`dot_config/ghostty/config.tmpl`) auto-installs the entry the first
time you SSH into a host — most new servers Just Work.

For hosts that miss the auto-install (older Ghostty version, SSH
through tmux pass-through, non-Ghostty terminals, servers without
`tic`), the `ssh-fix-term` helper in `dot_config/zsh/30-aliases.zsh`
does it manually — once per host, permanent:

```sh
ssh-fix-term kali@kali
ssh-fix-term root@10.0.0.5
```

It pipes the local `$TERM`'s terminfo via SSH and runs `tic -x -` on
the remote. Requires `infocmp` locally (macOS ships it; Linux pulls
`ncurses-bin` / `ncurses` from the base package lists) and `tic` on
the remote (same package, same name).

---

## What's inside

```
.
├── .editorconfig                      Editor defaults (indent, charset, EOL)
├── .gitignore                         Repo metadata (OS cruft, editor swap, chezmoi local data)
├── .github/workflows/ci.yml           lint + chezmoi bootstrap on Ubuntu / Fedora / Kali / Debian + macOS minimal
│
├── scripts/
│   ├── bootstrap.sh                   Pre-flight installer (git/curl + chezmoi); supports --minimal
│   ├── backup-before-apply.sh         Snapshot files chezmoi would overwrite + migrate SSH hosts
│   ├── restore-from-backup.sh         Revert from a backup dir (counterpart to backup script)
│   ├── migrate-omz-to-starship.sh     One-shot OMZ → Starship migration on a live machine
│   └── zshrc.local.example            Template for ~/.zshrc.local (per-machine overrides)
│
├── Brewfile                           macOS packages (`brew bundle`)
├── Brewfile.pentest                   macOS pentest toolkit (only used when pentest = true)
├── packages/
│   ├── apt.txt                        Debian / Ubuntu (base)
│   ├── pacman.txt                     Arch (base)
│   ├── dnf.txt                        Fedora (base)
│   └── *.pentest.txt                  Per-OS offensive-security toolkit (only used when pentest = true)
│
├── .chezmoidata.yaml                  Variables (identity + nerd_font / slow_terminal / pentest / profile flags)
├── .chezmoiignore                     Per-OS file filters
├── .chezmoiexternal.toml              zsh plugins (git repos, weekly refresh)
│
├── dot_zshrc.tmpl                     Loader: pure zsh + Starship + 4 plugins (gates fzf-tab --icons + syntax-highlighting via flags)
├── dot_zshenv                         Pre-shell PATH (cargo, foundry — both guarded) + TERM safety fallback
├── dot_gitconfig.tmpl                 Git config (templated identity, delta, includes ~/.gitconfig.local)
├── dot_gitignore_global               Patterns ignored in EVERY git repo (.DS_Store, IDE state, *.local, ...)
├── dot_tmux.conf                      tmux + TPM (plugins via externals), Catppuccin status following light/dark
│
├── dot_config/
│   ├── nvim/                          LazyVim distro + catppuccin (auto light/dark) + snacks dashboard
│   ├── ghostty/config.tmpl            Cross-OS terminal emulator (font gated by nerd_font)
│   ├── starship.toml.tmpl             Custom Catppuccin Mocha prompt (OS/clock glyphs gated by nerd_font)
│   └── zsh/                           Modular shell config (see below)
│
├── private_dot_ssh/config.tmpl        SSH client (0600, Include config.local, IdentitiesOnly, multiplexing)
│
└── run_*.sh.tmpl                      Idempotent setup scripts (packages on change; rustup, chsh once)
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

`~/.zshrc` is a small **loader**. The real config lives in
`~/.config/zsh/*.zsh`, sourced in lexical order:

| File             | Purpose                                                                                           |
| ---------------- | ------------------------------------------------------------------------------------------------- |
| `00-env.zsh`     | Cross-OS env vars (`HOMEBREW_NO_*`, `JAVA_TOOL_OPTIONS`, `PYTHONDONTWRITEBYTECODE`), bat/delta light/dark theme |
| `05-brew.zsh`    | Homebrew / Linuxbrew `shellenv` + keg-only formulae via `opt/` symlinks. Loads **before** version managers |
| `10-path.zsh`    | Common PATH entries (`~/go/bin`) — guarded with `[[ -d ]]`                                         |
| `20-tools.zsh`   | Tool init: gvm (lazy), jenv (hand-rolled, JAVA_HOME on `cd`), redos, **zoxide** (`z`), **fzf** keybindings (Ctrl-R / T / Alt-C) |
| `30-aliases.zsh` | `ls/ll/lt` (eza), `cat` (bat), `..` `...`, `take` fn, term-title hooks, 20 git aliases            |
| `40-darwin.zsh`  | macOS only: GNU inetutils/binutils, Android SDK, Metasploit/Sliver/LM Studio paths                |
| `40-linux.zsh`   | Linux only: snap, flatpak, upstream nvim tarball                                                  |

OS-specific files are filtered by `.chezmoiignore`, so on Linux the macOS
file isn't even rendered to disk.

### Why modular?

1. **Adding a tool** is a 1-file edit, not "scroll through 250-line zshrc".
2. **`git diff`** stays per-topic.
3. **OS isolation** is structural (filename), not runtime conditionals.
4. **No versioned paths** — keg-only formulae go through Homebrew's
   `opt/<formula>` symlinks, so `brew upgrade` never breaks PATH.

### Machine-specific overrides

Anything truly local goes in an untracked file that `chezmoi apply` never
touches:

| File                 | For                                                       |
| -------------------- | --------------------------------------------------------- |
| `~/.zshrc.local`     | API keys, employer-specific paths (sourced last)          |
| `~/.gitconfig.local` | Work email, signing key, extra credential helpers (`[include]`d last) |
| `~/.ssh/config.local`| Real hosts (`Include`d before the `Host *` defaults)      |

### Performance notes

- Startup is ~0.14s on an M-series Mac (was ~0.65s). Measure with
  `for i in {1..5}; do /usr/bin/time zsh -lic exit; done`, profile with
  `zmodload zsh/zprof` at the top of `~/.zshrc` + `zprof` at the bottom.
- `jenv` doesn't use `jenv init -`: that rehashes on every start, and its
  export plugin forks `jenv javahome` in **precmd** — ~50ms after every
  command. `20-tools.zsh` recomputes `JAVA_HOME` on `cd` and after `jenv …`.
  After installing a new JDK: `jenv add "$(brew --prefix openjdk@25)"`.
- `gvm`'s main script (~200ms) loads on first `gvm …`; the default Go
  environment is exported eagerly. Since Go 1.21 the `toolchain` line in
  `go.mod` makes most per-project gvm switching unnecessary.
- Homebrew loads before gvm/jenv so their `go`/`java` win over brew's —
  otherwise `go build` fails with a GOROOT/toolchain version mismatch.
- `PATH`/`FPATH` are deduplicated (`typeset -U` + `path=($path)`), so nested
  shells (tmux panes, nvim `:terminal`) don't keep growing them.
- Loader uses `null_glob` so an empty `~/.config/zsh/` doesn't error. Real
  syntax errors are still printed by zsh itself with file:line, so the loader
  doesn't wrap `source` with a custom reporter (it would false-fire on files
  that legitimately end on a falsey conditional).
- `compinit` trusts its cache (`-C`) unless `~/.zcompdump` is >24h old, the
  set of fpath dirs changed, or a fpath dir is newer than the dump (a new
  `brew install` dropped a completion). Brew's `site-functions` is put on
  fpath before compinit so `gh`/`brew`/`chezmoi` completions load.

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
| Keg-only formula paths       | `opt/` symlinks (version-free) | N/A            |
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
  sh -c "$(curl --proto '=https' -fsLS https://get.chezmoi.io)" -- init --apply 0xmanhnv
'
```

Takes ~5–10 minutes. The container is wiped on exit, no cleanup needed.
Swap `ubuntu:24.04` for `archlinux:latest` or `fedora:latest` to test the
other distro paths in `run_onchange_before_01-install-packages.sh.tmpl`.

> **Private repo?** This needs `chezmoi init` to be able to clone via HTTPS or
> SSH. Either make the repo public for the test, mount a PAT into the
> container (`-e GITHUB_TOKEN=...`), or use Option B instead.

### Option B — test the local source (no push needed)

Useful while iterating on the source dir before pushing:

```sh
docker run -it --rm -v "$PWD:/dotfiles:ro" ubuntu:24.04 bash -c '
  apt-get update -qq && apt-get install -y -qq curl sudo git
  sh -c "$(curl --proto '=https' -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
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
| Terminal    | [Ghostty](https://ghostty.org/) (macOS) — Catppuccin, Mocha/Latte following OS appearance |
| Multiplexer | [tmux](https://github.com/tmux/tmux) + [TPM](https://github.com/tmux-plugins/tpm) — see [docs/nvim-tmux.md](docs/nvim-tmux.md) for the Neovim+tmux workflow |
| Prompt      | [Starship](https://starship.rs/) — custom Catppuccin Mocha config (info-rich, no segments) |
| Theme       | Catppuccin everywhere: Ghostty, Neovim (`flavour = "auto"`), tmux (3.6+ theme hooks), delta, bat — dark = Mocha, light = Latte |
| CLI tools   | [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat), [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf), [zoxide](https://github.com/ajeetdsouza/zoxide), [jq](https://jqlang.org/), [gh](https://cli.github.com/) |
| Languages   | Java (openjdk@25 macOS / 21 LTS Linux) + jenv, Node 24 LTS, Go latest, Python 3.13, Ruby 3.4, Rust stable (rustup) |
| Manager     | [chezmoi](https://www.chezmoi.io/)                                  |

---

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to
`main` and on PRs:

| Job                  | What it tests                                                  |
| -------------------- | -------------------------------------------------------------- |
| `lint`               | shellcheck on `scripts/*.sh` **and** the rendered `run_*` scripts, `zsh -n` on every zsh file, `tmux source-file -n` |
| `macos-minimal`      | `apply --exclude=scripts` on macOS (= `--minimal`): plugins via externals, zsh starts with no errors, no PATH duplicates |
| `bootstrap-ubuntu`   | Full `chezmoi apply` inside `ubuntu:24.04` Docker, then loads zsh and verifies aliases / plugins / starship / nvim / delta |
| `bootstrap-fedora`   | Full apply inside `fedora:latest` (dnf branch + `--skip-unavailable`) |
| `bootstrap-kali`     | Full apply inside `kalilinux/kali-rolling` (Debian branch, NodeSource auto-skipped via `/etc/os-release` ID check) |
| `bootstrap-debian-bookworm` | Full apply on Debian 12 — exercises the eza/zoxide/yq/nvim/font fallback installers |
| `template-nerd-font-false`  | Renders templates with `nerd_font: false` and asserts the ASCII branch |

Every assertion goes through a `check` helper that fails the job — a bare
`test … && echo ✓` would silently pass.

This catches regressions like "OMZ install runs before zsh is installed" or
"NodeSource conflicts with apt's `npm`" before they hit a real machine.

---

## Troubleshooting

**`chezmoi diff` shows changes I didn't make.**
Some tools rewrite their own config (LazyVim → `lazy-lock.json`, VS Code
extensions, etc.). Either `chezmoi re-add <file>` to accept the change, or
add the file to `.chezmoiignore` if it's never worth tracking.

**Tool reports "command not found" after fresh apply.**
The package install script may have failed. It re-runs on its own whenever
the package lists change; to force it without editing a list, clear
chezmoi's record of run_onchange scripts and apply again:

```sh
chezmoi state delete-bucket --bucket=entryState   # forget script hashes
chezmoi apply
```

Or run the installer directly: `brew bundle --file=~/.local/share/chezmoi/Brewfile` (macOS) or
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
