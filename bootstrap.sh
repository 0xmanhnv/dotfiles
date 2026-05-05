#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="0xmanhnv"

echo "==> Bootstrap: detecting OS"
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
    sudo apt-get install -y git curl
  elif [[ -f /etc/arch-release ]]; then
    sudo pacman -Sy --noconfirm git curl
  elif [[ -f /etc/fedora-release ]]; then
    sudo dnf install -y git curl
  else
    echo "Unsupported Linux distribution" >&2
    exit 1
  fi
else
  echo "Unsupported OS: $OS" >&2
  exit 1
fi

echo "==> Installing chezmoi and applying dotfiles"
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$GITHUB_USER"

echo "==> Done. Open a new terminal."
