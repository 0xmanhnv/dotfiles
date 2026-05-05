# Linux-only config. Skipped on macOS via .chezmoiignore.

# Linuxbrew
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Snap
[[ -d /snap/bin ]] && export PATH="$PATH:/snap/bin"

# Flatpak
[[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && \
  export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
