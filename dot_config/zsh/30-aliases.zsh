# Aliases & shell ergonomics. Anything pointing to a specific file is guarded
# with [[ -d ]] / [[ -x ]] so the alias is only defined when the target exists.
# Aliases relying on a $PATH command resolve at use-time — a missing tool just
# produces "command not found" when actually invoked, no startup error.

# --- ls / file listing -------------------------------------------------------
# Prefer `eza` (modern Rust ls with icons + color + git status). Fall back to
# system ls with color flag if eza isn't installed.
if command -v eza >/dev/null 2>&1; then
  # No --icons: filename + eza's color-coding already convey file type;
  # icons add noise without new info. Same minimalist logic as the dropped
  # starship [directory.substitutions]. Use `eza --icons file…` ad hoc when
  # you actually want them.
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2'
  alias tree='eza --tree'
else
  if [[ "$(uname -s)" == "Darwin" ]]; then
    alias ls='ls -G'        # BSD ls (macOS): -G enables color
  else
    alias ls='ls --color=auto'  # GNU ls (Linux)
  fi
  alias ll='ls -lah'
  alias la='ls -A'
fi

# --- bat (cat with syntax highlighting) --------------------------------------
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never --style=plain'
fi

# --- Directory shortcuts (replaces OMZ lib/directories.zsh) ------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# `take <dir>` = mkdir -p && cd
take() { mkdir -p -- "$1" && cd -P -- "$1" || return; }

# --- Terminal title auto-update (replaces OMZ lib/termsupport.zsh) -----------
# Sets the terminal tab title to current path (idle) / running command (active).
# Uses add-zsh-hook so other plugins/configs can also register precmd/preexec.
autoload -Uz add-zsh-hook
_set_term_title_precmd()  { print -Pn '\e]0;%~\a'; }
_set_term_title_preexec() { print -Pn "\e]0;$1\a"; }
add-zsh-hook precmd  _set_term_title_precmd
add-zsh-hook preexec _set_term_title_preexec

# --- Git (subset of OMZ git-plugin aliases — most frequently used) -----------
alias g='git'
alias gst='git status'
alias gss='git status -sb'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gb='git branch'
alias ga='git add'
alias gaa='git add -A'
alias gsta='git stash push'
alias gstp='git stash pop'

# --- Claude Code multi-account switcher --------------------------------------
if [[ -d "$HOME/Data/Tools/claude-code-multi-account-switch" ]]; then
  alias claude-switch="$HOME/Data/Tools/claude-code-multi-account-switch/claude-switch.sh"
  alias claude-sync="$HOME/Data/Tools/claude-code-multi-account-switch/claude-sync.sh"
  alias claude-next="$HOME/Data/Tools/claude-code-multi-account-switch/claude-next.sh"
  alias claude-usage="python3 $HOME/Data/Tools/claude-code-multi-account-switch/claude-usage.py"
fi
