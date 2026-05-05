#!/usr/bin/env bash
# bootstrap-server.sh — Lean bootstrap for Linux servers / SSH-only boxes.
#
# Differs from the workstation one-liner (`scripts/bootstrap.sh`) by:
#   - Installs ONLY shell-level tools: git, zsh, neovim, tmux, fzf, ripgrep,
#     fd, bat, jq, tree, htop, ca-certificates. No language toolchains
#     (Java / Node / Go / Python / Ruby / Rust) — those bloat a server.
#   - chezmoi apply runs with --exclude=scripts so the heavy run_once
#     install scripts (Brewfile, NodeSource, GitHub CLI repo, rustup, chsh)
#     don't fire. Files only.
#   - Degrades gracefully if sudo is denied or chsh fails (common on
#     shared / restricted servers).
#   - Supports apt (Debian/Ubuntu/Kali/Parrot), dnf (Fedora/RHEL/Rocky),
#     pacman (Arch).
#
# Usage on a fresh server:
#   curl -fsSL https://raw.githubusercontent.com/0xmanhnv/dotfiles/main/scripts/bootstrap-server.sh | bash
#
# Or, if curl is also missing:
#   wget -O- https://raw.githubusercontent.com/0xmanhnv/dotfiles/main/scripts/bootstrap-server.sh | bash

set -euo pipefail

GITHUB_USER="0xmanhnv"

# --- Helpers ----------------------------------------------------------------

# Run with sudo if available, otherwise as-is (root container, etc.)
maybe_sudo() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "    (no sudo and not root — skipping: $*)" >&2
    return 1
  fi
}

# --- 1. Install minimal packages -------------------------------------------

OS="$(uname -s)"
if [[ "$OS" != "Linux" ]]; then
  echo "This script is Linux-only. On macOS use scripts/bootstrap.sh instead." >&2
  exit 1
fi

CORE_PACKAGES_APT="git curl wget zsh neovim tmux fzf ripgrep fd-find bat jq tree htop ca-certificates unzip"
CORE_PACKAGES_DNF="git curl wget zsh neovim tmux fzf ripgrep fd-find bat jq tree htop ca-certificates unzip"
CORE_PACKAGES_PACMAN="git curl wget zsh neovim tmux fzf ripgrep fd bat jq tree htop unzip"

echo "==> Detecting distro"
if [[ -f /etc/debian_version ]]; then
  echo "    Debian-based (apt)"
  if maybe_sudo apt-get update -qq; then
    # shellcheck disable=SC2086
    maybe_sudo apt-get install -y -qq $CORE_PACKAGES_APT || \
      echo "    (some packages failed — continuing)"
  fi
elif [[ -f /etc/fedora-release || -f /etc/redhat-release ]]; then
  echo "    Fedora / RHEL-based (dnf)"
  # shellcheck disable=SC2086
  maybe_sudo dnf install -y --skip-unavailable $CORE_PACKAGES_DNF || \
    echo "    (some packages failed — continuing)"
elif [[ -f /etc/arch-release ]]; then
  echo "    Arch-based (pacman)"
  # shellcheck disable=SC2086
  maybe_sudo pacman -Sy --noconfirm --needed $CORE_PACKAGES_PACMAN || \
    echo "    (some packages failed — continuing)"
else
  echo "    Unknown distro — assuming tools already installed" >&2
fi

# --- 2. Install starship to user-space if missing ---------------------------

if ! command -v starship >/dev/null 2>&1; then
  echo "==> Installing starship to ~/.local/bin (user-space, no sudo)"
  mkdir -p "$HOME/.local/bin"
  curl -sSfL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

# --- 3. Clone zsh plugins ---------------------------------------------------

PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

plugins=(
  "zsh-users/zsh-autosuggestions"
  "Aloxaf/fzf-tab"
  "zsh-users/zsh-syntax-highlighting"
  "zsh-users/zsh-history-substring-search"
)

for entry in "${plugins[@]}"; do
  name="${entry##*/}"
  dest="$PLUGIN_DIR/$name"
  if [[ ! -d "$dest" ]]; then
    echo "==> Cloning $entry"
    git clone --depth=1 "https://github.com/$entry.git" "$dest"
  fi
done

# --- 4. Install chezmoi + apply (FILES ONLY, no run_once scripts) -----------

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "==> Installing chezmoi to ~/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "==> chezmoi init + apply (--exclude=scripts to skip heavy installs)"
chezmoi init --apply --exclude=scripts "$GITHUB_USER"

# --- 5. Try to set zsh as default shell, but don't fail if denied -----------

ZSH_PATH="$(command -v zsh || true)"
if [[ -n "$ZSH_PATH" && "$SHELL" != "$ZSH_PATH" ]]; then
  if grep -q "$ZSH_PATH" /etc/shells 2>/dev/null; then
    if chsh -s "$ZSH_PATH" 2>/dev/null; then
      echo "==> Default shell set to $ZSH_PATH"
    else
      echo "==> chsh denied — run 'zsh' manually or 'exec zsh' in each session"
    fi
  else
    echo "==> $ZSH_PATH not in /etc/shells — skipping chsh"
    echo "    Add it manually with: echo '$ZSH_PATH' | sudo tee -a /etc/shells"
  fi
fi

# --- Done -------------------------------------------------------------------

cat <<EOF

==> Server bootstrap complete.

NEXT STEPS

  1. Open zsh:  exec zsh
  2. Verify:    type gst   # → git status alias
                command -v starship && echo OK
                ls ~/.local/share/zsh/plugins/

WHAT YOU GET (lean server profile)

  ✓ zsh + Starship + 4 plugins
  ✓ Modular ~/.config/zsh/*.zsh
  ✓ tmux + TPM (auto-bootstrap on first launch)
  ✓ neovim + LazyVim (plugins clone on first :Lazy sync)
  ✓ Aliases: gst/gco/.., take fn, eza/bat shortcuts

WHAT YOU DON'T GET (vs full workstation bootstrap)

  ✗ Java / Node / Go / Python / Ruby toolchains  (server doesn't need)
  ✗ Rust (rustup)                                 (skipped)
  ✗ GitHub CLI / yq                               (not in apt by default)
  ✗ chsh         — only attempted, not required

  Run them manually if you need:
    apt install nodejs golang-go default-jdk ruby   # etc.
EOF
