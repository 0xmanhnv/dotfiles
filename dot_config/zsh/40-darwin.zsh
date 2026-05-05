# macOS-only config. Skipped on Linux via .chezmoiignore.
#
# Strategy: use globs to find the latest installed version of each Cellar
# package instead of hard-coding versions. When you `brew upgrade`, paths
# auto-update without editing this file.

# Homebrew (Apple Silicon first, fall back to Intel)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Helper: prepend the bin/ of the latest version of a Cellar package, if installed.
_prepend_cellar_latest() {
  local pkg="$1"
  local latest
  latest=$(/bin/ls -d /opt/homebrew/Cellar/"$pkg"/*/bin 2>/dev/null | sort -V | tail -1)
  [[ -d "$latest" ]] && export PATH="$latest:$PATH"
}

# Pinned-version Cellar tools (preferred over default brew shims)
for pkg in inetutils nginx cloudtrail-cli binutils binwalk rlwrap bison \
           freerdp wireguard-tools gemini-cli neovim 'ruby@3.2'; do
  _prepend_cellar_latest "$pkg"
done

# Special-case rlwrap (its Cellar layout has bin under root, not under bin/)
for d in /opt/homebrew/Cellar/rlwrap/*/; do
  [[ -d "$d" ]] && export PATH="${d%/}:$PATH" && break
done
unset -f _prepend_cellar_latest

# Homebrew opt symlinks (stable paths)
[[ -d /opt/homebrew/opt/python@3.13/bin ]] && export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"
[[ -d /opt/homebrew/opt/openvpn/sbin ]]    && export PATH="/opt/homebrew/opt/openvpn/sbin:$PATH"

# Ruby gems (user)
[[ -d "$HOME/.gem/ruby/3.2.0/bin" ]] && export PATH="$HOME/.gem/ruby/3.2.0/bin:$PATH"

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
if [[ -n "$GHOSTTY_RESOURCES_DIR" && -f "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty.zsh" ]]; then
  source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty.zsh"
fi
