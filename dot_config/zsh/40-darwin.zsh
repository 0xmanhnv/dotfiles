# macOS-only config. Skipped on Linux via .chezmoiignore.
#
# Strategy: use globs to find the latest installed version of each Cellar
# package instead of hard-coding versions. When you `brew upgrade`, paths
# auto-update without editing this file.

# Detect Brew prefix: Apple Silicon = /opt/homebrew, Intel = /usr/local.
# All paths below resolve through $BREW_PREFIX so the file works on both.
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW_PREFIX=/opt/homebrew
elif [[ -x /usr/local/bin/brew ]]; then
  BREW_PREFIX=/usr/local
fi

if [[ -n "${BREW_PREFIX:-}" ]]; then
  eval "$($BREW_PREFIX/bin/brew shellenv)"
fi

# Helper: prepend the bin/ of the latest version of a Cellar package, if installed.
_prepend_cellar_latest() {
  local pkg="$1"
  local latest
  latest=$(/bin/ls -d "$BREW_PREFIX/Cellar/$pkg"/*/bin 2>/dev/null | sort -V | tail -1)
  [[ -d "$latest" ]] && export PATH="$latest:$PATH"
}

# Pinned-version Cellar tools (preferred over default brew shims)
if [[ -n "${BREW_PREFIX:-}" ]]; then
  for pkg in inetutils nginx binutils binwalk rlwrap bison \
             freerdp wireguard-tools neovim 'ruby@3.4'; do
    _prepend_cellar_latest "$pkg"
  done

  # Special-case rlwrap (its Cellar layout has bin under root, not under bin/)
  for d in "$BREW_PREFIX/Cellar/rlwrap"/*/; do
    [[ -d "$d" ]] && export PATH="${d%/}:$PATH" && break
  done

  # Homebrew opt symlinks (keg-only formulas need explicit PATH)
  [[ -d "$BREW_PREFIX/opt/python@3.13/bin" ]] && export PATH="$BREW_PREFIX/opt/python@3.13/bin:$PATH"
  [[ -d "$BREW_PREFIX/opt/openjdk@25/bin" ]]  && export PATH="$BREW_PREFIX/opt/openjdk@25/bin:$PATH"
  [[ -d "$BREW_PREFIX/opt/node@24/bin" ]]     && export PATH="$BREW_PREFIX/opt/node@24/bin:$PATH"
  [[ -d "$BREW_PREFIX/opt/openvpn/sbin" ]]    && export PATH="$BREW_PREFIX/opt/openvpn/sbin:$PATH"
fi
unset -f _prepend_cellar_latest 2>/dev/null

# Ruby gems (user) — bumped to ruby 3.4
[[ -d "$HOME/.gem/ruby/3.4.0/bin" ]] && export PATH="$HOME/.gem/ruby/3.4.0/bin:$PATH"

# Metasploit
[[ -d /opt/metasploit-framework/bin ]] && export PATH="/opt/metasploit-framework/bin:$PATH"

# Sliver C2
[[ -d "$HOME/Data/Tools/sliver/bin" ]] && export PATH="$HOME/Data/Tools/sliver/bin:$PATH"

# LM Studio
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"

# Windsurf (Codeium)
[[ -d "$HOME/.codeium/windsurf/bin" ]] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# Antigravity
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# pdtm (ProjectDiscovery Tool Manager)
[[ -d "$HOME/.pdtm/go/bin" ]] && export PATH="$PATH:$HOME/.pdtm/go/bin"

# Android SDK
if [[ -d "$HOME/Library/Android/sdk" ]]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export ANDROID_SDK_ROOT="$ANDROID_HOME"
  [[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
  [[ -d "$ANDROID_HOME/platform-tools" ]]           && export PATH="$ANDROID_HOME/platform-tools:$PATH"
  for d in "$ANDROID_HOME/build-tools/"*; do
    [[ -d "$d" ]] && export PATH="$d:$PATH" && break
  done
fi

# Ghostty shell integration (Ghostty exports GHOSTTY_RESOURCES_DIR when launching zsh)
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" && -f "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty.zsh" ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty.zsh"
fi
