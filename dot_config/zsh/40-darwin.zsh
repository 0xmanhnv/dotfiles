# macOS-only config. Skipped on Linux via .chezmoiignore.
#
# Formulae that brew links into $BREW_PREFIX/bin (neovim, nginx, binwalk,
# rlwrap, freerdp, wireguard-tools, ...) need nothing here.

# Homebrew itself (shellenv + keg-only formulae) loads earlier, from
# 05-brew.zsh. What's left here are macOS-only tweaks on top of it.
if [[ -n "${BREW_PREFIX:-}" ]]; then
  # GNU inetutils: unprefixed ftp / telnet / ping / ... (pentest workflows).
  [[ -d "$BREW_PREFIX/opt/inetutils/libexec/gnubin" ]] && \
    export PATH="$BREW_PREFIX/opt/inetutils/libexec/gnubin:$PATH"

  # GNU binutils is keg-only on purpose: its ar / ranlib / strip / nm shadow
  # Apple's and break Xcode / cargo / cc builds. APPEND it, so GNU-only tools
  # (readelf, objdump, addr2line, ...) are available without shadowing.
  [[ -d "$BREW_PREFIX/opt/binutils/bin" ]] && export PATH="$PATH:$BREW_PREFIX/opt/binutils/bin"
fi

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
