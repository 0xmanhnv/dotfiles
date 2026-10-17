# Cross-OS environment variables.

# Homebrew behavior
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTO_UPDATE=1

# Java
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Python
export PYTHONDONTWRITEBYTECODE=1

# Catppuccin everywhere (Ghostty, Neovim, tmux, starship, delta, bat),
# following the OS light/dark mode. bat (>= 0.25) detects the terminal
# background itself and picks one of these two:
export BAT_THEME_DARK="Catppuccin Mocha"
export BAT_THEME_LIGHT="Catppuccin Latte"
# delta can't pick per mode, so switch its feature set here (read once per
# shell: open a new tab after flipping the OS appearance). macOS reports
# AppleInterfaceStyle=Dark only in dark mode; elsewhere assume dark.
if [[ "$OSTYPE" == darwin* ]] && \
   [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" != "Dark" ]]; then
  export DELTA_FEATURES="+catppuccin-latte"
fi
