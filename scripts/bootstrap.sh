#!/usr/bin/env bash
# bootstrap.sh — install git/curl + chezmoi, then init+apply this dotfiles repo.
#
# Modes:
#   FULL (default)   Apply dotfiles + run_once installers (Brewfile / apt / dnf
#                    / pacman packages, NodeSource, GitHub CLI repo, rustup,
#                    chsh to zsh). Use on workstations and dev servers — any
#                    machine that wants the language toolchains.
#
#   --minimal        Apply dotfiles + zsh plugins only. Skips run_once scripts:
#                    no Java/Node/Go/Python/Ruby/Rust install, no NodeSource,
#                    no GitHub CLI repo, no chsh. Use on production servers,
#                    jump hosts, restricted accounts, or containers — any
#                    machine that doesn't need a full dev toolchain.
#
# Usage on a fresh machine:
#   curl -fsSL .../scripts/bootstrap.sh | bash                    # full
#   curl -fsSL .../scripts/bootstrap.sh | bash -s -- --minimal    # minimal (arg)
#   curl -fsSL .../scripts/bootstrap.sh | MINIMAL=1 bash          # minimal (env)
#
# Or directly:
#   bash scripts/bootstrap.sh
#   bash scripts/bootstrap.sh --minimal

set -euo pipefail

GITHUB_USER="0xmanhnv"

# --- Mode detection: full (default) or minimal -----------------------------
MINIMAL="${MINIMAL:-0}"
for arg in "$@"; do
  case "$arg" in
    --minimal|-m) MINIMAL=1 ;;
    --full|-f)    MINIMAL=0 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

if [[ "$MINIMAL" == "1" ]]; then
  echo "==> Mode: MINIMAL (dotfiles + zsh plugins only, no toolchains)"
else
  echo "==> Mode: FULL (dotfiles + run_once installers)"
fi

# --- Install git/curl prerequisites ----------------------------------------
echo "==> Detecting OS"
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "==> Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  brew install git curl
elif [[ "$OS" == "Linux" ]]; then
  if [[ -f /etc/debian_version ]]; then
    sudo apt-get update
    sudo apt-get install -y git curl ca-certificates
  elif [[ -f /etc/arch-release ]]; then
    sudo pacman -Sy --noconfirm git curl
  elif [[ -f /etc/fedora-release || -f /etc/redhat-release ]]; then
    sudo dnf install -y git curl
  else
    echo "Unsupported Linux distribution" >&2
    exit 1
  fi
else
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

# --- Install chezmoi + init+apply ------------------------------------------

# In MINIMAL mode, mark this machine as "server" so chezmoiignore drops
# GUI-only configs (Ghostty, etc.) in addition to skipping run_once installers.
if [[ "$MINIMAL" == "1" ]]; then
  mkdir -p "$HOME/.config/chezmoi"
  if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
    cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
# Set by bootstrap.sh --minimal; tells chezmoi this is a headless / server-
# style machine so GUI configs (Ghostty) and similar are filtered via
# .chezmoiignore.
[data]
profile = "server"
EOF
    echo "==> Wrote ~/.config/chezmoi/chezmoi.toml with profile=server"
  fi
fi

echo "==> Installing chezmoi and applying dotfiles"
if [[ "$MINIMAL" == "1" ]]; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --exclude=scripts "$GITHUB_USER"
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$GITHUB_USER"
fi

echo "==> Done. Open a new terminal (or 'exec zsh')."
