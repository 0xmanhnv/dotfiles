# Tool initializations. Every `source` / `eval` is guarded so a fresh machine
# without these tools won't crash zsh startup.

# Rust / Cargo: ~/.cargo/env is sourced from ~/.zshenv (every zsh, not just
# interactive ones), so nothing to do here.

# GVM (Go Version Manager) — lazy. Sourcing gvm's main script costs ~200ms
# (it runs `cd .` through its own cd wrapper to resolve .go-version). The
# default environment file is plain exports (GOROOT / GOPATH / PATH), so
# load just that eagerly; the real `gvm` command and its .go-version
# auto-switch on `cd` load on first `gvm ...` call.
#
# Most projects don't need gvm anymore: since Go 1.21 the `toolchain` line
# in go.mod makes `go` download and run the right version by itself.
if [[ -s "$HOME/.gvm/scripts/gvm" ]]; then
  export GVM_ROOT="$HOME/.gvm"
  [[ -s "$GVM_ROOT/environments/default" ]] && source "$GVM_ROOT/environments/default"

  gvm() {
    unfunction gvm
    source "$GVM_ROOT/scripts/gvm"
    # gvm overrides `cd` and bubbles its internal function name into error
    # messages ("__gvm_oldcd:cd: no such file or directory: foo"). Re-wrap
    # `cd` to fall through to the builtin with a clean error, but still
    # call __gvm_check on success so .go-version auto-switching works.
    if (( $+functions[__gvm_oldcd] )); then
      cd() {
        if ! builtin cd "$@" 2>/dev/null; then
          print -u2 "cd: no such file or directory: ${*:-(none)}"
          return 1
        fi
        (( $+functions[__gvm_check] )) && __gvm_check
      }
    fi
    gvm "$@"
  }
fi

# jenv (Java) — hand-rolled equivalent of `eval "$(jenv init -)"` plus the
# export plugin, minus its two costs:
#   1. `jenv rehash` + `jenv refresh-plugins` on every shell start (~100ms).
#      Only needed after adding a JDK, and `jenv add` rehashes by itself.
#   2. The export plugin's *precmd* hook, which forks `jenv javahome`
#      (~50ms) after EVERY command you run.
# JAVA_HOME can only change when the directory changes (.java-version) or
# the jenv version changes, so recompute on chpwd and after `jenv ...`.
if command -v jenv >/dev/null 2>&1; then
  [[ -d "$HOME/.jenv/bin" ]] && export PATH="$HOME/.jenv/bin:$PATH"
  export PATH="$HOME/.jenv/shims:$PATH"
  export JENV_SHELL=zsh JENV_LOADED=1 JENV_FORCEJAVAHOME=true

  _jenv_set_java_home() {
    local java_home
    java_home="$(command jenv javahome 2>/dev/null)"
    if [[ -n "$java_home" ]]; then
      export JAVA_HOME="$java_home"
    else
      unset JAVA_HOME
    fi
    if [[ -n "${JAVA_HOME:-}" && -e "$JAVA_HOME/bin/javac" ]]; then
      export JDK_HOME="$JAVA_HOME" JENV_FORCEJDKHOME=true
    else
      unset JDK_HOME
    fi
  }

  # Same dispatcher `jenv init` emits: `jenv shell` etc. must eval in this
  # shell to take effect.
  jenv() {
    local cmd="${1:-}" ret
    (( $# )) && shift
    case "$cmd" in
      enable-plugin|rehash|shell|shell-options)
        eval "$(command jenv "sh-$cmd" "$@")" ;;
      *)
        command jenv "$cmd" "$@" ;;
    esac
    ret=$?
    _jenv_set_java_home
    return $ret
  }

  # Completion ships next to the binary: brew → <Cellar>/libexec/completions,
  # git install → ~/.jenv/completions.
  for _f in "${commands[jenv]:A:h:h}/libexec/completions/jenv.zsh" \
            "${commands[jenv]:A:h:h}/completions/jenv.zsh"; do
    [[ -r "$_f" ]] && { source "$_f"; break; }
  done
  unset _f

  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _jenv_set_java_home
  _jenv_set_java_home
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
