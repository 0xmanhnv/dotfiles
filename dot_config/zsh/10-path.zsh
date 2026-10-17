# Common PATH entries (cross-OS). Each guarded so missing dirs are skipped.
# ~/bin and ~/.local/bin are set in ~/.zshrc before this file loads.

[[ -d "$HOME/go/bin" ]] && export PATH="$PATH:$HOME/go/bin"
