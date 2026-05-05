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
3. Renders templates (OS-aware) and links every dotfile into place
4. Runs `run_once_*` scripts:
   - Installs Homebrew + `Brewfile` packages (macOS) or apt/pacman/dnf packages (Linux)
   - Sets `zsh` as the default shell
   - Clones [TPM](https://github.com/tmux-plugins/tpm) so tmux plugins auto-install on first launch

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
├── dot_zshrc                          Loader: banner + OMZ + glob-source modules
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

## Stack

| Layer       | Tool                                                                |
| ----------- | ------------------------------------------------------------------- |
| Shell       | zsh + [oh-my-zsh](https://ohmyz.sh/) + [starship](https://starship.rs/) |
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

Personal config. Most plugin/tool defaults are stock LazyVim / oh-my-zsh /
chezmoi — credit upstream. Feel free to copy anything useful.
