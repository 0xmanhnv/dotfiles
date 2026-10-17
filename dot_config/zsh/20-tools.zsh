# Tool initializations. Every `source` / `eval` is guarded so a fresh machine
# without these tools won't crash zsh startup.

# Rust / Cargo
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# GVM (Go Version Manager)
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# gvm overrides `cd` and bubbles its internal function name into error
# messages ("__gvm_oldcd:cd: no such file or directory: foo"). Re-wrap
# `cd` to fall through to the builtin with a clean error, but still call
# __gvm_check on success so .go-version auto-switching keeps working.
if (( $+functions[__gvm_oldcd] )); then
  cd() {
    if ! builtin cd "$@" 2>/dev/null; then
      print -u2 "cd: no such file or directory: ${*:-(none)}"
      return 1
    fi
    (( $+functions[__gvm_check] )) && __gvm_check
  }
fi

# jenv (Java) — eager init so JAVA_HOME auto-switches on `cd` in every shell.
# Costs ~50ms at startup; chosen over lazy-load because Java is a daily tool
# and per-project JAVA_HOME hooks need to be active immediately.
if [[ -d "$HOME/.jenv" ]]; then
  export PATH="$HOME/.jenv/bin:$PATH"
  if command -v jenv >/dev/null 2>&1; then
    # The export plugin is what actually sets JAVA_HOME. It's a symlink into
    # the versioned Cellar path, so it dangles after `brew upgrade jenv` —
    # `-e` follows the link, re-enabling only when missing or broken. Must
    # run before `jenv init` so the hook loads in this same shell.
    if [[ ! -e "$HOME/.jenv/plugins/export" ]]; then
      rm -f "$HOME/.jenv/plugins/export"
      jenv enable-plugin export >/dev/null 2>&1
    fi
    eval "$(jenv init -)"
  fi
fi

# RedOS wrappers
[[ -s "$HOME/.redosrc" ]] && source "$HOME/.redosrc"

# zoxide — smarter `cd` (z <fragment> jumps to most-frecent matching dir)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf shell integration (Ctrl-R history, Ctrl-T files, Alt-C cd).
# Modern fzf (>= 0.48, Brew/Arch/Fedora) supports `fzf --zsh`. Older Linux
# packaging (Debian/Ubuntu apt) ships scripts separately under /usr/share/.
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for _fzf_init in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/fzf/completion.zsh \
      /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
      /opt/homebrew/opt/fzf/shell/completion.zsh \
      /usr/local/opt/fzf/shell/key-bindings.zsh \
      /usr/local/opt/fzf/shell/completion.zsh; do
      [[ -r "$_fzf_init" ]] && source "$_fzf_init"
    done
    unset _fzf_init
  fi
fi
