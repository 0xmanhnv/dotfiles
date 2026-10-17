# Common PATH entries (cross-OS). Each guarded so missing dirs are skipped.
# ~/bin and ~/.local/bin are prepended by ~/.zshrc after these modules load.

[[ -d "$HOME/go/bin" ]] && export PATH="$PATH:$HOME/go/bin"
