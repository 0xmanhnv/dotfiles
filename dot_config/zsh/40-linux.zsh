# Linux-only config. Skipped on macOS via .chezmoiignore.

# Linuxbrew
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Snap
[[ -d /snap/bin ]] && export PATH="$PATH:/snap/bin"

# Neovim from upstream tarball (run_once installer falls back to this when
# apt has no installation candidate, e.g. on Parrot lory). Only one of these
# directories exists per machine; first match wins.
for _d in /opt/nvim-linux-x86_64/bin /opt/nvim-linux-arm64/bin; do
  [[ -d "$_d" ]] && export PATH="$_d:$PATH" && break
done
unset _d

# Flatpak
[[ -d "$HOME/.local/share/flatpak/exports/bin" ]] && \
  export PATH="$PATH:$HOME/.local/share/flatpak/exports/bin"
