# Aliases. Each one that points to a specific file is guarded with [[ -x ]] /
# [[ -d ]] so the alias is only defined when the target exists. Aliases that
# rely on a $PATH command (not absolute paths) are unconditional — zsh resolves
# them at use-time, so a missing tool just produces a "command not found" when
# you actually run it (no startup error).

# Git — minimal subset of the most-used OMZ git-plugin aliases (we don't load
# OMZ, so we replicate by hand).
alias g='git'
alias gst='git status'
alias gss='git status -sb'
alias gco='git checkout'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gb='git branch'
alias ga='git add'
alias gaa='git add -A'

# Claude Code multi-account switcher
if [[ -d "$HOME/Data/Tools/claude-code-multi-account-switch" ]]; then
  alias claude-switch="$HOME/Data/Tools/claude-code-multi-account-switch/claude-switch.sh"
  alias claude-sync="$HOME/Data/Tools/claude-code-multi-account-switch/claude-sync.sh"
  alias claude-next="$HOME/Data/Tools/claude-code-multi-account-switch/claude-next.sh"
  alias claude-usage="python3 $HOME/Data/Tools/claude-code-multi-account-switch/claude-usage.py"
fi
