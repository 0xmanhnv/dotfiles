# Tool initializations. Every `source` / `eval` is guarded so a fresh machine
# without these tools won't crash zsh startup.

# Rust / Cargo
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# GVM (Go Version Manager)
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# jenv (Java) — eager init so JAVA_HOME auto-switches on `cd` in every shell.
# Costs ~50ms at startup; chosen over lazy-load because Java is a daily tool
# and per-project JAVA_HOME hooks need to be active immediately.
if [[ -d "$HOME/.jenv" ]]; then
  export PATH="$HOME/.jenv/bin:$PATH"
  command -v jenv >/dev/null 2>&1 && eval "$(jenv init -)"
fi

# RedOS wrappers
[[ -s "$HOME/.redosrc" ]] && source "$HOME/.redosrc"

# zoxide — smarter `cd` (z <fragment> jumps to most-frecent matching dir)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# fzf shell integration (Ctrl-R history, Ctrl-T files, Alt-C cd).
# `fzf --zsh` requires fzf 0.48+; falls back gracefully on older versions.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi
